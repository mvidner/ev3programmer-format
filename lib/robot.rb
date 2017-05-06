require "json"

def opts_to_s(opts)
  opts.map {|k, v| "#{k}: #{v.inspect}"}.join(", ")
end

module Ev3j
  class Robot
    def program(&block)
      @p = RobotProgram.new
      @p.instance_eval(&block)
    end

    def script_file(filename)
      @p = RobotProgram.new
      @p.instance_eval(File.read(filename))
    end

    def save_json(filename)
      @p.save_json(filename)
    end
  end

  class RobotProgram
    def initialize(comments: [], sequences: [])
      @comments = comments
      @sequences = sequences
    end

    def save_json(filename)
      File.write(filename, JSON.pretty_generate(json_hash))
    end

    def save_rb(filename)
      File.open(filename, "w") do |f|
        dump_rb(f)
      end
    end

    def dump_rb(f)
      @comments.each do |c|
        opts = c.dup
        text = opts.delete "text"
        f.puts "comment \"#{text}\", #{opts_to_s opts}"
      end
      @sequences.each do |seq|
        seq.dump_rb(f)
      end
    end

    def self.from_json_file(filename)
      from_json_object(JSON.parse(File.read(filename)))
    end

    def self.from_json_object(o)
      seqs = o["sequences"].map { |jseq| RobotSequence.from_json_object(jseq) }
      new(comments: o["comments"], sequences: seqs)
    end

    def comment(text, opts = {})
      @comments << opts.merge("text" => text)
    end

    def sequence(opts, &block)
      seq = RobotSequence.new(opts)
      seq.instance_eval(&block)
      @sequences << seq
    end

    # FIXME figure out the Ruby JSON protocol for this
    def json_hash
      {
        "comments" => @comments,
        "sequences" => @sequences.map(&:json_hash)
      }
    end
  end

  class RobotStep
    def initialize(opts)
      @opts = opts
    end

    def dump_rb(f)
      opts = @opts.dup
      method = opts.delete("stype").downcase.gsub("-", "_")
      f.puts("#{method} #{opts_to_s opts}")
    end

    def json_hash
      @opts
    end

    def self.from_json_object(o)
      if o["stype"] == "Loop"
        LoopStep.from_json_object(o)
      elsif o["stype"] == "Case-Switch"
        CaseSwitchStep.from_json_object(o)
      else
        new(o)
      end
    end
  end

  class LoopStep < RobotStep
    def initialize(opts, body)
      @body = body
      super(opts)
    end

    def dump_rb(f)
      f.puts("loop_count #{opts_to_s @opts} do")
      @body.dump_rb(f)
      f.puts "end"
    end

    def self.from_json_object(o)
      bopts = o.delete("body")
      body = LoopBody.from_json_object(bopts)
      new(o, body)
    end

    def json_hash
      @opts.merge("body" => @body.json_hash)
    end
  end

  class LoopBody
    def initialize(sequences = [], entry = {}, exit_from = nil)
      @sequences = sequences
      @entry     = RobotSequence.from_json_object(entry)
      @exit_from = exit_from
    end

    def self.from_json_object(o)
      new(o["sequences"], o["entry"], o["exit_from"])
    end

    def json_hash
      {
        "entry"     => @entry.json_hash,
        "exit_from" => @exit_from,
        "sequences" => @sequences.map(&:json_hash)
      }
    end

    def dump_rb(f, keyword = "entry")
      @entry.dump_rb(f, keyword)
      f.puts "exit_from #{@exit_from.inspect}"
    end

    def exit_from(val)
      @exit_from = val
    end

    def entry(opts, &block)
      seq = RobotSequence.new(opts)
      seq.instance_eval(&block)
      @entry = seq
    end
  end

  class CaseSwitchStep < RobotStep
    def self.from_json_object(o)
      cases = o.delete("cases").map do |c|
        cwhen = c["when"]
        cthen = LoopBody.from_json_object(c["then"])
        [cwhen, cthen]
      end
      new(o, Hash[cases])
    end

    def initialize(opts, cases)
      @opts = opts
      @cases = cases
    end

    def dump_rb(f)
      f.puts "case_switch(#{opts_to_s @opts}) do"
      @cases.each do |cwhen, cthen|
        cthen.dump_rb(f, "cwhen(#{cwhen}).opts")
      end
      f.puts "end"
    end
  end

  class RobotSequence
    def initialize(opts, steps: [])
      @opts = opts
      @steps = steps
    end

    def dump_rb(f, keyword = "sequence")
      f.puts "#{keyword}(#{opts_to_s(@opts)}) do"
      @steps.each { |st| st.dump_rb(f) }
      f.puts "end"
    end

    def self.from_json_object(o)
      steps = o.delete("steps")
      steps ||= []
      steps.map! { |st| RobotStep.from_json_object(st) }
      new(o, steps: steps)
    end

    def json_hash
      @opts.merge("steps" => @steps.map(&:json_hash))
    end

    def start(opts = {})
      step("Start", opts)
    end

    def move_steering(ports, opts = {})
      step("Move-Steering", common_motor_opts(ports, opts))
    end

    def large_motor(port, opts = {})
      step("Large-Motor", common_motor_opts(port, opts))
    end

    def medium_motor(port, opts = {})
      step("Medium-Motor", common_motor_opts(port, opts))
    end

    def loop_count(count, opts = {}, &block)
      until_opts = { "until" => { "ctype" => "Count", "count" => count } }
      body = LoopBody.new
      body.instance_eval(&block)

      step("Loop", opts.merge(until_opts).merge("body" => body))
    end

    private

    def step(stype, opts)
      if stype == "Loop"
        body = opts.delete("body")
        step = LoopStep.new(opts.merge("stype" => stype), body)
      else
        step = RobotStep.new(opts.merge("stype" => stype))
      end

      @steps << step
    end

    def common_motor_opts(ports, opts)
      step_opts = {
        "id" => opts[:id],
      }

      on_opts = {}
      on_opts["power"] = opts[:power] unless opts[:power].nil?
      on_opts["steering"] = opts[:steering] unless opts[:steering].nil?
      step_opts["on"] = on_opts unless on_opts.empty?

      off_opts = {}
      off_opts["brake"] = opts[:brake] unless opts[:brake].nil?
      step_opts["off"] = off_opts unless off_opts.empty?

      step_opts
        .merge(port_opts(ports))
        .merge(dur_opts(opts))
    end

    def port_opts(ports)
      case ports
      when :portA
        {"port" => "A" }
      when :portB
        {"port" => "B" }
      when :portC
        {"port" => "C" }
      when :portD
        {"port" => "D" }
      when :portsBC
        {"port1" => "B", "port2" => "C"}
      end
    end

    def dur_opts(opts)
      if opts[:degrees]
        {"dur" => { "dtype" => "degrees", "degrees" => opts[:degrees] } }
      elsif opts[:rotations]
        {"dur" => { "dtype" => "rotations", "rotations" => opts[:rotations] } }
      elsif opts[:seconds]
        {"dur" => { "dtype" => "time", "seconds" => opts[:seconds] } }
      else
        {}
      end
    end
  end
end
