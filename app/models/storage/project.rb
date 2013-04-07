require 'sequel'
require 'json'
require_relative '../../../db/schema'

module Plumb
  module Storage
    class Project < Sequel::Model
      unrestrict_primary_key
      one_to_many :builds

      plugin :association_dependencies, builds: :delete

      def last_build_status
        return 'Unknown' if builds.empty?
        last_build.status
      end

      def last_build_id
        return nil if builds.empty?
        last_build.id
      end

      def activity
        last_build_status == 'Building' ? 'Building' : 'Sleeping'
      end

      alias_method :to_param, :id

      def to_json
        JSON.generate to_hash
      end

      private

      def last_build
        builds_dataset.order(:started_at).last
      end
    end

    class Build < Sequel::Model
      unrestrict_primary_key
      many_to_one :project
    end
  end
end

