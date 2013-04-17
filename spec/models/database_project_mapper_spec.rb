require_relative '../spec_helper'
require_relative '../test_db'
require_relative '../../app/models/database_project_mapper'
require_relative '../support/shared_examples/project_mapper'

module Plumb
  class TestDatabaseProjectMapper < MiniTest::Unit::TestCase
    include ProjectMapperSharedTests

    def mapper
      @mapper ||= DatabaseProjectMapper.new
    end

    def test_includes_builds_when_getting_by_id
      attributes = project_hash(
        id: project_id,
        builds: [
          build_hash(id: build_id1, status: 'Success'),
          build_hash(id: build_id2, status: 'Failure'),
        ]
      )

      mapper.insert(attributes)

      project = mapper.get(project_id)
      assert_equal attributes, project.to_hash
      assert_kind_of Build, project.builds.first
    end

    def test_raises_exception_when_id_not_found
      assert_raises(mapper.class::ProjectNotFound) { mapper.get('made-up-id') }
    end

    def test_can_insert_with_string_keys
      name = SecureRandom.hex
      attributes = {
        'id' => project_id,
        'name' => name,
        'activity' => 'Sleeping',
        'repository_url' => nil,
        'ready' => nil,
        'script' => nil,
        'builds' => [ build_hash(id: build_id1, status: 'Success') ]
      }
      mapper.insert(attributes)
      assert_equal 1, mapper.get(project_id).builds.size
    end

    def test_includes_builds_when_finding_by_name
      name = SecureRandom.hex
      attributes = project_hash(
        id: project_id,
        name: name,
        builds: [ build_hash(id: build_id1, status: 'Success') ]
      )
      mapper.insert(attributes)
      project = mapper.find_by_name(name)
      assert_equal attributes, project.to_hash
      assert_kind_of Build, project.builds.first
    end

    def test_returns_nil_if_name_not_found
      mapper.find_by_name('made-up-name').must_be :nil?
    end

    def test_adds_project_to_collection
      name = SecureRandom.hex
      attributes = project_hash(
        name: name,
        builds: [ build_hash(id: build_id1, status: 'Success') ]
      )
      mapper.insert(attributes)
      stored_project = mapper.find_by_name name
      assert_kind_of Project, stored_project
      assert_kind_of Build, stored_project.builds.first
      assert_equal attributes, stored_project.to_hash
    end

    def test_doesnt_add_duplicate_to_collection
      new_name = SecureRandom.hex
      attributes = project_hash
      mapper.insert(attributes)
      old_count = mapper.all.select {|p| p.name == new_name}.size
      mapper.insert(attributes) rescue mapper.class::Conflict
      assert_equal old_count, mapper.all.select {|p| p.name == new_name}.size
    end

    def test_raises_exception_when_duplicate_attempt_made
      attributes = project_hash
      mapper.insert(attributes)
      assert_raises(mapper.class::Conflict) { mapper.insert(attributes) }
    end

    def test_updates_its_attributes
      old_name = SecureRandom.hex
      new_name = SecureRandom.hex
      mapper.insert(project_hash(id: project_id, name: old_name))
      refute_includes mapper.all.map(&:name), new_name
      mapper.update(project_id, name: new_name)
      assert_includes mapper.all.map(&:name), new_name
    end

    def test_raises_exception_if_id_not_found
      assert_raises(mapper.class::ProjectNotFound) { mapper.update('made-up-id', name: 'blah') }
    end

    def test_adds_a_single_build
      name = SecureRandom.hex
      mapper.insert(project_hash(id: project_id, name: name))
      mapper.update(project_id, builds: [{id: build_id1, status: 'Failed'}])
      assert_equal ['Failed'], mapper.find_by_name(name).builds.map(&:status)
    end

    def test_adds_multiple_builds
      name = SecureRandom.hex
      mapper.insert(project_hash(id: project_id, name: name))
      mapper.update(
        project_id,
        builds: [
          {id: build_id1, status: 'Failed'},
          {id: build_id2, status: 'Success'},
      ])
      assert_equal %w(Failed Success), mapper.find_by_name(name).builds.map(&:status)
    end

    def test_updates_a_single_build
      name = SecureRandom.hex
      mapper.insert(project_hash(id: project_id, name: name))
      mapper.update(project_id, builds: [{id: build_id1, status: 'Failed'}])
      mapper.update(project_id, builds: [{id: build_id1, status: 'Success'}])
      assert_equal ['Success'], mapper.find_by_name(name).builds.map(&:status)
    end

    def test_doesnt_update_the_project_if_adding_a_build_fails
      skip
    end

    def test_updates_multiple_builds
      name = SecureRandom.hex
      mapper.insert(project_hash(id: project_id, name: name))
      mapper.update(project_id, builds: [{id: build_id1, status: 'Failed'}])
      mapper.update(project_id, builds: [{id: build_id2, status: 'Failed'}])
      mapper.update(project_id, builds: [{id: build_id1, status: 'Success'}])
      mapper.update(project_id, builds: [{id: build_id2, status: 'Success'}])
      assert_equal %w(Success Success), mapper.get(project_id).builds.map(&:status)
    end

    def test_raises_exception_if_new_build_ID_belongs_to_other_project
      mapper.insert project_hash(id: project_id)
      mapper.insert(
        id: SecureRandom.uuid,
        builds: [ { id: build_id1, status: 'success' } ]
      )
      assert_raises(mapper.class::Conflict) {
        mapper.update(
          project_id,
          builds: [ { id: build_id1, status: 'success' } ]
        )
      }
    end
  end
end
