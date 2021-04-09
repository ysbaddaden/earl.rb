# frozen_string_literal: true

module Earl
  # A concurrency-safe registry of agents.
  #
  # - Agents may (un)register from the registry at any time.
  # - Registered agents can be iterated with `#each`.
  # - Sent messages are broadcasted to all registered agents.
  # - Failing to deliver a message to an agent will silently unregister it.
  #
  # ### Concurrency
  #
  # Relies on a copy-on-write array:
  # - (un)registering an agent will duplicate the current array (in a lock);
  # - iterations always iterate an immutable older reference to the array.
  #
  # This assumes that agents will (un)register themselves infrequently and
  # messages are sent much more often.
  class Registry
    def initialize
      # @mutex = Mutex.new unless defined?(Async)
      @subscriptions = []
      @closed = false
    end

    def register(agent)
      synchronize do
        raise ClosedError.new if closed?
        dup { |x| x.push(agent) }
      end
    end

    def unregister(agent)
      synchronize do
        dup { |x| x.delete(agent) } unless closed?
      end
    end

    def send(message)
      each do |agent|
        agent.send(message)
      rescue ClosedError
        unregister(agent) unless closed?
      rescue => ex
        Earl.logger.error(agent) { "failed to send to registered agent message=#{ex.message} (#{ex.class.name})" }
        unregister(agent) unless closed?
      end

      sleep(0)
    end

    def each
      raise ClosedError.new if closed?
      subscriptions = @subscriptions
      subscriptions.each { |agent| yield agent }
    end

    def stop
      synchronize { @closed = true }
      @subscriptions.each do |agent|
        agent.stop
      rescue
        nil
      end
      @subscriptions.clear
    end

    def closed?
      @closed
    end

    private

    def synchronize
      if @mutex
        @mutex.synchronize { yield }
      else
        yield
      end
    end

    # NOTE: must be called within `synchronize` block!
    def dup
      subscriptions = @subscriptions.dup
      yield subscriptions
      @subscriptions = subscriptions
    end
  end
end
