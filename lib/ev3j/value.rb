module Ev3j
  # Supplies input for a {Condition}
  class Value
    def self.from_json_object(o)
      o = o.dup
      mtype = o.delete "mtype"
      case mtype
      when "Brick-Buttons-Check"
        BrickButtonsCheck.new(check: o["check"], buttons: o["buttons"])
      else
        new(o, mtype: mtype)
      end
    end

    def initialize(opts, mtype:)
      @opts = opts
      @mtype = mtype
    end

    def dump_rb(f)
      method = @mtype.downcase.gsub("-", "_")
      f.print "#{method}(#{opts_to_s @opts})"
    end

    def json_hash
      @opts.merge("mtype" => @mtype)
    end
  end

  class BrickButtonsCheck < Value
    # @param check [String] "pressed" or (?)
    # @param buttons [Array<Integer>]
    def initialize(check:, buttons:)
      @check = check
      @buttons = buttons
    end

    def dump_rb(f)
      f.print("brick_buttons_check(#{@check.inspect}, #{@buttons.inspect})")
    end
  end
end
