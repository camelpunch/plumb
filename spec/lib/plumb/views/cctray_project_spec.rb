require_relative '../../../spec_helper'
require_relative '../../../../lib/plumb/build_status'
require_relative '../../../../lib/plumb/views/cctray_project'
require_relative '../../../../lib/plumb/job'

module Plumb
  describe CCTrayProject do
    it "shows capitalized statuses" do
      job = Job.new name: 'foo', last_build_status: 'success', activity: "building"
      project = CCTrayProject.new(job)
      project.last_build_status.must_equal 'Success'
      project.activity.must_equal 'Building'
    end

    it "copes with nil build status" do
      job = Job.new name: 'foo', last_build_status: nil
      project = CCTrayProject.new(job)
      project.last_build_status.must_be_nil
    end
  end
end
