# frozen_string_literal: true

require "fiber"
require "nio"
require "timers"

module Earl
  class Scheduler
    def initialize
      @selector = NIO::Selector.new
      @timers = Timers::Group.new
      @ready = []
      @blocked = {}
    end

    def process_wait(pid, flags)
      if (flags & Process::WNOHANG) == Process::WNOHANG
        Process::Status.wait(pid, flags)
      else
        Thread.new { Process::Status.wait(pid, flags) }.value
      end
    end

    def io_wait(io, events, timeout)
      # p [:io_wait, io, events_to_nio_interests(events), timeout]
      fiber = Fiber.current

      blk = proc { enqueue(fiber) }
      monitor = @selector.register(io, events_to_nio_interests(events))
      monitor.value = blk
      timer = @timers.after(timeout, &blk) if timeout

      Fiber.yield

      # p [:io_resume, io, monitor.readiness, io.closed?]

      timer&.cancel
      monitor.close
      nio_interests_to_events(monitor.readiness)
    end

    def kernel_sleep(duration = nil)
      # NOTE: ConditionVariable#wait eventually calls #kernel_sleep instead of
      # #block in Ruby 3.0.0 so we always call #block to make sure to always
      # have a #block then #unblock calls:
      block(:sleep, duration)

      # fiber = Fiber.current
      # @timers.after(duration) { enqueue(fiber) } if duration
      # Fiber.yield
    end

    def block(blocker, timeout = nil)
      fiber = Fiber.current
      timer = @timers.after(timeout) { unblock(blocker, fiber) } if timeout
      @blocked[fiber] = timer
      Fiber.yield
      true
    end

    def unblock(blocker, fiber)
      @blocked.delete(fiber)&.cancel
      enqueue(fiber)

      # resume the NIO selector, because it may be blocking the loop
      @selector.wakeup
      nil
    end

    def fiber(&block)
      fiber = Fiber.new(blocking: false, &block)
      fiber.resume # immediately yield control to the fiber (seems to be expected)
      fiber
    end

    def close
      run
    end

    def run
      until done?
        if @ready.empty?
          # try to replenish the queue, blocking until something is ready,
          # making sure to resume when the next timer must be triggered
          wait_interval = @timers.wait_interval&.clamp(0..)
          @selector.select(wait_interval) { |monitor| monitor.value.call }

          # trigger expired sleeps & timeouts
          @timers.fire
        end

        # resume next ready fiber (if any)
        @ready.shift&.resume
      end
    ensure
      @selector.close
      @timers.cancel
      @ready.clear
      @blocked.clear
    end

    private

    def done?
      @ready.empty? && @selector.empty? && @timers.empty? && @blocked.empty?
    end

    def enqueue(fiber)
      @ready << fiber
    end

    def events_to_nio_interests(events)
      readable = (events & IO::READABLE) == IO::READABLE
      writable = (events & IO::WRITABLE) == IO::WRITABLE

      if readable && writable
        :rw
      elsif readable
        :r
      elsif writable
        :w
      end
    end

    def nio_interests_to_events(interests)
      case interests
      when :rw
        IO::READABLE | IO::WRITABLE
      when :r
        IO::READABLE
      when :w
        IO::WRITABLE
      else
        0
      end
    end
  end
end
