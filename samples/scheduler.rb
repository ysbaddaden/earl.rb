require "earl/scheduler"
require "net/http"

Thread.new do
  scheduler = Earl::Scheduler.new
  Fiber.set_scheduler(scheduler)

  %w[2.6 2.7 3.0].each do |version|
    Fiber.schedule do
      t = Time.now
      Net::HTTP.get("rubyreferences.github.io", "/rubychanges/#{version}.html")
      puts "%s: finished in %.3f" % [version, Time.now - t]
    end
  end

  scheduler.run
end.join
