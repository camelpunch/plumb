require_relative '../../spec_helper'
require_relative '../../../lib/plumb/job'
require_relative '../../../lib/plumb/build_status'

module Plumb
  describe Job do
    it "can be parsed from a raw JSON string" do
      job = Job.parse({ name: 'some-job' }.to_json)
      job.name.must_equal 'some-job'
    end

    it "has a JSON representation" do
      Job.new(
        name: 'run tests',
        script: 'rake',
        repository_url: '/some/place'
      ).to_json.must_equal('{"name":"run tests","script":"rake","repository_url":"/some/place"}')
    end

    it "is equivalent to a job with same name" do
      Job.new(name: 'foo', script: 'rake').
        must_equal(Job.new(name: 'foo', script: 'fake'))
    end

    it "is not equivalent to a job with different names" do
      Job.new(name: 'foo').wont_equal(Job.new(name: 'bar'))
    end

    it "defaults to sleeping" do
      Job.new.activity.must_equal 'sleeping'
    end

    it "has a ready? reader" do
      Job.new(ready: false).wont_be :ready?
      Job.new(ready: nil).wont_be :ready?
      Job.new(ready: true).must_be :ready?
    end

    it "uses its name when converting to param" do
      Job.new(name: "foo-id").to_param.must_equal "foo-id"
    end

    it "is building when explicitly set" do
      Job.new(activity: 'building').activity.must_equal 'building'
    end

    it "returns a new job modified by build status" do
      original_job = Job.new(name: 'unit-tests',
                             script: 'rake',
                             activity: 'sleeping',
                             last_build_status: 'failure')
      new_job = original_job.with_build_status(
        BuildStatus.new(status: 'building')
      )
      new_job.wont_be_same_as original_job
      new_job.must_equal Job.new(name: 'unit-tests',
                                 script: 'rake',
                                 activity: 'building',
                                 last_build_status: 'failure')
    end

    it "sets a success build status as the last build status" do
      original_job = Job.new(name: 'unit-tests',
                             script: 'rake',
                             activity: 'sleeping',
                             last_build_status: 'failure')
      new_job = original_job.with_build_status(
        BuildStatus.new(status: :success)
      )
      new_job.wont_be_same_as original_job
      new_job.last_build_status.must_equal 'success'
      new_job.script.must_equal 'rake'
      new_job.activity.must_equal 'sleeping'
    end

    it "sets a failure build status as the last build status" do
      original_job = Job.new(name: 'unit-tests',
                             script: 'rake',
                             activity: 'sleeping',
                             last_build_status: 'success')
      new_job = original_job.with_build_status(
        BuildStatus.new(status: :failure)
      )
      new_job.wont_be_same_as original_job
      new_job.last_build_status.must_equal 'failure'
      new_job.script.must_equal 'rake'
      new_job.activity.must_equal 'sleeping'
    end
  end
end

