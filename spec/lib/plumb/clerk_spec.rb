require_relative '../../spec_helper'
require_relative '../../../lib/plumb/clerk'

module Plumb
  describe Clerk do
    let(:unused_queue) { nil }

    def inbox_with(item)
      Object.new.tap do |inbox|
        inbox.define_singleton_method(:pop) do |&block|
          block.call(item)
        end
      end
    end

    it "sends provided item to first slot that will accept it, then stops" do
      item = 'some item'
      slots = [MiniTest::Mock.new] * 3

      clerk = Clerk.new(inbox_with(item), *slots)

      slots[0].expect(:receive, false, [item])
      slots[1].expect(:receive, true, [item])

      clerk.deliver_next_item

      slots[0].verify
      slots[1].verify
    end
  end
end
