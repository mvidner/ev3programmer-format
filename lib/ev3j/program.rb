module Ev3j
  class Program
    def initialize(comments: [], sequences: [])
      @comments = comments
      @sequences = sequences
    end

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
