require_relative 'job'

module Plumb
  class QueuedJobs
    class NullJobRepository
      def refresh(job)
        job
      end
    end

    def initialize(queue,
                   after_pop = ->{},
                   job_repository = NullJobRepository.new)
      @queue = queue
      @job_repository = job_repository
      @after_pop = after_pop
    end

    def pop(&block)
      job = job_from_message(queue.pop)
      block.call(job_repository.refresh(job)) if job
      after_pop.call
    end

    private

    attr_reader :queue, :job_repository, :after_pop

    def job_from_message(message)
      return nil unless message
      Job.new(message.attributes)
    end
  end
end
