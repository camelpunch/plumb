require_relative 'build_status'

module Plumb
  class Builder
    def initialize(job, repo, reporter)
      @repo = repo
      @job = job
      @reporter = reporter
    end

    def run
      repo.fetch job.repository_url, self
    end

    def process_working_copy(dir)
      promise = reporter.build_started(job)

      if system("cd #{dir.path} && #{job.script}")
        promise.fulfil
      else
        promise.break
      end
    end

    def handle_clone_failure
      reporter.build_failed(job)
    end

    private

    attr_reader :job, :repo, :reporter
  end
end

