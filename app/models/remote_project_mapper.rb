require 'faraday'
require_relative 'project'

module Plumb
  class RemoteProjectMapper
    attr_reader :config
    private :config

    def initialize(config)
      @config = config
    end

    def get(id)
      Project.new JSON.parse(connection.get("/projects/#{id}").body)
    end

    def insert(attributes)
      id = attributes[:id]
      other_attributes = attributes.reject {|key, value| key == :id}

      connection.put(
        "/projects/#{attributes[:id]}",
        JSON.generate(other_attributes)
      )
    end

    private

    def connection
      Faraday.new(url: config.endpoint) do |faraday|
        faraday.adapter *config.adapter
      end
    end
  end
end

