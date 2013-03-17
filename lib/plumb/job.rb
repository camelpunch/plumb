require 'json'
require 'ostruct'

module Plumb
  class Job < OpenStruct
    class << self
      def parse(json)
        new JSON.parse(json)
      end
    end

    def ==(other)
      name == other.name
    end

    def to_h
      @table
    end

    def to_json(*)
      JSON.generate(@table)
    end

    def to_param
      name
    end

    def with_build_status(build_status)
      Job.new(@table.merge(
        if build_status.success?
          {activity: 'sleeping', last_build_status: 'success'}
        elsif build_status.failure?
          {activity: 'sleeping', last_build_status: 'failure'}
        else
          {activity: build_status.status}
        end
      ))
    end

    def ready?
      ready
    end

    def activity
      super || "sleeping"
    end
  end
end

