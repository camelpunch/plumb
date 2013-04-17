require 'psych'
require_relative '../../config/database' unless defined? DB
require_relative '../../lib/plumb/server/plumb_server'

module Plumb
  class Config
    class Projects
      include Enumerable

      def initialize(projects)
        @projects = projects
      end

      def each(&block)
        @projects.each do |project|
          block.call project
        end
      end

      def find_by_name(name)
        find {|project| project.name == name}
      end
    end

    attr_reader :config
    private :config

    def self.load_file(path)
      new Psych.load_file(path)
    end

    def initialize(config)
      @config = config
    end

    def adapter
      adapter, app_name = server.fetch 'adapter'
      Array(adapter.to_sym).tap do |adapter|
        adapter << Module.const_get(app_name) if app_name
      end
    end

    def endpoint
      server.fetch 'endpoint'
    end

    def projects
      Projects.new(config.fetch('projects').map {|id, project_config|
        Project.new(project_config.merge(id: id))
      })
    end

    private

    def server
      config.fetch 'server'
    end
  end
end
