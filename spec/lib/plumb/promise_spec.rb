require_relative '../../spec_helper'
require_relative '../../../lib/plumb/promise'

module Plumb
  describe Promise do
    it "can be fulfilled" do
      state = 'a'
      promise = Promise.new(->{ state = 'b' }, ->{ state = 'c' })
      state.must_equal 'a'
      promise.fulfil
      state.must_equal 'b'
    end

    it "can be broken" do
      state = 'a'
      promise = Promise.new(->{ state = 'b' }, ->{ state = 'c' })
      state.must_equal 'a'
      promise.break
      state.must_equal 'c'
    end
  end
end
