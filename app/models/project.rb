module Plumb
  module Entity
    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      @to_param = id
    end
  end

  class Project
    attr(
      :id,
      :to_param,
      :name,
      :repository_url,
      :ready,
      :script
    )
    attr_accessor :builds

    include Entity

    def initialize(*)
      @builds = []
      super
    end

    def activity
      last_build_status == 'Building' ? 'Building' : 'Sleeping'
    end

    def add_build(attributes)
      builds << Build.new(attributes)
    end

    def last_build_status
      return 'Unknown' if builds.empty?
      last_build.status
    end

    def last_build_id
      return nil if builds.empty?
      last_build.id
    end

    def to_json
      JSON.generate to_hash
    end

    def to_hash
      {
        id: id,
        name: name,
        activity: activity,
        repository_url: repository_url,
        ready: ready,
        script: script,
        builds: builds.map(&:to_hash)
      }
    end

    def ==(other)
      to_hash == other.to_hash
    end

    private

    def last_build
      builds.sort_by(&:started_at).last
    end
  end

  class Build
    attr_reader(:id, :status, :started_at, :completed_at, :project_id)

    include Entity

    def to_hash
      {
        id: id,
        status: status,
        started_at: started_at,
        completed_at: completed_at,
        project_id: project_id
      }
    end
  end
end
