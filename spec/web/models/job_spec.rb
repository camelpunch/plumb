require 'json'
require 'sequel'
require_relative '../../spec_helper'
require_relative '../../../lib/plumb/build_status'

module Plumb
  module Storage
    DB = Sequel.sqlite

    require_relative '../../../web/models/job'
    require_relative '../../../web/models/build'

    describe Job do
      it "can store a job" do
        job = Job.new(name: 'unit-tests',
                      repository_url: '/some/place.git')
        job.save
        Job[job.id].name.must_equal 'unit-tests'
      end

      it "defaults to sleeping" do
        Job.new.activity.must_equal 'sleeping'
      end

      it "has a JSON representation" do
        job = Job.new(name: 'unit-tests',
                      activity: 'sleeping',
                      repository_url: '/some/place.git',
                      ready: true)
        JSON.parse(job.to_json).must_equal(
          'name' => 'unit-tests',
          'activity' => 'sleeping',
          'repository_url' => '/some/place.git',
          'ready' => true
        )
      end

      describe "when a build is started" do
        it "changes its activity" do
          job = Job.new(name: 'unit-tests')
          job.save
          job.build_started(BuildStatus.new(status: 'building'))
          job.reload.activity.must_equal 'building'
        end

        it "has a new last build status" do
          job = Job.new(name: 'unit-tests')
          job.save
          job.build_started(BuildStatus.new(status: 'building'))
          job.reload.last_build_status.must_equal 'building'
        end
      end

      describe "when a build fails" do
        it "is sleeping" do
          job = Job.create(name: 'unit-tests')
          job.build_started(BuildStatus.new(status: 'building'))
          job.build_finished(BuildStatus.new(status: 'failure'))
          job.reload.activity.must_equal 'sleeping'
        end

        it "doesn't add a new build" do
          job = Job.create(name: 'unit-tests')
          job.build_started(BuildStatus.new(status: 'building'))
          job.build_finished(BuildStatus.new(status: 'failure'))
          job.builds.count.must_equal 1
        end

        it "has a last build status of failure" do
          job = Job.create(name: 'unit-tests')
          job.build_started(BuildStatus.new(status: 'building'))
          job.build_finished(BuildStatus.new(status: 'failure'))
          job.reload.last_build_status.must_equal 'failure'
        end
      end

      it "can return the last build's status" do
        job = Job.new(name: 'unit-tests')
        job.save
        job.add_build(Build.new(status: 'Failure'))
        job.last_build_status.must_equal 'Failure'
        job.add_build(Build.new(status: 'Success'))
        job.last_build_status.must_equal 'Success'
      end
    end
  end
end
