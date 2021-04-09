# frozen_string_literal: true
require "earl/errors"

module Earl
  class AbstractChannel
    def initialize(capacity = 1000)
      @state = :open
      @capacity = capacity
      @size = 0
      @start = 0
      @values = Array.new(capacity)
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

      close_impl
      nil
    end

    def closed?
      @state == :closed
    end

    protected

    def closing?
      @state != :open
    end

    def send_impl(value)
      yield if closing?

      while full?
        yield if closing?
        wait @senders
      end

      index = @start + @size
      index -= @capacity if index >= @capacity

      @values[index] = value
      @size += 1

      signal @receivers
      nil
    end

    def receive_impl # rubocop:disable Metrics/CyclomaticComplexity
      yield if closed?

      while empty?
        yield if closed?
        wait @receivers
      end

      value = @values[@start]
      @size -= 1
      @start += 1
      @start -= @capacity if @start >= @capacity

      if closing?
        @state = :closed if empty?
      else
        signal @senders
      end

      value
    end

    def close_impl
      broadcast @senders
      broadcast @receivers
    end

    def wait(_condition)
      raise NotImplementedError.new
    end

    def signal(_condition)
      raise NotImplementedError.new
    end

    def broadcast(_condition)
      raise NotImplementedError.new
    end
  end

  # class Channel < AbstractChannel
  #   def initialize(capacity = 1000)
  #     super
  #     @receivers = []
  #     @senders = []
  #   end

  #   protected

  #   def wait(fibers)
  #     fibers << Fiber.current
  #     Fiber.scheduler.block(self)
  #   end

  #   def signal(fibers)
  #     if fiber = fibers.shift
  #       Fiber.scheduler.unblock(self, fiber)
  #     end
  #   end

  #   def broadcast(fibers)
  #     fibers.each { |fiber| Fiber.scheduler.unblock(self, fiber) }
  #     fibers.clear
  #   end
  # end
end

#if defined?(Async)
#  require "async/notification"
#
#  class Earl::Channel < Earl::AbstractChannel
#    def initialize(capacity = 1000)
#      super
#      @senders = Async::Notification.new
#      @receivers = Async::Notification.new
#    end
#
#    protected
#
#    def wait(condition)
#      condition.wait
#    end
#
#    def signal(condition)
#      condition.signal
#    end
#
#    def broadcast(condition)
#      condition.signal
#    end
#  end
#else
  class Earl::Channel < Earl::AbstractChannel
    def initialize(capacity = 1000)
      super
      @mutex = Mutex.new
      @senders = ConditionVariable.new
      @receivers = ConditionVariable.new
    end

    protected

    def send_impl(value)
      @mutex.synchronize { super }
    end

    def receive_impl
      @mutex.synchronize { super }
    end

    def close_impl
      @mutex.synchronize { super }
    end

    def wait(condition)
      condition.wait(@mutex)
    end

    def signal(condition)
      condition.signal
    end

    def broadcast(condition)
      condition.broadcast
    end
  end
#end
