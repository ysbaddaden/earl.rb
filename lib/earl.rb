# frozen_string_literal: true
require "earl/agent"

module Earl
  def self.sleep(duration)
    if task = Async::Task.current?
      task.sleep(duration)
    else
      Kernel.sleep(duration)
    end
  end
end
