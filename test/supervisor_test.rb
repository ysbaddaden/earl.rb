# frozen_string_literal: true
require "test_helper"
require "earl"

module Earl
  class SupervisorTest < Minitest::Test
    class Pending
      include Earl::Artist

      def handle(arg)
      end
    end

    class Noop
      include Earl::Agent

      def initialize(monkey = false)
        @monkey = monkey
      end

      def call
        return unless @monkey
        Earl.sleep 0
        raise "chaos"
      end
    end

    def test_starts_and_stops_monitored_agents
      Async do
        agents = [Pending.new, Pending.new, Pending.new]
        supervisor = Supervisor.new

        agents.each { |agent| supervisor.monitor(agent) }
        assert supervisor.starting?
        assert agents.all?(&:starting?)

        supervisor.async
        eventually { assert supervisor.running? }
        eventually { assert agents.all?(&:running?) }

        supervisor.stop
        eventually { assert supervisor.stopped? }
        eventually { assert agents.all? { |a| a.stopped? || a.stopping? } }
      end
    end

    def test_normal_termination_of_supervised_agents
      Async do
        agents = [Noop.new, Noop.new]
        supervisor = Supervisor.new

        agents.each { |agent| supervisor.monitor(agent) }
        assert supervisor.starting?
        assert agents.all?(&:starting?)

        supervisor.async

        eventually { assert supervisor.stopped? || supervisor.stopping? }
        eventually { assert agents.all? { |a| a.stopped? || a.stopping? } }
      end
    end

    def test_recycles_supervised_agents
      Async do
        agent = Noop.new(monkey: true)
        supervisor = Supervisor.new

        supervisor.monitor(agent)
        assert supervisor.starting?
        assert agent.starting?

        supervisor.async
        eventually { assert supervisor.running? }

        10.times do
          eventually { refute agent.crashed? }
        end

        supervisor.stop
      end
    end
  end
end
