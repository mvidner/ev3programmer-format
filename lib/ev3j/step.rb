module Ev3j
  class Step
    def initialize(opts, stype:)
      @opts = opts
      @stype = stype
    end

    def dump_rb(f)
      method = @stype.downcase.gsub("-", "_")
      f.puts("#{method} #{opts_to_s @opts}")
    end

    def json_hash
      @opts.merge("stype" => @stype)
    end

    def self.from_json_object(o)
      stype = o.delete "stype"
      case stype
      when "Loop"
        Step::Loop.from_json_object(o)
      when "Case-Switch"
        Step::CaseSwitch.from_json_object(o)
      when "If-Switch"
        Step::IfSwitch.from_json_object(o)
      else
        new(o, stype: stype)
      end
    end
  end
end
