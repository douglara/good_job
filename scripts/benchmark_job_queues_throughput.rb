# To run:
# bundle exec ruby scripts/benchmark_example.rb
#

ENV['GOOD_JOB_EXECUTION_MODE'] = 'external'

require_relative '../spec/test_app/config/environment'
require_relative '../lib/good_job'
require 'benchmark/ips'
require 'pry'
require 'benchmark'

@jobs = 100
@queues = 5

def make_seed(jobs, queues)
  GoodJob::Job.delete_all

  queues.times.each do | queue_count | 
    jobs_data = Array.new(jobs) do |i|
      {
        queue_name: "queue_#{queue_count + 1}",
        created_at: 90.minutes.ago,
        updated_at: 90.minutes.ago,
      }
    end
    GoodJob::Job.insert_all(jobs_data)
  end
end

def run_default_order
  current_queue_name = ""
  while current_queue_name != "queue_#{@queues}" do
    GoodJob::Job.unfinished.priority_ordered.only_scheduled.limit(1).with_advisory_lock(unlock_session: true) do |good_jobs|
      current_queue_name = good_jobs.first.queue_name
      good_jobs.first&.destroy!
    end
  end
end

def run_queue_random_order
  current_queue_name = ""
  while current_queue_name != "queue_#{@queues}" do
    GoodJob::Job.unfinished.queue_random_order.priority_ordered.only_scheduled.limit(1).with_advisory_lock(unlock_session: true) do |good_jobs|
      current_queue_name = good_jobs.first.queue_name
      good_jobs.first&.destroy!
    end
  end
end


Benchmark.ips do |x|
  x.report("default queue order") do
    make_seed(@jobs, @queues)
    run_default_order()
  end

  x.report("random queue order") do
    make_seed(@jobs, @queues)
    run_queue_random_order()
  end

  x.compare!
end

Benchmark.bm do |x|
  make_seed(@jobs, @queues)
  x.report("default queue order") { run_default_order }
  make_seed(@jobs, @queues)
  x.report("random queue order") { run_queue_random_order }
end