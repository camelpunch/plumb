require 'minitest/autorun'
require 'tempfile'
require 'tmpdir'
require_relative '../../../lib/plumb/build'
require_relative '../../../lib/plumb/job'

module Plumb
  describe Build do
    let(:unused_repo) { Class.new { def fetch(*); end }.new }
    let(:spy_reporter) { Spy.new }
    let(:stub_dir) { Struct.new(:path).new('/') }

    it "requests a copy of the code from the repo" do
      repo = Spy.new
      url = '/some/repo.git'
      build = Build.new(Job.new(repository_url: url), repo, spy_reporter)

      build.run
      repo.calls.must_equal [[:fetch, url, build]]
    end

    describe "when the code is ready" do
      it "passes the started job to the reporter" do
        job = Job.new(name: 'foobar', script: 'true')

        build = Build.new(job, unused_repo, spy_reporter)

        build.process_working_copy(stub_dir)
        spy_reporter.calls.first.must_equal [:build_started, job]
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

          build = Build.new(job, unused_repo, spy_reporter)
          build.process_working_copy(working_copy)

          side_effect_file.read.strip.must_equal "script output"
        end
      end

      it "passes a successful job to the reporter" do
        job = Job.new(name: 'foobar', script: 'true')

        build = Build.new(job, unused_repo, spy_reporter)

        build.process_working_copy(stub_dir)
        spy_reporter.calls.last.must_equal [:build_succeeded, job]
      end

      it "passes an unsuccessful job to the reporter" do
        job = Job.new(script: 'false')

        build = Build.new(job, unused_repo, spy_reporter)
        build.process_working_copy(stub_dir)
        spy_reporter.calls.last.must_equal [:build_failed, job]
      end
    end

    describe "when clone fails" do
      let(:job) { Job.new(name: 'qux', script: 'whatever') }

      it "passes the job to the reporter" do
        build = Build.new(job, unused_repo, spy_reporter)

        build.handle_clone_failure
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
