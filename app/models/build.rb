require 'sequel'
require_relative '../../db/schema'
require_relative 'build'

module Plumb
  class Build < Sequel::Model
    unrestrict_primary_key
    many_to_one :project
  end
end

