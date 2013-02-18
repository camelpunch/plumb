require_relative '../../spec_helper'
require_relative '../../../lib/plumb/build_status'
require_relative '../../../lib/plumb/job'

module Plumb
  describe BuildStatus do
    it "can be parsed from a raw JSON string" do
      status = BuildStatus.parse({ status: "foo" }.to_json)
      status.status.must_equal 'foo'
    end

    it "is equivalent to a build status with same attributes" do
      attributes = { status: :failure }
      BuildStatus.new(attributes).
        must_equal(BuildStatus.new(attributes))
    end

    it "is not equivalent to a build status with different attributes" do
      BuildStatus.new(status: :failure).
        wont_equal(BuildStatus.new(status: :success))
    end

    it "defaults to sleeping" do
      BuildStatus.new.status.must_equal :sleeping
    end

    it "has a JSON representation of its attributes" do
      BuildStatus.new(status: :success).to_json.
        must_equal '{"status":"success"}'
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
