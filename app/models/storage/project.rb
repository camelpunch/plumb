require 'sequel'
require 'json'
require_relative '../../../db/schema'

module Plumb
  module Storage
    class Project < Sequel::Model
      unrestrict_primary_key
      one_to_many :builds

      plugin :association_dependencies, builds: :delete

      alias_method :to_param, :id
    end

    class Build < Sequel::Model
      unrestrict_primary_key
      many_to_one :project
    end
  end
end

