require_relative '../spec_helper'
require_relative '../test_db'
require_relative '../../app/models/database_project_mapper'

module Plumb
  module ProjectMapperSharedExamples
    def test_has_project_mapper_interface
      mapper.must_respond_to :all
      mapper.must_respond_to :find_by_name
      mapper.must_respond_to :get
    end
  end

  module TestDatabaseProjectMapper
    class Base < MiniTest::Unit::TestCase
      attr_reader :mapper, :project_id, :build_id1, :build_id2

      def setup
        @mapper = DatabaseProjectMapper.new
        @project_id = SecureRandom.uuid
        @build_id1 = SecureRandom.uuid
        @build_id2 = SecureRandom.uuid
      end

      def project_hash(attrs = {})
        {
          id: project_id,
          name: SecureRandom.hex,
          activity: 'Sleeping',
          repository_url: nil,
          ready: nil,
          script: nil
        }.merge(attrs)
      end

      def build_hash(attrs)
        {
          id: nil,
          status: nil,
          started_at: nil,
          completed_at: nil,
          project_id: project_id
        }.merge(attrs)
      end
    end

    class Basics < Base
      include ProjectMapperSharedExamples
    end

    class GettingById < Base
      def test_includes_builds
        attributes = project_hash(
          id: project_id,
          builds: [
            build_hash(id: build_id1, status: 'Success'),
            build_hash(id: build_id2, status: 'Failure'),
          ]
        )

        mapper.insert(attributes)

        project = mapper.get(project_id)
        project.to_hash.must_equal(attributes)
        project.builds.first.must_be_kind_of Build
      end

      def test_raises_exception_when_not_found
        -> { mapper.get('made-up-id') }.
          must_raise DatabaseProjectMapper::ProjectNotFound
      end
    end

    class FindingByName < Base
      def test_includes_builds
        attributes = project_hash(
          id: project_id,
          name: "Cool Build",
          builds: [ build_hash(id: build_id1, status: 'Success') ]
        )

        mapper.insert(attributes)

        project = mapper.find_by_name("Cool Build")
        project.to_hash.must_equal(attributes)
        project.builds.first.must_be_kind_of Build
      end

      def test_returns_nil_if_not_found
        mapper.find_by_name('made-up-name').must_be :nil?
      end
    end

    class Creating < Base
      def setup
        super
        @new_name = SecureRandom.hex
      end

      def test_adds_project_to_collection
        attributes = project_hash(
          name: @new_name,
          builds: [ build_hash(id: build_id1, status: 'Success') ]
        )
        mapper.insert(attributes)
        stored_project = mapper.find_by_name @new_name
        stored_project.must_be_kind_of Project
        stored_project.builds.first.must_be_kind_of Build
        stored_project.to_hash.must_equal(attributes)
      end

      class DuplicateIds < Base
        def setup
          super
          @attributes = project_hash
          mapper.insert(@attributes)
        end

        def test_doesnt_add_duplicate_to_collection
          old_count = mapper.all.select {|p| p.name == @new_name}.size
          mapper.insert(@attributes) rescue DatabaseProjectMapper::Conflict
          mapper.all.select {|p| p.name == @new_name}.size.must_equal old_count
        end

        def test_raises_exception
          -> { mapper.insert(@attributes) }.
            must_raise DatabaseProjectMapper::Conflict
        end
      end
    end

    class Updating < Base
      def setup
        super
        @old_name = SecureRandom.hex
        @new_name = SecureRandom.hex
        mapper.all.select {|p| [@old_name, @new_name].include?(p.name)}.each do |project|
          mapper.delete(project)
        end
        mapper.insert(project_hash(id: project_id, name: @old_name))
      end

      def test_updates_its_attributes
        mapper.all.map(&:name).wont_include(@new_name)
        mapper.update(project_id, name: @new_name)
        mapper.all.map(&:name).must_include(@new_name)
      end

      def test_raises_exception_if_not_found
        -> { mapper.update('made-up-id', name: 'blah') }.
          must_raise DatabaseProjectMapper::ProjectNotFound
      end

      def test_adds_a_single_build
        mapper.update(project_id, builds: [{id: build_id1, status: 'Failed'}])
        mapper.find_by_name(@old_name).builds.map(&:status).
          must_equal ['Failed']
      end

      def test_adds_multiple_builds
        mapper.update(
          project_id,
          builds: [
            {id: build_id1, status: 'Failed'},
            {id: build_id2, status: 'Success'},
        ])
        mapper.find_by_name(@old_name).builds.map(&:status).
          must_equal %w(Failed Success)
      end

      def test_updates_a_single_build
        mapper.update(project_id, builds: [{id: build_id1, status: 'Failed'}])
        mapper.update(project_id, builds: [{id: build_id1, status: 'Success'}])
        mapper.find_by_name(@old_name).builds.map(&:status).
          must_equal ['Success']
      end

      def test_doesnt_update_the_project_if_adding_a_build_fails
        skip
      end

      def test_updates_multiple_builds
        mapper.update(project_id, builds: [{id: build_id1, status: 'Failed'}])
        mapper.update(project_id, builds: [{id: build_id2, status: 'Failed'}])

        mapper.update(project_id, builds: [{id: build_id1, status: 'Success'}])
        mapper.update(project_id, builds: [{id: build_id2, status: 'Success'}])

        mapper.get(project_id).builds.map(&:status).
          must_equal %w(Success Success)
      end

      def test_raises_exception_if_new_build_ID_belongs_to_other_project
        mapper.insert(
          id: SecureRandom.uuid,
          builds: [ { id: build_id1, status: 'success' } ]
        )
        -> {
          mapper.update(
            project_id,
            builds: [ { id: build_id1, status: 'success' } ]
          )
        }.must_raise DatabaseProjectMapper::Conflict
      end
    end
  end
end
