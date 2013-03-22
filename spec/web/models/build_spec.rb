require_relative '../../spec_helper'
require 'json'

module Plumb
  module Storage
    require 'sequel'
    DB = Sequel.sqlite

    require_relative '../../../web/models/build'

    describe Build do
      it "can store a build" do
        job = Job.new.save
        build = Build.new(job_id: job.id, status: 'Success')
        build.save
        Build[build.id].status.must_equal 'Success'
      end
    end
  end
end
