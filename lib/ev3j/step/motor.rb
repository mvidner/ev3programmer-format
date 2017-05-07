module Ev3j
  class Step
    class Motor < Step
      def initialize(stype, port_sym, short_opts)
        @stype = stype
        @opts = Program.expand(short_opts).merge(port_opts(port_sym))
      end

      private

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
    end
  end
end
