require "async"
require "async/notification"
require "earl/errors"

module Earl
  class Channel
    def initialize(capacity = 1)
      @state = :open
      @capacity = capacity
      @size = 0
      @start = 0
      @values = []
      @senders = Async::Notification.new
      @receivers = Async::Notification.new
    end

    def empty?
      @size == 0
    end

    def full?
      @size == @capacity
    end

    def send(value)
      send_impl(value) { raise ClosedError.new }
    end

    def receive
      receive_impl { raise ClosedError.new }
    end

    def receive?
      receive_impl { return nil }
    end

    def close
      return if closing?

      if empty?
        @state = :closed
      else
        @state = :closing
      end

      @senders.signal   # .broadcast
      @receivers.signal # .broadcast

      nil
    end

    protected

    def closing?
      @state != :open
    end

    def closed?
      @state == :closed
    end

    def send_impl(value)
      yield if closing?

      while full?
        yield if closing?
        @senders.wait
      end

      index = @start + @size
      index -= @capacity if index >= @capacity

      @values[index] = value
      @size += 1

      @receivers.signal
      nil
    end

    def receive_impl
      yield if closed?

      while empty?
        yield if closed?
        @receivers.wait
      end

      value = @values[@start]
      @size -= 1
      @start += 1
      @start -= @capacity if @start >= @capacity

      if closing?
        @state = :closed if empty?
      else
        @senders.signal
      end

      value
    end
  end
end
