module Ev3j
  class Until < Condition
    def self.from_json_object(o)
      case o["ctype"]
      when "Count"
        UntilCount.new(o["count"])
      when "Never"
        UntilForever.new
      else
        Condition.from_json_object(o)
      end
    end
  end

  class UntilCount < Until
    def initialize(count)
      @count = count
    end

    def json_hash
      { "ctype" => "Count", "count" => @count }
    end

    def dump_rb(f)
      f.print "count(#{@count})"
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
