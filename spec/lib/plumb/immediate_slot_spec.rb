require_relative '../../spec_helper'
require_relative '../../../lib/plumb/immediate_slot'
require_relative '../../../lib/plumb/job'

module Plumb
  describe ImmediateSlot do
    it "moves everything it receives into the given queue" do
      queue = ::Queue.new
      item = 'some item'
      slot = ImmediateSlot.new(queue)
      slot.receive(item).must_equal true
      queue.size.must_equal 1
      queue.pop.must_equal item
    end
  end
end
