module Plumb
  class Clerk
    def initialize(inbox, *slots)
      @inbox = inbox
      @slots = slots
    end

    def deliver_next_item
      @inbox.pop do |item|
        @slots.detect {|slot| slot.receive(item)}
      end
    end
  end
end
