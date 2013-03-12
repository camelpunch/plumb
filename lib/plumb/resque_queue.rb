require 'resque'
require_relative 'message'
require_relative '../../lib/plumb/null_queue_listener'

module Plumb
  class ResqueQueue
    attr_reader :name

    def initialize(name, listener = NullQueueListener.new)
      @name = name
      @listener = listener
    end

    def <<(item)
      Resque::Job.create(name, 'Plumb::ResqueQueue', [item])
      listener.enqueued(item)
    end

    def pop
      job = Resque.pop(name)
      return nil unless job
      converted = convert job
      listener.popped(converted)
      Plumb::Message.new(converted)
    end

    def destroy
      Resque.remove_queue(name)
    end

    private

    attr_reader :listener

    def convert(job)
      job && JSON.generate(job['args'].first.first)
    end
  end
end
