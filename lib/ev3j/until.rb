module Ev3j
  class Until < Condition
    def initialize(opts)
      raise ScriptError, "not implemented: #{opts}" unless opts[:count]
      @count = opts[:count]
    end

    def self.from_json_object(o)
      case o["ctype"]
      when "Count"
        new(count: o["count"])
      when "Never"
        UntilForever.new
      else
        raise ScriptError, "not implemented: #{o}"
      end
    end

    def json_hash
      { "ctype" => "Count", "count" => @count }
    end

    def dump_rb(f)
      f.print "until(count: #{@count})"
    end
  end

  class UntilForever < Until
    def initialize; end

    def json_hash
      { "ctype" => "Never" }
    end

    def dump_rb(f)
      f.print "forever"
    end
  end
end
