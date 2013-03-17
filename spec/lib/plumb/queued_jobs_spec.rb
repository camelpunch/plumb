require 'thread'
require_relative '../../spec_helper'
require_relative '../../../lib/plumb/queued_jobs'
require_relative '../../../lib/plumb/message'

module Plumb
  describe QueuedJobs do
    describe "when a job repository is passed" do
      it "refreshes queued jobs before passing to the given block" do
        queue = ::Queue.new
        queue << Message.new('{"name":"Greetings", "ready":false}')

        job_repository = Object.new
        def job_repository.refresh(job)
          Job.new(name: "Greetings", ready: true) if job.name == "Greetings"
        end

        runner = QueuedJobs.new(queue, ->{}, job_repository)

        job_passed = nil
        runner.pop do |job|
          job_passed = job
        end

        job_passed.name.must_equal 'Greetings'
        job_passed.must_be :ready?
      end
    end

    describe "when a job repository is not passed" do
      it "passes jobs directly to the given block" do
        queue = ::Queue.new
        queue << Message.new('{"name":"Greetings", "ready":false}')

        runner = QueuedJobs.new(queue)

        job_passed = nil
        runner.pop do |job|
          job_passed = job
        end

        job_passed.name.must_equal 'Greetings'
        job_passed.wont_be :ready?
      end
    end

    it "calls the callable if job is found" do
      runner = QueuedJobs.new(
        queue = OpenStruct.new(pop: Job.new),
        callable = MiniTest::Mock.new
      )
      callable.expect(:call, nil, [])
      runner.pop {}
      callable.verify
    end

    it "calls the callable if no job is found" do
      runner = QueuedJobs.new(
        queue = OpenStruct.new(pop: nil),
        callable = MiniTest::Mock.new
      )
      callable.expect(:call, nil, [])
      runner.pop {}
      callable.verify
    end

    it "returns nil when popping a nil job and doesn't yield" do
      QueuedJobs.new(OpenStruct.new(pop: nil)).
        pop { raise "should not be called!" }.must_be_nil
    end
  end
end

