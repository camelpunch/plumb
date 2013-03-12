require 'ostruct'
require_relative '../plumb'
require_relative 'job'

module Plumb
  class Pipeline
    class << self
      def parse(options, queue_config)
        new(order: job_order(options['order']),
            waiting_queue: waiting_queue(queue_config),
            job_repository: HttpJobRepository.new(config.fetch('build_status_endpoint')))
      end
    end

    def initialize(options)
      @order = options.fetch :order
      @waiting_queue = options.fetch :waiting_queue
      @job_repository = options.fetch :job_repository
    end

    def run
      order.flatten.each do |job|
        job_repository.create(job)
        waiting_queue << job
      end
    end

    private

    attr_reader :waiting_queue, :order, :job_repository
  end
end
