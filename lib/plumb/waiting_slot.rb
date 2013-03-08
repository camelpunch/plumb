require_relative 'job'

module Plumb
  class WaitingSlot
    def initialize(queue)
      @queue = queue
    end

    def receive(job)
      job.ready? ? false : (@queue << job; true)
    end
  end
end
