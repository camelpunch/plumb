require_relative '../../spec_helper'
require_relative '../../../lib/plumb/http_job_repository'

module Plumb
  describe HttpJobRepository do
    it "can refresh a job from the server given a name" do
      repo = HttpJobRepository.new('http://great.repo/')
      job = Job.new(name: 'job1', ready: false)
      stub_request(:get, 'http://great.repo/jobs/job1').
        to_return(body: {name: 'job', ready: true}.to_json)

      repo.refresh(job).must_be :ready?
    end
  end
end
