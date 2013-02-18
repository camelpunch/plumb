require_relative '../../spec_helper'
require 'thread'
require_relative '../../../lib/plumb/queue_runner'
require_relative '../../../lib/plumb/sqs_queue'

module Plumb
  describe QueueRunner do
    let(:reject) { ->*{ raise "should not be called!" } }

    it "passes a popped job to a given block of code" do
      runner = QueueRunner.new(
        OpenStruct.new(pop: Message.new('{"name":"Greetings"}')),
        ->{}
      )

      job_passed = nil
      runner.run do |job|
        job_passed = job
      end

      job_passed.must_equal Job.new(name: 'Greetings')
    end

    it "calls the callable if nothing was found" do
      runner = QueueRunner.new(
        queue = OpenStruct.new(pop: nil),
        callable = MiniTest::Mock.new
      )
      callable.expect(:call, nil, [])
      runner.run {}
      callable.verify
    end

    it "returns nil when popping a nil job (doesn't yield)" do
      QueueRunner.new(OpenStruct.new(pop: nil), ->{}).
        run(&reject).must_be_nil
    end
  end
end

