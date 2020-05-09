# frozen_string_literal: true
require "async"

module Earl
  def self.run
    Async do
      yield application if block_given?
      application.start
    end
  end

  def self.application
    @@application ||= Application.new.tap do |app|
      app.monitor(logger)
    end
  end

  def self.logger
    @@logger ||= Logger::Actor.new(Logger::INFO, Logger::ConsoleBackend.new)
  end

  def self.sleep(duration)
    if task = Async::Task.current?
      task.sleep(duration)
    else
      Kernel.sleep(duration)
    end
  end
end

require "earl/agent"
require "earl/channel"
require "earl/mailbox"
require "earl/logger"
require "earl/artist"
require "earl/supervisor"
require "earl/application"
require "earl/pool"
require "earl/registry"
