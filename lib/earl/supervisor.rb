require "async"
require "earl/agent"
require "earl/channel"

module Earl
  class Supervisor
    include Agent

    def initialize
      @agents = []
      @done = Channel.new
    end

    def monitor(agent)
      if starting?
        @agents << agent
      else
        raise ArgumentError.new("agents must be monitored before starting the supervisor")
      end
      nil
    end

    def call
      agents = @agents
      count = agents.size

      agents.each do |agent|
        Async do
          while running? && agent.starting?
            agent.start(link: self)
          end
        end
      end

      count.times { @done.receive? }
      nil
    end

    def trap(agent, exception = nil)
      if exception
        # Logger.error(agent, exception)
        # log.error { "#{agent.class.name} crashed (#{exception.class.name})" }
        return agent.recycle if running?
      end

      @done.send(1)
      nil
    end

    def terminate
      @agents.reverse_each do |agent|
        agent.stop if agent.running?
      end
      nil
    end

    def reset
      @done = Channel.new
      @agents.each(&:recycle)
      nil
    end
  end
end
