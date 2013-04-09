require 'ostruct'
require_relative '../spec_helper'
require_relative '../test_db'
require_relative '../../app/models/database_project_mapper'

module Plumb
  describe DatabaseProjectMapper do
    let(:mapper) { DatabaseProjectMapper.new }
    let(:old_name) { SecureRandom.hex }
    let(:new_name) { SecureRandom.hex }
    let(:project_id) { SecureRandom.uuid }
    let(:build_id) { SecureRandom.uuid }

    def project_hash(attrs = {})
      {
        id: project_id,
        name: new_name,
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

    describe "getting a project by ID" do
      it "includes its builds" do
        attributes = project_hash(
          id: project_id,
          builds: [ build_hash(id: build_id, status: 'Success') ]
        )

        mapper.insert(attributes)

        project = mapper.get(project_id)
        project.to_hash.must_equal(attributes)
      end

      it "raises an exception if there is no such project" do
        -> { mapper.get('made-up-id') }.
          must_raise DatabaseProjectMapper::ProjectNotFound
      end
    end

    describe "creating a single project" do
      it "updates the collection with the new project" do
        attributes = project_hash(
          name: new_name,
          builds: [ build_hash(id: build_id, status: 'Success') ]
        )
        mapper.insert(attributes)
        stored_project = mapper.all.find {|p| p.name == new_name}
        stored_project.must_be_kind_of Project
        stored_project.builds.first.must_be_kind_of Build
        stored_project.to_hash.must_equal(attributes)
      end

      describe "when its ID already exists" do
        let(:attributes) { project_hash }

        before do
          mapper.insert(attributes)
        end

        it "doesn't create a new project" do
          old_count = mapper.all.select {|p| p.name == new_name}.size
          mapper.insert(attributes) rescue nil
          mapper.all.select {|p| p.name == new_name}.size.must_equal old_count
        end

        it "raises an exception" do
          -> { mapper.insert(attributes) }.
            must_raise DatabaseProjectMapper::Error
        end
      end
    end

    describe "updating a single project" do
      before do
        mapper.all.select {|p| [old_name, new_name].include?(p.name)}.each do |project|
          mapper.delete(project)
        end

        attributes = project_hash(id: project_id, name: old_name)
        mapper.insert(attributes)
      end

      it "updates the existing project attributes" do
        mapper.all.map(&:name).wont_include(new_name)
        mapper.update(project_id, name: new_name)
        mapper.all.map(&:name).must_include(new_name)
      end

      it "updates its builds" do
        mapper.all.select {|p| p.name == old_name}.
          flat_map(&:builds).map(&:status).must_be :empty?
        mapper.update(project_id,
                      builds: [Build.new(id: build_id, status: 'Failed')])
        mapper.all.select {|p| p.name == old_name}.
          flat_map(&:builds).map(&:status).must_equal ['Failed']
      end

      it "raises an exception if the project is not found" do
        -> { mapper.update('made-up-id', name: 'blah') }.
          must_raise DatabaseProjectMapper::ProjectNotFound
      end

      describe "when a build already exists" do
        it "raises an exception"
      end
    end
  end
end
