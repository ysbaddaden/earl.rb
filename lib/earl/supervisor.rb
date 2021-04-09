# frozen_string_literal: true

module Earl
  class Supervisor
    include Agent
    include Logger

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
      count = start_agents
      wait_agents(count)
    end

    def trap(agent, exception = nil)
      if exception
        Earl.logger.exception(agent, exception)
        log.error { "#{agent.class.name} crashed (#{exception.class.name})" }
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

    protected

    def start_agents
      agents = @agents
      count = agents.size

      agents.each do |agent|
        Fiber.schedule do
          while running? && agent.starting?
            agent.start(link: self)
          end
        end
      end

      count
    end

    def wait_agents(count)
      count.times { @done.receive? }
      nil
    end
  end
end
