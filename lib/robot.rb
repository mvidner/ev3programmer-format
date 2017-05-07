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
      jh = @p.json_hash
      File.write(filename, JSON.pretty_generate(jh))
    end

    def save_rb(filename)
      File.open(filename, "w") do |f|
        @p.dump_rb(f)
      end
    end

    def json_file(filename)
      text = File.read(filename)
      jh = JSON.parse(text)
      @p = RobotProgram.from_json_object(jh)
    end
  end

  class RobotProgram
    def initialize(comments: [], sequences: [])
      @comments = comments
      @sequences = sequences
    end

    #@!group To Ruby
    def dump_rb(f)
      @comments.each do |c|
        opts = c.dup
        text = opts.delete "text"
        f.puts "comment \"#{text}\", #{opts_to_s opts}"
      end
      @sequences.each do |seq|
        seq.dump_rb(f, opts_in: :args)
      end
    end

    #@!group From Json
    def self.from_json_object(o)
      comments = o.fetch("comments", [])
      seqs = o["sequences"].map { |jseq| RobotSequence.from_json_object(jseq) }
      new(comments: comments, sequences: seqs)
    end

    # @!group From Ruby

    def comment(text, opts = {})
      @comments << opts.merge("text" => text)
    end

    def sequence(opts, &block)
      seq = RobotSequence.new(opts)
      seq.instance_eval(&block)
      @sequences << seq
    end

    # @!group To Json
    # FIXME figure out the Ruby JSON protocol for this
    def json_hash
      {
        "comments" => @comments,
        "sequences" => @sequences.map(&:json_hash)
      }
    end
  end

  class RobotStep
    def initialize(opts, stype:)
      @opts = opts
      @stype = stype
    end

    def dump_rb(f)
      method = @stype.downcase.gsub("-", "_")
      f.puts("#{method} #{opts_to_s @opts}")
    end

    def json_hash
      @opts.merge("stype" => @stype)
    end

    def self.from_json_object(o)
      stype = o.delete "stype"
      case stype
      when "Loop"
        LoopStep.from_json_object(o)
      when "Case-Switch"
        CaseSwitchStep.from_json_object(o)
      when "If-Switch"
        IfSwitchStep.from_json_object(o)
      else
        new(o, stype: stype)
      end
    end
  end

  class LoopStep < RobotStep
    def initialize(opts)
      @body = nil
      @opts = opts
    end

    def until=(until_)
      @until = until_
    end

    def body=(body)
      @body = body
    end

    def dump_rb(f)
      f.print("loop(#{opts_to_s @opts}).")
      @until.dump_rb(f)
      @body.dump_rb(f)
    end

    def self.from_json_object(o)
      bopts = o.delete("body")
      uopts = o.delete("until")
      s = new(o)
      s.body = Body.from_json_object(bopts)
      s.until = Until.from_json_object(uopts)
      s
    end

    def json_hash
      {
        "stype" => "Loop",
        "body"  => @body.json_hash,
        "until" => @until.json_hash
      }.merge(@opts)
    end
  end

  # A Body either has only one RobotSequence, in the @entry member,
  # or it has multiple sequences, in @sequences
  class Body
    # for @entry, without @sequences
    def self.with_entry
      seq = RobotSequence.new({})
      new(entry: seq, sequences: [], sequence: seq, exit_from: nil)
    end

    # @param sequence the one to apply block commands to
    def initialize(entry:, sequences:, sequence:, exit_from:)
      @entry     = entry
      @sequences = sequences
      @sequence  = sequence
      @exit_from = exit_from
    end

    def self.from_json_object(o)
      seqs = o["sequences"].map { |jseq| RobotSequence.from_json_object(jseq) }
      entry = RobotSequence.from_json_object(o["entry"])
      exit_from = o["exit_from"]
      new(entry: entry, sequences: seqs, sequence: entry, exit_from: exit_from)
    end

    def json_hash
      {
        "entry"     => @entry.json_hash,
        "exit_from" => @exit_from || @sequence.id,
        "sequences" => @sequences.map(&:json_hash)
      }
    end

    def dump_rb(f)
      if @sequences.empty?
        @entry.dump_rb(f, opts_in: :block)
      else
        raise "TODO"
      end
    end

    def sequence
      @sequence
    end
  end

  class CaseSwitchStep < RobotStep
    def self.from_json_object(o)
      cases = o.delete("cases").map do |c|
        cwhen = c["when"]
        cthen = Body.from_json_object(c["then"])
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

    def dump_rb(f, opts_in:)
      case opts_in
      when :args
        f.puts("sequence(#{opts_to_s @opts}) do")
      when :block
        f.puts " do"
        f.puts "id #{id.inspect}"
      end
      @steps.each { |st| st.dump_rb(f) }
      f.puts "end"
    end

    def self.from_json_object(o)
      steps = o.delete("steps")
      steps.map! { |st| RobotStep.from_json_object(st) }
      new(o, steps: steps)
    end

    def json_hash
      @opts.merge("steps" => @steps.map(&:json_hash))
    end

    def add_step(step)
      @steps << step
    end

    # both a getter and a setter in one method
    def id(i = nil)
      if i
        @opts["id"] = i
      else
        @opts["id"]
      end
    end

    def start(opts = {})
      @steps << RobotStep.new(opts, stype: "Start")
    end

    def move_steering(ports, opts = {})
      @steps << MotorStep.new("Move-Steering", ports, opts)
    end

    def large_motor(port, opts = {})
      @steps << MotorStep.new("Large-Motor", port, opts)
    end

    def medium_motor(port, opts = {})
      @steps << MotorStep.new("Medium-Motor", port, opts)
    end

    class LoopStatement
      def initialize(sequence, loop_step)
        @sequence = sequence
        @step = loop_step
      end

      def until(opts, &block)
        @step.until = Until.new(opts)
        body = Body.with_entry
        @step.body = body
        body.sequence.instance_eval(&block)
        @sequence.add_step(@step)
      end
    end

    def loop(opts = {})
      step = LoopStep.new(opts)
      # a chained .until call will add the LoopStep to our @steps
      LoopStatement.new(self, step)
    end
  end

  class Cond
    def self.from_json_object(o)
      new(o)
    end

    def initialize(opts)
      @opts = opts
    end

    def dump_rb(f)
      f.puts "cond(#{opts_to_s @opts})"
    end
  end

  class Until < Cond
    def initialize(opts)
      raise ScriptError, "not implemented: #{opts}" unless opts[:count]
      @count = opts[:count]
    end

    def self.from_json_object(o)
      raise ScriptError, "not implemented: #{o}" unless o["count"]
      new(count: o["count"])
    end

    def json_hash
      { "ctype" => "Count", "count" => @count }
    end

    def dump_rb(f)
      f.print "until(count: #{@count})"
    end
  end

  class MotorStep < RobotStep
    def initialize(stype, port_sym, short_opts)
      @stype = stype
      @opts = common_motor_opts(port_sym, short_opts)
    end

    private

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

  class IfSwitchStep < RobotStep
    def self.from_json_object(o)
      cond = Cond.from_json_object(o.delete("cond"))
      cthen = Body.from_json_object(o.delete "then")
      celse = Body.from_json_object(o.delete "else")
      new(o, cond, cthen, celse)
    end

    def initialize(opts, cond, cthen, celse)
      @opts = opts
      @cond = cond
      @then = cthen
      @else = celse
    end

    def dump_rb(f)
      f.puts "if_switch(#{opts_to_s @opts}).cond do"
      @cond.dump_rb(f)
      f.puts "end.then do"
      @then.dump_rb(f)
      f.puts "end.else do"
      @else.dump_rb(f)
      f.puts "end"
    end
  end
end
