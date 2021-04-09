# frozen_string_literal: true

#begin
#  require "async"
#
#  # :nodoc:
#  module Async
#    # :nodoc:
#    class Scheduler
#      # :nodoc:
#      def fiber(&block)
#        task = Task.new(@reactor, &block)
#        task.run
#        task.fiber
#      end
#    end
#  end
#rescue LoadError
#  begin
#    require "evt"
#  rescue LoadError
#    abort "fatal: the async or evt gem is required"
#  end
#end

module Earl
  def self.application
    @@application ||= Application.new.tap do |app|
      app.monitor(logger)
    end
  end

  def self.logger
    @@logger ||= Logger::Actor.new(Logger::INFO, Logger::ConsoleBackend.new)
  end
end

require "earl/scheduler"
require "earl/agent"
require "earl/channel"
require "earl/mailbox"
require "earl/logger"
require "earl/artist"
require "earl/supervisor"
require "earl/application"
require "earl/pool"
require "earl/registry"
