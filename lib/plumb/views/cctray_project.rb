module Plumb
  class CCTrayProject
    def initialize(job)
      @job = job
    end

    def job_name
      @job.name
    end

    def activity
      @job.activity.capitalize
    end

    def last_build_status
      return nil unless @job.last_build_status
      @job.last_build_status.capitalize
    end
  end
end
