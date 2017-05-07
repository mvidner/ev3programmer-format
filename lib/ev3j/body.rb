module Ev3j
  # A Body either has only one Sequence, in the @entry member,
  # or it has multiple sequences, in @sequences
  class Body
    # for @entry, without @sequences
    def self.with_entry
      seq = Sequence.new({})
      new(entry: seq, sequences: [], sequence: seq, exit_from: nil)
    end

    # @param sequence the one to apply block commands to
    def initialize(entry:, sequences:, sequence:, exit_from:)
      @entry     = entry
      @sequences = sequences
      @sequence  = sequence
      @exit_from = exit_from
    end

    def self.from_json_object(o)
      seqs = o["sequences"].map { |jseq| Sequence.from_json_object(jseq) }
      entry = Sequence.from_json_object(o["entry"])
      exit_from = o["exit_from"]
      new(entry: entry, sequences: seqs, sequence: entry, exit_from: exit_from)
    end

    def json_hash
      {
        "entry"     => @entry.json_hash,
        "exit_from" => @exit_from || @sequence.id,
        "sequences" => @sequences.map(&:json_hash)
      }
    end

    def dump_rb(f)
      if @sequences.empty?
        @entry.dump_rb(f, opts_in: :block)
      else
        raise "TODO"
      end
    end

    def sequence
      @sequence
    end
  end
end
