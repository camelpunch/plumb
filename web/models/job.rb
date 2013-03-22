require 'sequel'

module Plumb
  module Storage
    begin
      DB.create_table :jobs do
        primary_key :id
        String :name
        String :activity
        String :repository_url
        Boolean :ready
      end
    rescue StandardError => e
      $stderr.puts e.message
    end

    class Job < Sequel::Model
      one_to_many :builds

      def after_initialize
        set activity: 'sleeping'
      end

      def build_started(status)
        add_build Build.new(status.to_h)
        update activity: status
      end

      def build_finished(status)
        builds.last.update(status.to_h)
        update activity: 'sleeping'
      end

      def last_build_status
        builds.last.status
      end

      def to_json
        JSON.generate(
          Hash[
            %w(name activity repository_url ready).
            map {|attribute| [attribute, public_send(attribute)]}
          ]
        )
      end
    end
  end
end
