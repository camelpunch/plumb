require 'psych'
require_relative '../../config/database' unless defined? DB
require_relative 'project'
require_relative '../../lib/plumb/server/plumb_server'

module Plumb
  class Config
    attr_reader :adapter, :endpoint, :projects

    def self.load_file(path)
      new Psych.load_file(path)
    end

    def initialize(config)
      server = config.fetch('server')
      adapter, app_name = server.fetch('adapter')
      @endpoint = server['endpoint']
      @adapter =
        app_name ? [ adapter.to_sym, Module.const_get(app_name) ]
                 : [ adapter.to_sym ]
      @projects = config.fetch('projects').map { |id, project_config|
        Project.new(project_config.merge(id: id))
      }
    end
  end
end
