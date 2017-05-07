module Ev3j
  class Until < Condition
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
end
