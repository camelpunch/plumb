require_relative '../spec_helper'
require_relative '../support/shared_examples/queues.rb'
require_relative '../../lib/plumb/resque_queue'

module Plumb
  class ResqueQueueSpec < SpecSupport::QueueSpec
    def queue_named(name, listener = Plumb::NullQueueListener.new)
      ResqueQueue.new(name, listener)
    end
  end
end

