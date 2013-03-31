require_relative '../../spec_helper'
require_relative '../../../lib/plumb/http_job_repository'

module Plumb
  describe HttpJobRepository do
    describe "refreshing a job" do
      it "returns a refreshed job instance given a name" do
        repo = HttpJobRepository.new('http://great.repo/')
        stub_request(:get, 'http://great.repo/jobs/job1').
          to_return(body: {name: 'job', ready: true}.to_json)

        job = Job.new(name: 'job1', ready: false)
        repo.refresh(job).must_be :ready?
      end

      it "raises an exception when it receives a 404" do
        repo = HttpJobRepository.new('http://great.repo/')
        stub_request(:get, 'http://great.repo/jobs/job1').
          to_return(body: '<h1>Not Found</h1>', status: 404)

        job = Job.new(name: 'job1', ready: false)
        -> { repo.refresh(job) }.must_raise HttpJobRepository::JobNotFound
      end
    end

    describe "storing a job" do
      it "returns true on success" do
        repo = HttpJobRepository.new('http://great.repo/')
        job = Job.new(name: 'job1', ready: false)
        stub_request(:put, 'http://great.repo/jobs/job1').
          with(body: job.to_json).
          to_return(status: 200)

        repo.create(job).must_equal true
      end

      it "returns false on failure" do
        repo = HttpJobRepository.new('http://great.repo/')
        job = Job.new(name: 'job1', ready: false)
        stub_request(:put, 'http://great.repo/jobs/job1').
          with(body: job.to_json).
          to_return(status: 422)

        repo.create(job).must_equal false
      end

      it "raises an exception when it receives a 404" do
        repo = HttpJobRepository.new('http://great.repo/')
        stub_request(:put, 'http://great.repo/jobs/job1').
          to_return(body: '<h1>Not Found</h1>', status: 404)

        job = Job.new(name: 'job1', ready: false)
        -> { repo.create(job) }.must_raise HttpJobRepository::JobNotFound
      end
    end
  end
end
