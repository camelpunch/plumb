require_relative '../../spec_helper'
require_relative '../../../lib/plumb/waiting_slot'

module Plumb
  describe WaitingSlot do
    let(:unused_queue) { nil }

    it "rejects jobs ready for immediate processing" do
      slot = WaitingSlot.new(unused_queue)
      job = Job.new name: "unit-tests", ready: true
      slot.receive(job).must_equal false
    end

    it "re-queues jobs that aren't ready" do
      queue = ::Queue.new
      slot = WaitingSlot.new(queue)
      job = Job.new name: "unit-tests", ready: false

      slot.receive(job).must_equal true
      queue.size.must_equal 1
      queue.pop.must_equal job
    end
  end
end

