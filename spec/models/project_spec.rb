require_relative '../spec_helper'
require_relative '../../app/models/project'

module Plumb
  describe Project do
    it "has a name" do
      Project.new(id: SecureRandom.uuid, name: 'unit-tests').name.
        must_equal 'unit-tests'
    end

    it "deletes associated builds when it is deleted" do
      project = Project.create(id: SecureRandom.uuid)
      project.add_build(id: SecureRandom.uuid, status: 'asdf')
      builds_count_before_delete = Build.count
      project.destroy
      Build.count.must_equal builds_count_before_delete - 1
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
              "ready" => nil
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
