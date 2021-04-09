# frozen_string_literal: true

require "earl/agent/state"

module Earl
  module Agent
    def start(link: nil)
      state.transition(:running)

      begin
        call
      rescue => e
        state.transition(:crashed)
        link&.trap(self, e)
      else
        link&.trap(self, nil)
        stop if running?
        state.transition(:stopped)
      end
    end

    def schedule(link: nil)
      Fiber.schedule { start(link: link) }
    end

    def call
      raise NotImplementedError.new("#{self.class.name}#call must be implemented")
    end

    def stop
      state.transition(:stopping)
      terminate
    end

    def terminate
    end

    def trap(agent, exception = nil)
    end

    def recycle
      state.transition(:recycling) unless recycling?
      reset
      state.transition(:starting)
    end

    def reset
    end

    def starting?
      state.value == :starting
    end

    def running?
      state.value == :running
    end

    def stopping?
      state.value == :stopping
    end

    def stopped?
      state.value == :stopped
    end

    def crashed?
      state.value == :crashed
    end

    def recycling?
      state.value == :recycling
    end

    protected

    private

    def state
      @state ||= State.new(self)
    end
  end
end
