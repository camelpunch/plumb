require 'yaml'
require_relative '../spec_helper'
require_relative '../support/shared_examples/queues.rb'
require_relative '../../lib/plumb/sqs_queue'

module Plumb
  class SqsQueueSpec < SpecSupport::QueueSpec
    def queue_named(name, listener = Plumb::NullQueueListener.new)
      SqsQueue.new(
        name,
        YAML.load_file(
          if File.exists?(ENV['PLUMB_AWS_CONFIG'].to_s)
            ENV['PLUMB_AWS_CONFIG']
          else
            File.expand_path('../../../config/aws.yml', __FILE__)
          end
        ),
        listener
      )
    end
  end
end

