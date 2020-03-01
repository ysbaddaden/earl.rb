# frozen_string_literal: true

module Earl
  class Application < Supervisor
    def signals
      @signals ||= [:INT, :TERM]
    end

    def call
      @reactor = Async::Task.current.reactor

      signals.each do |signal|
        Signal.trap(signal) do
          # log.debug { "received SIG#{signal} signal" }
          puts "received SIG#{signal} signal"
          Earl.sleep(0.001)
          exit
        end
      end

      at_exit do
        stop if running?
      end

      # start agents then wait for all agents minus Logger that never stops
      count = start_agents
      wait_agents(count - 1)
    ensure
      # stop the reactor loop to exit the program
      @reactor.stop
    end
  end
end
