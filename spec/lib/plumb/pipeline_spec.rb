require_relative '../../spec_helper'
require_relative '../../../lib/plumb/pipeline'

module Plumb
  describe Pipeline do
    let(:parent) { Object.new }
    let(:aunty) { Object.new }
    let(:child) { Object.new }

    it "creates jobs on the server" do
      job_repository = MiniTest::Mock.new
      pipeline = Pipeline.new(
        job_repository: job_repository,
        waiting_queue: ::Queue.new,
        order: [
          [parent, aunty],
          [child]
        ]
      )
      job_repository.expect(:create, true, [parent])
      job_repository.expect(:create, true, [aunty])
      job_repository.expect(:create, true, [child])
      pipeline.run
      job_repository.verify
    end

    it "enqueues everything into the waiting queue, in order" do
      null_repo = Object.new
      def null_repo.create(*); end

      waiting_queue = ::Queue.new
      pipeline = Pipeline.new(
        waiting_queue: waiting_queue,
        job_repository: null_repo,
        order: [
          [parent, aunty],
          [child]
        ]
      )
      pipeline.run
      waiting_queue.size.must_equal 3
      waiting_queue.pop.must_equal parent
      waiting_queue.pop.must_equal aunty
      waiting_queue.pop.must_equal child
    end
  end
end

