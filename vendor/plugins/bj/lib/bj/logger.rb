class Bj
  class Logger < ::Logger
    def self.new *a, &b
      super(*a, &b).instance_eval{ @default_formatter = @formatter = Formatter.new; self }
    end
    def format_message(severity, datetime, progname, msg)
      (@formatter || @default_formatter).call(severity, datetime, progname, msg)
    end

    def device
      @logdev.instance_eval{ @dev }
    end

    def tty?
      device.respond_to?('tty?') and device.tty?
    end

    def turn which
      @logdev.extend OnOff unless OnOff === @logdev
      @logdev.turn which
    end

    module OnOff
      def turn which
        @turned = which.to_s =~ %r/on/i ? :on : :off
      end

      def write message 
        return message.to_s.size if @turned == :off
        super
      end
    end

    def on
      turn :on
    end
    alias_method "on!", "on"
    def self.on *a, &b
      new(*a, &b).instance_eval{ turn :on; self }
    end

    def off
      turn :off
    end
    alias_method "off!", "off"
    def self.off *a, &b
      new(*a, &b).instance_eval{ turn :off; self }
    end
  end
end
