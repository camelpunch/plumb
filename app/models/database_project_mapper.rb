require_relative 'storage/project'
require_relative 'project'

module Plumb
  class DatabaseProjectMapper
    Error = Class.new(StandardError)
    ProjectNotFound = Class.new(Error)
    Conflict = Class.new(Error)

    def all
      Storage::Project.all.map { |stored_project|
        Project.new(stored_project.to_hash).tap do |project|
          project.builds = stored_project.builds.map {|build|
            Build.new(build.to_hash)
          }
        end
      }
    end

    def get(id)
      project = Storage::Project[id]
      raise ProjectNotFound, "no project with id #{id}" unless project
      Project.new(project.to_hash.merge(
        builds: project.builds.map {|build| Build.new(build.to_hash)}
      ))
    end

    def insert(attributes)
      id = attributes[:id]
      Storage::Project.create(without_builds(attributes))
      if attributes[:builds]
        Storage::Project[id].add_build(attributes[:builds].first)
      end
    rescue Sequel::ConstraintViolation => e
      raise Conflict, e.message
    end

    def update(id, attributes)
      project = Storage::Project[id]
      raise ProjectNotFound, "no project with id #{id}" unless project

      project.update(without_builds(attributes))

      return unless attributes[:builds]

      attributes[:builds].each do |build_attrs|
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

    def without_builds(attributes)
      attributes.reject {|key, value| key == :builds}
    end
  end
end
