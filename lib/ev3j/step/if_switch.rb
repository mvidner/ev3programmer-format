module Ev3j
  class Step
    class IfSwitch < Step
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
end
