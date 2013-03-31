require 'sequel'
require 'json'
require_relative '../../db/schema'
require_relative 'build'

module Plumb
  class Project < Sequel::Model
    one_to_many :builds

    def last_build_status
      return nil if builds.empty?
      builds_dataset.order(:started_at).last.status
    end

    def activity
      last_build_status == 'Building' ? 'Building' : 'Sleeping'
    end

    alias_method :to_param, :id

    def to_json
      JSON.generate to_hash
    end
  end
end
