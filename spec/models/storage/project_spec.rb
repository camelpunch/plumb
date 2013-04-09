require_relative '../../spec_helper'
require_relative '../../test_db'
require_relative '../../../app/models/storage/project'

module Plumb
  module Storage
    describe Project do
      it "has a name" do
        Project.new(id: SecureRandom.uuid, name: 'unit-tests').
          name.must_equal 'unit-tests'
      end

      it "deletes associated builds when it is deleted" do
        project = Project.create(id: SecureRandom.uuid)
        unique_status = SecureRandom.hex
        project.add_build(id: SecureRandom.uuid, status: unique_status)

        finder = -> { Build.first(status: unique_status) }
        finder.call.wont_be :nil?
        project.destroy
        finder.call.must_be :nil?
      end

      describe "conversions" do
        describe "URL param" do
          it "is equal to its id" do
            Project.create(id: SecureRandom.uuid).tap do |job|
              assert job.id
              job.to_param.must_equal job.id
            end
          end
        end

        describe "JSON" do
          it "contains all its attributes, without a root node" do
            id = SecureRandom.uuid
            JSON.parse(Project.create(id: id, name: "Foo").to_json).
              must_equal(
                "id" => id,
                "name" => "Foo",
                "activity" => nil,
                "repository_url" => nil,
                "ready" => nil,
                "script" => nil
            )
          end
        end

        describe "last build status" do
          it "is Unknown when there are no associated builds" do
            project = Project.create(id: SecureRandom.uuid)
            project.last_build_status.must_equal 'Unknown'
          end

          it "is retrieved from the last started associated build" do
            project = Project.create(id: SecureRandom.uuid)

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
            project = Project.create(id: SecureRandom.uuid)
            project.last_build_id.must_equal nil
          end

          it "is retrieved from the last started associated build" do
            project = Project.create(id: SecureRandom.uuid)

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

      describe "activity" do
        it "is Sleeping when the last started build is completed" do
          project = Project.create(id: SecureRandom.uuid)
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
          project = Project.create(id: SecureRandom.uuid)
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
    end
  end
end
