require "ev3j/short_opt"

module Ev3j
  # A Program is one or more {Sequence}s of {Step}s, and optionally some
  # {Comment}s.
  class Program
    def initialize(comments: [], sequences: [])
      @comments = comments
      @sequences = sequences
    end

    @@abbrevs = FuzzyShortOptSet.new

    def self.abbrev(key, long)
      @@abbrevs.add(key, long)
    end

    def self.expand(opts)
      @@abbrevs.expand(opts)
    end

    def self.shorten(opts)
      @@abbrevs.shorten(opts)
    end

    X = ShortOpt::X
    abbrev(:power    , { on:  { power:    X } })
    abbrev(:steering , { on:  { steering: X } })

    abbrev(:brake    , { off: { brake:    X } })

    abbrev(:degrees  , { dur: { dtype: "degrees",   degrees:   X } })
    abbrev(:rotations, { dur: { dtype: "rotations", rotations: X } })
    abbrev(:seconds  , { dur: { dtype: "time",      seconds:   X } })

    # @!group To Ruby
    # @param f [IO] a writable IO
    def dump_rb(f)
      @comments.each { |c| c.dump_rb(f) }
      @sequences.each do |seq|
        seq.dump_rb(f, opts_in: :args)
      end
    end

    # @!group From Json
    # @param o [Hash] a certain deserialized JSON; schema: Ev3j
    def self.from_json_object(o)
      comments = o.fetch("comments", []).map { |jc| Comment.from_json_object(jc) }
      seqs = o["sequences"].map { |jseq| Sequence.from_json_object(jseq) }
      new(comments: comments, sequences: seqs)
    end

    # @!group From Ruby

    def comment(text, opts = {})
      @comments << Comment.new(text, opts)
    end

    def sequence(opts, &block)
      seq = Sequence.new(opts)
      seq.instance_eval(&block)
      @sequences << seq
    end

    # @!group To Json
    # @return [Hash] a certain deserialized JSON; schema: Ev3j
    def json_hash
      {
        "comments" => @comments.map(&:json_hash),
        "sequences" => @sequences.map(&:json_hash)
      }
    end
  end
end
