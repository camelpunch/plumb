require 'json'
require 'ostruct'

module Plumb
  class BuildStatus < OpenStruct
    class << self
      def parse(json)
        new JSON.parse(json)
      end
    end

    def success?
      status.to_sym == :success
    end

    def failure?
      status.to_sym == :failure
    end

    def status
      super || :sleeping
    end

    def to_json(*)
      JSON.generate(@table)
    end

    def to_h
      @table
    end

    def to_s
      status.to_s
    end
  end
end

