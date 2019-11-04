require "earl/channel"

module Earl
  module Mailbox
    DEFAULT_CAPACITY = 10

    attr_writer :mailbox_capacity

    def mailbox_capacity
      @mailbox_capacity ||= DEFAULT_CAPACITY
    end

    def mailbox=(channel)
      @mailbox_close_on_stop = false
      @mailbox = channel
    end

    def send(message)
      mailbox.send(message)
    end

    # :nodoc:
    def stop
      @mailbox.close if @mailbox_close_on_stop && @mailbox
      super
    end

    protected

    def receive
      mailbox.receive
    end

    def receive?
      mailbox.receive?
    end

    private

    def mailbox
      @mailbox ||=
        begin
          @mailbox_close_on_stop = true
          Channel.new(mailbox_capacity)
        end
    end
  end
end
