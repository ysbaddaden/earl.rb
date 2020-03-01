# frozen_string_literal: true
require "earl/channel"

module Earl
  class Pool
    include Artist

    def initialize(agent_class, capacity)
      @agent_class = agent_class
      @capacity = capacity
      @workers = Array.new(capacity)
      @done = Channel.new
    end

    def call
      @capacity.times do
        Async do
          agent = @agent_class.new
          @workers << agent

          while agent.starting?
            log.info { "starting worker" }
            agent.mailbox = mailbox
            agent.start(link: self)
          end
        end
      end

      @done.receive?

      until @workers.all?(&:nil?)
        Earl.sleep(1)
      end
    end

    def trap(agent, exception = nil)
      if exception
        Earl.logger.exception(agent, exception)
        log.error { "worker crashed (#{exception.class.name})" }
      elsif agent.running?
        log.warn { "worker stopped unexpectedly" }
      end

      if running?
        return agent.recycle
      end

      @workers.delete(agent)
      nil
    end

    def terminate
      @workers.each do |agent|
        agent.stop rescue nil
      end

      @done.close

      nil
    end
  end
end
