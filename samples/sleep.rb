require "earl/scheduler"

puts "Go to sleep!"

Fiber.set_scheduler(Earl::Scheduler.new)

Fiber.schedule do
  puts "Going to sleep"
  sleep(1)
  puts "I slept well"
end

puts "Wakey-wakey, sleepyhead"
