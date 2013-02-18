require_relative 'build_status'

module Plumb
  class Build
    def initialize(job, repo, reporter)
      @repo = repo
      @job = job
      @reporter = reporter
    end

    def run
      @repo.fetch @job.repository_url, self
    end

    def process_working_copy(dir)
      @reporter.build_started(@job)

      if system("cd #{dir.path} && #{@job.script}")
        @reporter.build_succeeded(@job)
      else
        @reporter.build_failed(@job)
      end
    end

    def handle_clone_failure
      @reporter.build_failed(@job)
    end
  end
end

