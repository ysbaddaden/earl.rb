# frozen_string_literal: true

module Earl
  module Logger
    # :nodoc:
    class Actor
      include Agent
      include Mailbox

      attr_reader :backends # TODO: use a concurrency-safe array (e.g. copy-on-write array)
      attr_accessor :level
      attr_accessor :sync

      def initialize(level, backend)
        @backends = [backend]
        @level = level
        @mailbox_close_on_stop = false
        @sync = false
      end

      def call
        while mail = receive?
          write(*mail)
        end
        nil
      end

      def terminate
        until mailbox.__send__(:empty?)
          Earl.sleep(0.001)
        end
        nil
      end

      def send(mail)
        if @sync
          write(*mail)
        else
          super
        end
      end

      def silent?
        @level <= SILENT
      end

      def error?
        @level <= ERROR
      end

      def error(agent, message = nil)
        send [ERROR, agent, Time.now, message || yield] if error?
      end

      def warn?
        @level <= WARN
      end

      def warn(agent, message = nil)
        send [WARN, agent, Time.now, message || yield] if warn?
      end

      def notice?
        @level <= NOTICE
      end

      def notice(agent, message = nil)
        send [NOTICE, agent, Time.now, message || yield] if notice?
      end

      def info?
        @level <= INFO
      end

      def info(agent, message = nil)
        send [INFO, agent, Time.now, message || yield] if info?
      end

      def debug?
        @level <= DEBUG
      end

      def debug(agent, message = nil)
        send [DEBUG, agent, Time.now, message || yield] if debug?
      end

      def exception(agent, exception)
        error(agent) do
          str = "#{exception.class.name}: #{exception.message} at #{exception.backtrace.first}\n"
          exception.backtrace.each_with_index { |line, index| str += "  #{line}\n" unless index == 0 }
          str
        end
      end

      private

      def write(severity, agent, time, message)
        backends.each { |b| b.write(severity, agent, time, message) }
      end
    end
  end
end
