require_relative 'storage/project'
require_relative 'project'

module Plumb
  class DatabaseProjectMapper
    Error = Class.new(StandardError)

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
      Project.new(project.to_hash.merge(builds: project.builds))
    end

    def insert(attributes)
      id = attributes[:id]
      Storage::Project.create(without_builds(attributes))
      if attributes[:builds]
        Storage::Project[id].add_build(attributes[:builds].first)
      end
    rescue Sequel::ConstraintViolation => e
      raise Error, e.message
    end

    def update(id, attributes)
      project = Storage::Project[id]
      project.update(without_builds(attributes))
      if attributes[:builds]
        project.add_build(attributes[:builds].first.to_hash)
      end
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
