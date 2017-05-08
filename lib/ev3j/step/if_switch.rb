module Ev3j
  class Step
    class IfSwitch < Step
      def self.from_json_object(o)
        cond = Condition.from_json_object(o.delete("cond"))
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
        f.print "if_switch(#{opts_to_s @opts})"
        f.print "."
        @cond.dump_rb(f)
        f.print ".then"
        @then.dump_rb(f, chain_else: true)
        f.print ".else"
        @else.dump_rb(f)
      end
    end
  end
end
