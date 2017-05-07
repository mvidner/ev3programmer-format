module Ev3j
  class Step
    class Loop < Step
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
  end
end
