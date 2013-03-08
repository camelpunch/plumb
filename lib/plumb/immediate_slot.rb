module Plumb
  class ImmediateSlot
    def initialize(queue)
      @queue = queue
    end

    def receive(item)
      @queue << item
      true
    end
  end
end
