module Ev3j
  class Step
    class Motor < Step
      def initialize(stype, port_sym, short_opts)
        @stype = stype
        @opts = common_motor_opts(port_sym, short_opts)
      end

      private

      def common_motor_opts(ports, opts)
        step_opts = {
          "id" => opts[:id],
        }

        on_opts = {}
        on_opts["power"] = opts[:power] unless opts[:power].nil?
        on_opts["steering"] = opts[:steering] unless opts[:steering].nil?
        step_opts["on"] = on_opts unless on_opts.empty?

        off_opts = {}
        off_opts["brake"] = opts[:brake] unless opts[:brake].nil?
        step_opts["off"] = off_opts unless off_opts.empty?

        step_opts
          .merge(port_opts(ports))
          .merge(dur_opts(opts))
      end

      def port_opts(ports)
        case ports
        when :portA
          {"port" => "A" }
        when :portB
          {"port" => "B" }
        when :portC
          {"port" => "C" }
        when :portD
          {"port" => "D" }
        when :portsBC
          {"port1" => "B", "port2" => "C"}
        end
      end

      def dur_opts(opts)
        if opts[:degrees]
          {"dur" => { "dtype" => "degrees", "degrees" => opts[:degrees] } }
        elsif opts[:rotations]
          {"dur" => { "dtype" => "rotations", "rotations" => opts[:rotations] } }
        elsif opts[:seconds]
          {"dur" => { "dtype" => "time", "seconds" => opts[:seconds] } }
        else
          {}
        end
      end
    end
  end
end
