# frozen_string_literal: true
require "earl"

class Foo
  include Earl::Artist

  def handle(message)
    case message
    when String
      log.info [:string, message].inspect
    when Integer
      log.info { [:number, message].inspect }
    end
  end
end

class Bar
  include Earl::Artist

  def initialize(foo)
    @foo = foo
  end

  def handle(number)
    if number.odd?
      @foo.send(number)
    else
      @foo.send(number.to_s)
    end
  end
end

Async do
  # create agents:
  foo = Foo.new
  Earl.application.monitor(foo)

  bar = Bar.new(foo)
  Earl.application.monitor(bar)

  # spawn all agents (supervisor, logger, foo, bar)
  Earl.application.async

  # send some messages:
  1.upto(5) { |i| bar.send(i) }

  # let agents run:
  Earl.sleep(0.010)

  # stop everything:
  Earl.application.stop
end
