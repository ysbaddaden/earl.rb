# frozen_string_literal: true

require "earl/logger/backend"

module Earl
  module Logger
    class ConsoleBackend < Backend
      def initialize(io = $stdout)
        @io = io
      end

      def write(severity, agent, time, message)
        char = Logger.severity_char(severity)
        @io << "#{char} [#{time} #{Process.pid}] #{agent.class.name} #{message}\n"
        nil
      end
    end
  end
end
