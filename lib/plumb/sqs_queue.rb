require 'aws/sqs'
require_relative 'message'

module Plumb
  class SqsQueue
    attr_reader :name

    def initialize(name, options = {})
      @name = name
      sqs = AWS::SQS.new(options)
      @queue = sqs.queues.named(name)
    rescue AWS::SQS::Errors::NonExistentQueue
      @queue = sqs.queues.create(name)
    end

    def <<(item)
      @queue.send_message(item.to_json)
    end

    def pop
      @queue.receive_message(initial_timeout: 5, idle_timeout: 5) do |message|
        return Message.new(message.body) unless message.body.empty?
      end
    end

    def destroy
      @queue.delete
    rescue AWS::SQS::Errors::NonExistentQueue
    end
  end
end
