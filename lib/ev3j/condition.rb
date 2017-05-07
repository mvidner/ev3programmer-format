module Ev3j
  class Condition
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
end
