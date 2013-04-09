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
      end
    end
  end
end
