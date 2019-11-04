# frozen_string_literal: true
require "test_helper"
require "earl"

class StatusAgent
  include Earl::Agent

  attr_reader :called
  attr_reader :terminated

  def initialize
    @called = false
    @terminated = false
  end

  def call
    @called = true

    while running?
      sleep(0)
    end
  end

  def terminate
    @terminated = true
  end
end

class Noop
  include Earl::Agent

  attr_reader :called
  attr_reader :terminated

  def initialize
    @called = false
    @terminated = 0
  end

  def call
    @called = true
  end

  def terminate
    @terminated += 1
  end
end

module Earl
  class AgentTest < Minitest::Test
    def test_state
      Async do
        agent = StatusAgent.new
        assert agent.starting?

        Async { agent.start }
        assert agent.running?

        agent.stop
        assert agent.stopping?

        eventually { assert agent.stopped? }
      end
    end

    def test_start_executes_call
      agent = Noop.new
      refute agent.called

      agent.start
      assert agent.called
    end

    def test_start_eventually_executes_terminate
      agent = Noop.new
      agent.start
      assert_equal 1, agent.terminated
      assert agent.stopped?
    end

    def test_stop_executes_terminate
      agent = Noop.new
      agent.__send__(:state).transition(:running)
      agent.stop
      assert_equal 1, agent.terminated
    end

    def test_async
      Async do
        agent = StatusAgent.new
        agent.async
        assert agent.running?
      ensure
        agent.stop
      end
    end
  end
end
