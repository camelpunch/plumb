require_relative '../../spec_helper'
require_relative '../../../lib/plumb/working_copy'

module Plumb
  describe WorkingCopy do
    it "is equivalent to something with same path" do
      WorkingCopy.new('/blah').must_equal WorkingCopy.new('/blah')
    end

    it "is different to something with different path" do
      WorkingCopy.new('/blah').wont_equal WorkingCopy.new('foo')
    end

    it "allows joining of its path" do
      WorkingCopy.new('/blah').path.join('foo', 'bar').to_s.
        must_equal('/blah/foo/bar')
    end
  end
end
