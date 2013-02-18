require_relative '../../spec_helper'
require 'yaml'
require_relative '../../support/shared_examples/queues.rb'
require_relative '../../../lib/plumb/sqs_queue'

module Plumb
  class SqsQueueSpec < SpecSupport::QueueSpec
    def queue_named(name)
      SqsQueue.new(
        name,
        YAML.load_file(
          File.expand_path('../../../../config/aws.yml', __FILE__)
        )
      )
    end
  end
end

