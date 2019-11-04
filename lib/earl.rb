# frozen_string_literal: true
require "earl/agent"
require "earl/artist"
require "earl/mailbox"

module Earl
  def self.sleep(duration)
    if task = Async::Task.current?
      task.sleep(duration)
    else
      Kernel.sleep(duration)
    end
  end
end
