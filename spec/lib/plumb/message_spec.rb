require_relative '../../spec_helper'
require 'json'
require_relative '../../../lib/plumb/message'

module Plumb
  describe Message do
    it "allows access to individual properties" do
      Message.new(JSON.generate(name: 'foo'))['name'].must_equal 'foo'
    end

    it "returns its attributes" do
      attributes = {
        'name' => 'apple',
        'color' => 'green',
        'variety' => 'granny smith'
      }
      Message.new(JSON.generate(attributes)).
        attributes.must_equal(attributes)
    end

    it "takes a single, unused argument to JSON, for compatibility" do
      Message.new('{"foo":"bar"}').to_json('baz').must_equal('{"foo":"bar"}')
    end
  end
end
