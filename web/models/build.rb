require 'sequel'
require_relative 'job'

module Plumb
  module Storage
    begin
      DB.create_table :builds do
        primary_key :id
        foreign_key :job_id, :jobs
        String :status
      end
    rescue StandardError => e
      $stderr.puts e.message
    end

    class Build < Sequel::Model
      many_to_one :job
    end
  end
end

