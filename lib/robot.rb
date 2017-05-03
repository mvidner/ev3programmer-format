require "json"

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
      File.write(filename, JSON.pretty_generate(@p.json_hash))
    end
  end

  class RobotProgram
    def initialize
      @comments = []
      @sequences = []
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

  class LoopBody
    def initialize
      @sequences = []
      @exit_from = nil
    end

    def json_hash
      {
        "entry"     => @entry.json_hash,
        "exit_from" => @exit_from,
        "sequences" => @sequences.map(&:json_hash)
      }
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

  class RobotSequence
    def initialize(opts)
      @opts = opts
      @steps = []
    end

    def json_hash
      @opts.merge("steps" => @steps)
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
      
      step("Loop", opts.merge(until_opts).merge("body" => body.json_hash))
    end
    
    private

    def step(stype, opts)
      @steps << opts.merge("stype" => stype)
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
      elsif opts[:duration]
        {"dur" => { "dtype" => "time", "seconds" => opts[:duration] } }
      else
        {}
      end
    end
  end
end
