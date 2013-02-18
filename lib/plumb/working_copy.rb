require 'pathname'
module Plumb
  class WorkingCopy < Struct.new(:path)
    def path
      Pathname(super)
    end
  end
end
