require_relative '../../spec_helper'
require 'tempfile'
require 'tmpdir'
require_relative '../../../lib/plumb/builder'
require_relative '../../../lib/plumb/job'
require_relative '../../../lib/plumb/promise'

module Plumb
  describe Builder do
    let(:unused_code_repo) { Class.new { def fetch(*); end }.new }
    let(:stub_dir) { Struct.new(:path).new('/') }

    it "requests a copy of the code, passing self as listener" do
      code_repo = Spy.new
      unused_job_repo = nil
      job = Job.new(repository_url: '/some/repo.git')

      builder = Builder.new(job, code_repo, unused_job_repo)
      builder.run

      code_repo.calls.must_equal [[:fetch, job.repository_url, builder]]
    end

    describe "when the code is ready" do
      it "" do
        job = Job.new(name: 'foobar', script: 'true')

        reporter = Minitest::Mock.new
        builder = Builder.new(job, unused_code_repo, reporter)

        reporter.expect(:build_started, nil, [job, build])
        builder.process_working_copy(stub_dir)
        reporter.verify
      end

      class WebReporterDouble
      end

      it "runs the job's script from the working copy" do
        job = Job.new(script: './make_stuff_happen')
        side_effect_file = Tempfile.new('side_effect_receiver')
        script = "echo 'script output' > #{side_effect_file.path}"

        with_real_working_copy do |working_copy|
          File.open(working_copy.path + "/make_stuff_happen", 'w') do |file|
            file << script
            file.chmod(500)
          end

          stub_reporter = WebReporterDouble.new
          builder = Builder.new(job, unused_code_repo, stub_reporter)
          builder.process_working_copy(working_copy)

          side_effect_file.read.strip.must_equal "script output"
        end
      end

      it "passes a successful job to the reporter" do
        job = Job.new(name: 'foobar', script: 'true')

        spy_reporter = Spy.new
        builder = Builder.new(job, unused_code_repo, spy_reporter)

        builder.process_working_copy(stub_dir)
        spy_reporter.calls.last.must_equal [:build_succeeded, job]
      end

      it "passes an unsuccessful job to the reporter" do
        job = Job.new(script: 'false')

        spy_reporter = Spy.new
        builder = Builder.new(job, unused_code_repo, spy_reporter)
        builder.process_working_copy(stub_dir)
        spy_reporter.calls.last.must_equal [:build_failed, job]
      end
    end

    describe "when clone fails" do
      let(:job) { Job.new(name: 'qux', script: 'whatever') }

      it "passes the job to the reporter" do
        builder = Builder.new(job, unused_code_repo, spy_reporter)

        builder.handle_clone_failure
        spy_reporter.calls.must_equal [[:build_failed, job]]
      end
    end

    describe "when the code is not available" do
      it "sends a failed build to the reporter"
    end

    class Spy
      def calls
        @calls ||= []
      end
      def method_missing(name, *args)
        calls << [name, *args]
      end
    end

    def with_real_working_copy(&block)
      Dir.mktmpdir do |working_copy_path|
        block.call(Dir.new(working_copy_path))
      end
    end
  end
end
