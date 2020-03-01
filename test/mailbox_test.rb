# frozen_string_literal: true
require "test_helper"

module Earl
  class MailboxTest < Minitest::Test
    class Counter
      include Earl::Agent
      include Earl::Mailbox

      attr_reader :value

      def initialize(value = 0)
        @value = value
      end

      def call
        while increment = receive?
          @value += increment
        end
      end
    end

    def test_send
      Async do
        counter = Counter.new(0)
        counter.async

        counter.send(2)
        eventually { assert_equal 2, counter.value }

        counter.send(10)
        counter.send(23)
        counter.send(54)
        counter.stop
        eventually { assert_equal 89, counter.value }

        assert_raises(ClosedError) { counter.send(102) }
      end
    end

    def test_receive
      Async do
        counter = Counter.new(0)

        counter.send(1)
        counter.send(2)
        assert_equal 1, counter.__send__(:receive)
        assert_equal 2, counter.__send__(:receive)

        counter.async
        counter.stop

        assert_raises(ClosedError) { counter.__send__(:receive) }
        assert_nil counter.__send__(:receive?)
      end
    end
  end
end
