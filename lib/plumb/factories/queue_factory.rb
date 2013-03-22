require_relative '../http_job_repository'
require_relative '../queue_logger'

module Plumb
  class QueueFactory
    def initialize(config)
      @waiting_queue_name = config.fetch('waiting_queue')
      @immediate_queue_name = config.fetch('immediate_queue')
      @build_status_endpoint = config.fetch('build_status_endpoint')
      @queue_driver = Plumb.const_get(config.fetch('driver'))
    end

    def waiting_queue
      queue_driver.new(
        waiting_queue_name,
        QueueLogger.new(logger_path('waiting'))
      )
    end

    def immediate_queue
      queue_driver.new(
        immediate_queue_name,
        QueueLogger.new(logger_path('immediate'))
      )
    end

    def job_repository
      HttpJobRepository.new(build_status_endpoint)
    end

    private

    attr_reader(:build_status_endpoint,
                :waiting_queue_name,
                :immediate_queue_name,
                :queue_driver)

    def logger_path(type)
      File.expand_path("../../../../log/#{type}_queue.log", __FILE__)
    end
  end
end
