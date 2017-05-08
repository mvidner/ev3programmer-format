module Ev3j
  class Sequence
    def initialize(opts, steps: [])
      @opts = opts
      @steps = steps
    end

    def dump_rb(f, opts_in:, chain_else: false)
      case opts_in
      when :args
        f.puts("sequence(#{opts_to_s @opts}) do")
      when :block
        f.puts " do"
        f.puts "id #{id.inspect}"
      end
      @steps.each { |st| st.dump_rb(f) }
      f.print "end"
      f.puts unless chain_else
    end

    def self.from_json_object(o)
      steps = o.delete("steps")
      steps.map! { |st| Step.from_json_object(st) }
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
      @steps << Step.new(opts, stype: "Start")
    end

    def move_steering(ports, opts = {})
      @steps << Step::Motor.new("Move-Steering", ports, opts)
    end

    def large_motor(port, opts = {})
      @steps << Step::Motor.new("Large-Motor", port, opts)
    end

    def medium_motor(port, opts = {})
      @steps << Step::Motor.new("Medium-Motor", port, opts)
    end

    class LoopStatement
      def initialize(sequence, loop_step)
        @sequence = sequence
        @step = loop_step
      end

      def count(n, &block)
        until_block(UntilCount.new(n), &block)
      end

      def forever(&block)
        until_block(UntilForever.new, &block)
      end

      private

      def until_block(until_, &block)
        @step.until = until_
        body = Body.with_entry
        @step.body = body
        body.sequence.instance_eval(&block)
        @sequence.add_step(@step)
      end
    end

    def loop(opts = {})
      step = Step::Loop.new(opts)
      # a chained .until call will add the Step::Loop to our @steps
      LoopStatement.new(self, step)
    end
  end
end
