require_relative '../../spec_helper'
require_relative '../../../lib/plumb/web_reporter'
require_relative '../../../lib/plumb/job'

module Plumb
  describe WebReporter do
    let(:host) { "http://some.place:8000" }
    let(:job) { Job.new(name: 'a-job') }
    let(:reporter) { WebReporter.new(host) }
    let(:any_path) { %r{^#{host}/.*} }

    before do
      @object = reporter
      WebMock.disable_net_connect!
    end

    after do
      WebMock.allow_net_connect!
    end

    it "sends a building status to the endpoint" do
      stub_request(:put, any_path)
      reporter.build_started(job)

      assert_requested(:put, 'http://some.place:8000/jobs/a-job',
                       body: job.to_json)
      assert_requested(:put,
                       %r{http://some.place:8000/jobs/a-job/builds/[-\h]+},
                       body: BuildStatus.new(status: 'building').to_json)
    end

    it "sends successful build statuses to the endpoint" do
      stub_request(:post, any_path)
      reporter.build_succeeded(job)

      assert_requested(:post, 'http://some.place:8000/jobs/a-job/builds',
                       body: BuildStatus.new(status: 'success').to_json)
    end

    it "sends failed build statuses to the endpoint" do
      stub_request(:post, any_path)
      reporter.build_failed(job)

      assert_requested(:post, 'http://some.place:8000/jobs/a-job/builds',
                       body: BuildStatus.new(status: 'failure').to_json)
    end
  end
end

