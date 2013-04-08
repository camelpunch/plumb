require 'json'
require 'date'
require_relative '../spec_helper'
require_relative '../../app/models/project'

module Plumb
  describe Project do
    it "has a name" do
      Project.new(id: SecureRandom.uuid, name: 'unit-tests').
        name.must_equal 'unit-tests'
    end

    it "has builds" do
      project = Project.new
      project.builds.must_equal []
      project.builds = [Build.new]
      project.builds.size.must_equal 1
      Project.new(builds: [Build.new(status: 'Success')]).
        builds.first.status.must_equal 'Success'
    end

    describe "conversions" do
      describe "URL param" do
        it "is equal to its id" do
          Project.new(id: SecureRandom.uuid).tap do |job|
            assert job.id
            job.to_param.must_equal job.id
          end
        end
      end

      describe "Hash" do
        it "exposes attributes" do
          Project.new(
            id: '123',
            name: 'my-project',
            repository_url: 'http://some.url/',
            ready: true,
            script: 'rake',
            builds: [Build.new(id: '456', status: 'Success')]
          ).to_hash.must_equal(
            id: '123',
            name: 'my-project',
            activity: 'Sleeping',
            repository_url: 'http://some.url/',
            ready: true,
            script: 'rake',
            builds: [
              {
                id: '456', status: 'Success', started_at: nil,
                completed_at: nil, project_id: nil
              }
            ]
          )
        end
      end

      describe "JSON" do
        it "contains all its attributes, without a root node" do
          id = SecureRandom.uuid
          JSON.parse(Project.new(id: id, name: "Foo").to_json).
            must_equal(
              "id" => id,
              "name" => "Foo",
              "activity" => 'Sleeping',
              "repository_url" => nil,
              "ready" => nil,
              "script" => nil,
              "builds" => []
          )
        end
      end

      describe "activity" do
        it "is Sleeping when the last started build is completed" do
          project = Project.new(id: SecureRandom.uuid)
          project.add_build(
            id: SecureRandom.uuid,
            status: 'Success',
            started_at: DateTime.new(100, 1, 1),
            completed_at: DateTime.new(100, 1, 1, 1)
          )
          project.add_build(
            id: SecureRandom.uuid,
            status: 'Building',
            started_at: Date.new(0, 1, 1)
          )
          project.activity.must_equal 'Sleeping'

          project.add_build(
            id: SecureRandom.uuid,
            status: "Failure",
            started_at: DateTime.new(200, 1, 1),
            completed_at: DateTime.new(200, 1, 1, 1)
          )
          project.activity.must_equal 'Sleeping'
        end

        it "is Building when the last started build is pending" do
          project = Project.new(id: SecureRandom.uuid)
          project.add_build(
            id: SecureRandom.uuid,
            status: 'Building',
            started_at: DateTime.new(100, 1, 1)
          )
          project.add_build(
            id: SecureRandom.uuid,
            status: 'Success',
            started_at: Date.new(0, 1, 1)
          )
          project.activity.must_equal 'Building'
        end
      end

      describe "last build status" do
        it "is Unknown when there are no associated builds" do
          project = Project.new(id: SecureRandom.uuid)
          project.last_build_status.must_equal 'Unknown'
        end

        it "is retrieved from the last started associated build" do
          project = Project.new(id: SecureRandom.uuid)

          project.add_build(
            id: SecureRandom.uuid,
            status: 'Success',
            started_at: Date.new(0, 1, 1)
          )
          project.last_build_status.must_equal 'Success'

          project.add_build(
            id: SecureRandom.uuid,
            status: 'Failure',
            started_at: Date.new(1066, 10, 14)
          )
          project.last_build_status.must_equal 'Failure'

          project.add_build(
            id: SecureRandom.uuid,
            status: 'Success',
            started_at: Date.new(166, 10, 14)
          )
          project.last_build_status.must_equal 'Failure'
        end
      end

      describe "last build ID" do
        it "is nil when there are no associated builds" do
          project = Project.new(id: SecureRandom.uuid)
          project.last_build_id.must_equal nil
        end

        it "is retrieved from the last started associated build" do
          project = Project.new(id: SecureRandom.uuid)

          ids = (1..3).map do SecureRandom.uuid end

          project.add_build(id: ids[0], started_at: Date.new(0, 1, 1))
          project.last_build_id.must_equal ids[0]

          project.add_build(id: ids[1], started_at: Date.new(1066, 10, 14))
          project.last_build_id.must_equal ids[1]

          project.add_build(id: ids[2], started_at: Date.new(166, 10, 14))
          project.last_build_id.must_equal ids[1]
        end
      end
    end
  end
end
