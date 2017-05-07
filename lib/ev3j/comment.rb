module Ev3j
  class Comment
    attr_reader :opts
    def initialize(text, opts)
      @text = text
      @opts = opts
    end

    def self.from_json_object(o)
      text = o.delete("text")
      new(text, o)
    end

    def json_hash
      {text: @text}.merge(@opts)
    end

    def opt_order
      %w(color w h x0 y0)
    end

    def opts_s
      opt_order.map { |k| "#{k}: #{opts[k].inspect}" }.join(", ")
    end
    
    def dump_rb(f)
      f.puts "comment \"#{@text}\", #{opts_s}"
    end
  end
end

