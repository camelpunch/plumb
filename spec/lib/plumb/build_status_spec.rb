require 'minitest/autorun'
require_relative '../../../lib/plumb/build_status'
require_relative '../../../lib/plumb/job'

module Plumb
  describe BuildStatus do
    it "can be parsed from a raw JSON string" do
      status = BuildStatus.parse({ build_id: 34, status: "foo" }.to_json)
      status.build_id.must_equal 34
      status.status.must_equal 'foo'
    end

    it "is equivalent to a build status with same attributes" do
      attributes = {
        build_id: 1,
        job: Job.new(name: 'foo'),
        status: :failure
      }
      BuildStatus.new(attributes).
        must_equal(BuildStatus.new(attributes))
    end

    it "is not equivalent to a build status with different attributes" do
      BuildStatus.new(build_id: 1, status: :failure).
        wont_equal(BuildStatus.new(build_id: 1, status: :success))
    end

    it "defaults to sleeping" do
      BuildStatus.new.status.must_equal :sleeping
    end

    it "has a JSON representation of its attributes" do
      BuildStatus.new(build_id: 14,
                      job: Job.new(name: 'foo'),
                      status: :success).to_json.
        must_equal '{"build_id":14,"job":{"name":"foo"},"status":"success"}'
    end

    it "instantiates a job if attributes are passed" do
      BuildStatus.new(job: { name: 'foo' }).
        job.name.must_equal 'foo'
    end

    it "describes itself as successful when success is the status" do
      BuildStatus.new(status: :success).must_be :success?
      BuildStatus.new(status: 'success').must_be :success?
    end

    describe "with a failure status" do
      it "is not a success" do
        BuildStatus.new(status: :failure).wont_be :success?
        BuildStatus.new(status: 'failure').wont_be :success?
      end

      it "is a failure" do
        BuildStatus.new(status: :failure).must_be :failure?
        BuildStatus.new(status: 'failure').must_be :failure?
      end
    end
  end
end
