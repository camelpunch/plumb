require 'httparty'
require_relative 'job'

module Plumb
  class HttpJobRepository
    JobNotFound = Class.new(StandardError)

    def initialize(url)
      @url = url
    end

    def refresh(job)
      Job.new(
        server.get("/jobs/#{job.to_param}")
      )
    rescue MultiJson::DecodeError => e
      raise JobNotFound
    end

    def create(job)
      response = server.put("/jobs/#{job.to_param}", body: job.to_json)
      raise JobNotFound if response.code == 404
      response.code == 200
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
