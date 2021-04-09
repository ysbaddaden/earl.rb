require "earl/scheduler"
require "earl/channel"

scheduler = Earl::Scheduler.new
Fiber.set_scheduler(scheduler)

mutex = Mutex.new
queue = Queue.new
done = 0

10.times do
  Fiber.schedule do
    10_000.times { |i| queue.push(i) }
    mutex.synchronize { done += 1 }

    if done == 10
      sleep 1
      queue.close
    end
  end
end

2.times do
  Fiber.schedule do
    while i = queue.pop
      $stderr.puts(i)
    end
  end
end

scheduler.run
