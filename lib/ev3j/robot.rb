require "json"

def opts_to_s(opts)
  opts.map {|k, v| "#{k}: #{v.inspect}"}.join(", ")
end

module Ev3j
  # A Robot has a Program which can be manipulated (only) through the methods.
  class Robot
    # Load the {Program} from a Ruby block
    # @return [Program]
    def program(&block)
      @p = Program.new
      @p.instance_eval(&block)
      @p
    end

    # Load the program from a Ruby file
    # @return [Program]
    def script_file(filename)
      @p = Program.new
      @p.instance_eval(File.read(filename))
      @p
    end

    # Save the {Program} as an EV3J file
    # @return [void]
    def save_json(filename)
      jh = @p.json_hash
      File.write(filename, JSON.pretty_generate(jh))
    end

    # Save the {Program} as a Ruby file
    # @return [void]
    def save_rb(filename)
      File.open(filename, "w") do |f|
        @p.dump_rb(f)
      end
    end

    # Load the {Program} from an EV3J file
    # @return [Program]
    def json_file(filename)
      text = File.read(filename)
      jh = JSON.parse(text)
      @p = Program.from_json_object(jh)
    end
  end
end
