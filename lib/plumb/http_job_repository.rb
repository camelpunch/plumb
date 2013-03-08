require 'httparty'
require_relative 'job'

module Plumb
  class HttpJobRepository
    def initialize(url)
      @url = url
    end

    def refresh(job)
      Job.new(
        server.get("/jobs/#{job.to_param}")
      )
    end

    private

    attr_reader :url

    def server
      @server ||= Class.new { include HTTParty }.tap do |server|
        server.format :json
        server.base_uri url
      end
    end
  end
end
