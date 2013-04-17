require_relative 'storage/project'
require_relative 'project'

module Plumb
  class DatabaseProjectMapper
    Error = Class.new(StandardError)
    ProjectNotFound = Class.new(Error)
    Conflict = Class.new(Error)

    def all
      Storage::Project.all.map &method(:hydrate)
    end

    def get(id)
      project = Storage::Project[id]
      raise ProjectNotFound, "no project with id #{id}" unless project
      hydrate project
    end

    def find_by_name(name)
      hydrate Storage::Project.first(name: name)
    end

    def insert(attributes)
      id = grab attributes, :id
      builds = grab attributes, :builds, []
      Storage::Project.create(without_builds(attributes))
      builds.each do |build_attrs|
        Storage::Project[id].add_build(build_attrs)
      end
    rescue Sequel::ConstraintViolation => e
      raise Conflict, e.message
    end

    def update(id, attributes)
      project = Storage::Project[id]
      raise ProjectNotFound, "no project with id #{id}" unless project

      project.update(without_builds(attributes))

      attributes.fetch(:builds, []).each do |build_attrs|
        existing = project.builds_dataset.first(id: build_attrs[:id])
        if existing
          existing.update(build_attrs)
        else
          project.add_build(build_attrs)
        end
      end

    rescue Sequel::ConstraintViolation => e
      raise Conflict, e.message
    end

    def delete(project)
      Storage::Project[project.id].destroy
    end

    private

    def grab(hash, key, default = nil)
      hash.fetch(key.to_sym, hash.fetch(key.to_s, default))
    end

    def hydrate(stored_project)
      return nil if stored_project.nil?
      Project.new(stored_project.to_hash).tap do |project|
        project.builds = stored_project.builds.map {|build|
          Build.new(build.to_hash)
        }
      end
    end

    def without_builds(attributes)
      attributes.reject {|key, value| [:builds, 'builds'].include?(key)}
    end
  end
end
