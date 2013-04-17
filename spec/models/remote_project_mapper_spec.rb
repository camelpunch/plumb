require_relative '../spec_helper'
require_relative '../test_db'
require_relative '../../app/models/remote_project_mapper'
require_relative '../../app/models/config'
require_relative '../support/shared_examples/project_mapper'

module Plumb
  class TestRemoteProjectMapper < MiniTest::Unit::TestCase
    include ProjectMapperSharedTests

    def mapper
      config = Config.new(
        'server' => {
          'endpoint' => 'http://some.endpoint',
          'adapter' => ['rack', 'Plumb::Server'],
      })
      @mapper ||= RemoteProjectMapper.new(config)
    end
  end
end

