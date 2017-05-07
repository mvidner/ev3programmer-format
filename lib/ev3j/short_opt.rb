module Ev3j
  class ShortOpt
    # placeholder constant
    class X; end

    # @param key
    # @param long  [Hash]
    def initialize(key, long)
      @key = key
      @long = long
    end

    def expand(data)
      if data.key?(@key)
        new_data = data.dup
        value = new_data.delete(@key)
        new_data.merge(sub_x(@long, value))
      else
        data
      end
    end

    def shorten(data)
      match, mx = hash_match(@long, data)
      return data unless match
      new_data = data.dup
      @long.each_key { |k| new_data.delete(k) }
      new_data[@key] = mx
      new_data
    end

    private

    # @return pair (Bool matched, nil or value of X)
    def hash_match(needle_h, haystack_h)
      x = nil
      needle_h.each_pair do |k, v|
        return [false, nil] unless haystack_h.key?(k)
        matched, mx = value_match(v, haystack_h[k])
        return [false, nil] unless matched
        x = mx unless mx.nil?
      end
      [true, x]
    end

    # @return pair (Bool matched, nil or value of X)
    def value_match(needle_v, haystack_v)
      if needle_v == haystack_v
        [true, nil]
      elsif needle_v == X
        [true, haystack_v]
      elsif needle_v.is_a?(Hash) && haystack_v.is_a?(Hash)
        hash_match(needle_v, haystack_v)
      else
        [false, nil]
      end
    end

    # A helper for {#expand}
    def sub_x(data, value)
      pairs = data.map do |k, v|
        v = value if v == X
        v = sub_x(v, value) if v.is_a? Hash
        [k, v]
      end
      Hash[pairs]
    end
  end

  class ShortOptSet
    def initialize
      @all = []
    end

    def add(* args)
      @all << ShortOpt.new(* args)
    end

    def expand(data)
      @all.each do |a|
        data = a.expand(data)
      end
      data
    end

    def shorten(data)
      @all.each do |a|
        data = a.shorten(data)
      end
      data
    end
  end

  class FuzzyShortOptSet < ShortOptSet
    def add(key, long)
      @all << ShortOpt.new(key, long)
      @all << ShortOpt.new(key.to_s, stringkeys(long))
    end

    private

    def stringkeys(hash)
      pairs = hash.map do |k, v|
        k = k.to_s
        v = stringkeys(v) if v.is_a?(Hash)
        [k, v]
      end
      Hash[pairs]
    end
  end
end
