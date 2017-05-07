require "ev3j/short_opt"

module Ev3j
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

    #@!group To Ruby
    def dump_rb(f)
      @comments.each do |c|
        opts = c.dup
        text = opts.delete "text"
        f.puts "comment \"#{text}\", #{opts_to_s opts}"
      end
      @sequences.each do |seq|
        seq.dump_rb(f, opts_in: :args)
      end
    end

    #@!group From Json
    def self.from_json_object(o)
      comments = o.fetch("comments", [])
      seqs = o["sequences"].map { |jseq| Sequence.from_json_object(jseq) }
      new(comments: comments, sequences: seqs)
    end

    # @!group From Ruby

    def comment(text, opts = {})
      @comments << opts.merge("text" => text)
    end

    def sequence(opts, &block)
      seq = Sequence.new(opts)
      seq.instance_eval(&block)
      @sequences << seq
    end

    # @!group To Json
    # FIXME figure out the Ruby JSON protocol for this
    def json_hash
      {
        "comments" => @comments,
        "sequences" => @sequences.map(&:json_hash)
      }
    end
  end
end
