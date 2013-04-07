require_relative 'project'

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
      @adapter = [ adapter.to_sym, Module.const_get(app_name) ]
      @projects = config.fetch('projects').map { |id, project_config|
        Project.new(project_config.merge(id: id))
      }
    end
  end
end
