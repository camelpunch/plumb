require 'aws/sqs'
require_relative 'message'
require_relative '../../lib/plumb/null_queue_listener'

module Plumb
  class SqsQueue
    attr_reader :name

    def initialize(name, options = {}, listener = NullQueueListener.new)
      @name = name
      @listener = listener
      sqs = AWS::SQS.new(options)
      @queue = sqs.queues.named(name)
    rescue AWS::SQS::Errors::NonExistentQueue
      @queue = sqs.queues.create(name)
    end

    def <<(item)
      @queue.send_message(item.to_json)
      listener.enqueued(item)
    end

    def pop
      @queue.receive_message(initial_timeout: 5, idle_timeout: 5) do |message|
        unless message.body.empty?
          listener.popped(message.body)
          return Message.new(message.body)
        end
      end
    end

    def destroy
      @queue.delete
    rescue AWS::SQS::Errors::NonExistentQueue
    end

    private

    attr_reader :listener
  end
end
