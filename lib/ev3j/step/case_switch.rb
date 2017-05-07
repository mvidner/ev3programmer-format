module Ev3j
  class CaseSwitch < Step
    def self.from_json_object(o)
      cases = o.delete("cases").map do |c|
        cwhen = c["when"]
        cthen = Body.from_json_object(c["then"])
        [cwhen, cthen]
      end
      new(o, Hash[cases])
    end

    def initialize(opts, cases)
      @opts = opts
      @cases = cases
    end

    def dump_rb(f)
      f.puts "case_switch(#{opts_to_s @opts}) do"
      @cases.each do |cwhen, cthen|
        cthen.dump_rb(f, "cwhen(#{cwhen}).opts")
      end
      f.puts "end"
    end
  end
end  
