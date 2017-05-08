module Ev3j
  class Condition
    def self.from_json_object(o)
      case o["ctype"]
      when "Absolute"
        AbsoluteCondition.from_json_object(o)
      when "Discrete"
        DiscreteCondition.from_json_object(o)
      else
        raise ScriptError, "not implemented: #{o}"
      end
    end

    def initialize(opts)
      @opts = opts
    end

    def dump_rb(f)
      f.puts "cond(#{opts_to_s @opts})"
    end
  end

  class AbsoluteCondition < Condition
    def self.from_json_object(o)
      source = Value.from_json_object o["source"]
      new(source: source, comparison: o["comparison"], threshold: o["threshold"])
    end

    def initialize(source:, comparison:, threshold:)
      @source = source
      @comparison = comparison
      @threshold = threshold
    end

    def dump_rb(f)
      @source.dump_rb(f)
      f.print(".is(#{@comparison.inspect}, #{@threshold.inspect})")
    end
  end

  class DiscreteCondition < Condition
    def self.from_json_object(o)
      source = Value.from_json_object o["source"]
      new(source: source, is_in: o["is_in"])
    end

    def initialize(source:, is_in:)
      @source = source
      @is_in = is_in
    end

    def dump_rb(f)
      @source.dump_rb(f)
      f.print(".is_in(#{@is_in.inspect})")
    end
  end
end
