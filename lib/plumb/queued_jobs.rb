require_relative 'job'

module Plumb
  class QueuedJobs
    class NullJobRepository
      def refresh(job)
        job
      end
    end

    def initialize(queue, callable_when_empty = ->*{},
                   job_repository = NullJobRepository.new)
      @queue = queue
      @job_repository = job_repository
      @callable_when_empty = callable_when_empty
    end

    def pop(&block)
      job = job_from_message(queue.pop)

      if job
        block.call(job_repository.refresh(job))
      else
        callable_when_empty.call
      end
    end

    private

    attr_reader :queue, :job_repository, :callable_when_empty

    def job_from_message(message)
      return nil unless message
      Job.new(message.attributes)
    end
  end
end
