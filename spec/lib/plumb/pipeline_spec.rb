require_relative '../../spec_helper'
require_relative '../../../lib/plumb/pipeline'

module Plumb
  describe Pipeline do
    it "is equivalent to another pipeline with the same name" do
      Pipeline.new(name: 'foo').must_equal(
        Pipeline.new(name: 'foo', order: [])
      )
    end

    it "is not equivalent to another pipeline with different name" do
      Pipeline.new(name: 'bar').wont_equal(
        Pipeline.new(name: 'foo')
      )
    end

    it "enqueues the first job into the waiting queue" do
      job1 = Object.new
      job2 = Object.new

      waiting_queue = ::Queue.new
      pipeline = Pipeline.new(
        waiting_queue: waiting_queue,
        order: [[job1], [job2]]
      )
      pipeline.run
      waiting_queue.size.must_equal 1
      waiting_queue.pop.must_equal job1
    end
  end
end

