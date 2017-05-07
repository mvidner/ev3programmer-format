require "json"

def opts_to_s(opts)
  opts.map {|k, v| "#{k}: #{v.inspect}"}.join(", ")
end

module Ev3j
  class Robot
    def program(&block)
      @p = Program.new
      @p.instance_eval(&block)
    end

    def script_file(filename)
      @p = Program.new
      @p.instance_eval(File.read(filename))
    end

    def save_json(filename)
      jh = @p.json_hash
      File.write(filename, JSON.pretty_generate(jh))
    end

    def save_rb(filename)
      File.open(filename, "w") do |f|
        @p.dump_rb(f)
      end
    end

    def json_file(filename)
      text = File.read(filename)
      jh = JSON.parse(text)
      @p = Program.from_json_object(jh)
    end
  end
end
