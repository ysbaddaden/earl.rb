# frozen_string_literal: true

module Earl
  class Application < Supervisor
    def signals
      @signals ||= %i[INT TERM]
    end

    def call
      with_scheduler do
        signals.each do |signal|
          Signal.trap(signal) do
            # log.debug { "received SIG#{signal} signal" }
            puts "received SIG#{signal} signal"
            sleep(0.001)
            exit
          end
        end

        at_exit do
          stop if running?
        end

        # start agents then wait for all agents minus Logger that never stops
        count = start_agents
        wait_agents(count - 1)
      end
    end

    private

    def with_scheduler
      if Fiber.scheduler
        yield
      elsif defined?(Async)
        reactor = Async::Task.current.reactor
        begin
          yield
        ensure
          # must stop the reactor loop to exit the program
          reactor.stop
        end
      elsif defined?(Evt)
        scheduler = Evt::Epoll.new
        Fiber.set_scheduler(scheduler)
        yield
        # scheduler will run on thread exit
      end

      nil
    end
  end
end
