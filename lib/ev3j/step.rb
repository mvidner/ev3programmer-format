#require "ev3j/step/case_switch"
#require "ev3j/step/if_switch"
#require "ev3j/step/loop"

module Ev3j
  class Step
    def initialize(opts, stype:)
      @opts = opts
      @stype = stype
    end

    def dump_rb(f)
      method = @stype.downcase.gsub("-", "_")
      short_opts = Program.shorten(@opts)
      sym_arg, short_opts = symize(short_opts)
      sym_arg_s = sym_arg ? "#{sym_arg.inspect}, " : ""
      f.puts "#{method} #{sym_arg_s}#{opts_to_s short_opts}"
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

    private

    # @param [Hash] opts
    # @return [pair Symbol|nil, Hash]
    def symize(opts)
      new_opts = opts.dup
      port = new_opts.delete("port")
      if port
        sym = "port#{port}".to_sym
        [sym, new_opts]
      else
        [nil, opts]
      end
    end
  end
end
