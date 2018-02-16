module Ev3j
  class Comment
    attr_reader :opts

    # @param text [String]
    # @param opts [Hash] layout options: color, w, h, x0, y0
    def initialize(text, opts)
      @text = text
      @opts = opts
    end

    # @!group From Json
    # @param o [Hash] a certain deserialized JSON; schema: Comment
    def self.from_json_object(o)
      text = o.delete("text")
      new(text, o)
    end

    # @!group To Json
    # @return [Hash] a certain deserialized JSON; schema: Comment
    def json_hash
      {text: @text}.merge(@opts)
    end

    def opt_order
      %w(color w h x0 y0)
    end

    def opts_s
      opt_order.map { |k| "#{k}: #{opts[k].inspect}" }.join(", ")
    end
    
    # @!group To Ruby
    # @param f [IO] a writable IO
    def dump_rb(f)
      f.puts "comment \"#{@text}\", #{opts_s}"
    end
  end
end
