require_relative '../../spec_helper'
require_relative '../../../lib/plumb/web_reporter'
require_relative '../../../lib/plumb/job'

require 'webmock/minitest'
WebMock.allow_net_connect!

module Plumb
  describe WebReporter do
    before do WebMock.disable_net_connect! end
    after do WebMock.allow_net_connect! end

    let(:host) { "http://some.place:8000" }
    let(:mock_handler) {
      handler = MiniTest::Mock.new
      def handler.handle_200(*); end
      handler
    }
    let(:job) { Job.new(name: 'a-job') }
    let(:reporter) { WebReporter.new(host) }

    it "sends a building status to the endpoint, ensuring job exists" do
      stub_request(:put, %r{^#{host}/.*})
      stub_request(:post, %r{^#{host}/.*})
      reporter.build_started(job)

      assert_requested(:put, 'http://some.place:8000/jobs/a-job',
                       body: job.to_json)
      assert_requested(:post, 'http://some.place:8000/jobs/a-job/builds',
                       body: BuildStatus.new(status: 'building').to_json)
    end

    it "sends successful build statuses to the endpoint" do
      stub_request(:post, %r{^#{host}/.*})
      reporter.build_succeeded(job)

      assert_requested(:post, 'http://some.place:8000/jobs/a-job/builds',
                       body: BuildStatus.new(status: 'success').to_json)
    end

    it "sends failed build statuses to the endpoint" do
      stub_request(:post, %r{^#{host}/.*})
      reporter.build_failed(job)

      assert_requested(:post, 'http://some.place:8000/jobs/a-job/builds',
                       body: BuildStatus.new(status: 'failure').to_json)
    end
  end
end

