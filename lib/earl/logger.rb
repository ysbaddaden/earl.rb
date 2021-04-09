# frozen_string_literal: true

require "earl/logger/severity"
require "earl/logger/actor"
require "earl/logger/console_backend"

module Earl
  module Logger
    class Log
      def initialize(agent)
        @agent = agent
      end

      def silent?
        Earl.logger.silent?
      end

      def error?
        Earl.logger.error?
      end

      def error(message = nil)
        if block_given?
          Earl.logger.error(@agent) { yield }
        else
          Earl.logger.error(@agent, message)
        end
      end

      def warn?
        Earl.logger.warn?
      end

      def warn(message = nil)
        if block_given?
          Earl.logger.warn(@agent) { yield }
        else
          Earl.logger.warn(@agent, message)
        end
      end

      def notice?
        Earl.logger.notice?
      end

      def notice(message = nil)
        if block_given?
          Earl.logger.notice(@agent) { yield }
        else
          Earl.logger.notice(@agent, message)
        end
      end

      def info?
        Earl.logger.info?
      end

      def info(message = nil)
        if block_given?
          Earl.logger.info(@agent) { yield }
        else
          Earl.logger.info(@agent, message)
        end
      end

      def debug?
        Earl.logger.debug?
      end

      def debug(message = nil)
        if block_given?
          Earl.logger.debug(@agent) { yield }
        else
          Earl.logger.debug(@ægent, message)
        end
      end

      def exception(exception)
        Earl.logger.exception(@agent, exception)
      end
    end

    def log
      @log ||= Log.new(self)
    end
  end
end
