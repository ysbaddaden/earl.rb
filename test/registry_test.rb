# frozen_string_literal: true
require "test_helper"

module Earl
  class RegistryTest < Minitest::Test
    class Consumer
      include Earl::Agent
      include Earl::Logger
      include Earl::Mailbox

      attr_reader :received

      def initialize
        @received = []
      end

      def call
        while message = receive?
          @received << message
        end
      end
    end

    def test_closed
      Async do
        registry = Registry.new
        registry.stop
        assert registry.closed?
        assert_raises(Earl::ClosedError) { registry.send 123 }
      end
    end

    def test_send
      messages = (0..999).to_a

      Async do
        registry = Registry.new

        consumers = 5.times.map do
          registry.register(consumer = Consumer.new)
          consumer.async
          consumer
        end

        # send all messages
        messages.each { |message| registry.send(message) }
        registry.stop

        # wait for consumers to process messages
        eventually { assert consumers.all?(&:stopped?) }

        # all consumers received all messages in FIFO order
        consumers.each do |consumer|
          assert_equal messages, consumer.received
        end
      end
    end

    def test_silently_removes_stopped_agent
      Async do
        registry = Earl::Registry.new
        registry.register(a = Consumer.new); a.async
        registry.register(b = Consumer.new); b.async

        # send a message (wait to be delivered)
        registry.send(1)
        eventually do
          assert_equal [1], a.received
          assert_equal [1], b.received
        end

        # stop a registered agent (and wait for it)
        a.stop
        eventually { assert a.stopped? }

        # send a second message & stop
        registry.send(2)
        registry.stop

        # the second message shall be received by the registered agent
        eventually { assert_equal [1, 2], b.received }
        # but was never delivered to the stopped one
        eventually { assert_equal [1], a.received }
      end
    end

    def test_stops_registered_agents
      Async do
        registry = Earl::Registry.new
        registry.register(a = Consumer.new); a.async
        registry.register(b = Consumer.new); b.async
        registry.stop
        eventually { assert a.stopped? && b.stopped? }
      end
    end
  end
end
