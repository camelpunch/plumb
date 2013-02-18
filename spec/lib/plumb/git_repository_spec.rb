require_relative '../../spec_helper'
require 'tmpdir'
require_relative '../../../lib/plumb/git_repository'
require_relative '../../support/git_repository'

module Plumb
  describe GitRepository do
    let(:fixture_repo) { SpecSupport::GitRepository.new }
    let(:spy) { ListenerSpy.new }

    after do
      fixture_repo.destroy
    end

    it "clones the repo and passes the working dir to its listener" do
      fixture_repo.create
      fixture_repo.create_good_commit

      Dir.mktmpdir do |projects_dir|
        repo = GitRepository.new(projects_dir)
        repo.fetch(fixture_repo.url, spy)
        spy.filenames.must_equal fixture_repo.filenames
      end
    end

    describe "when the repo can't be cloned" do
      it "tells the listener" do
        Dir.mktmpdir do |dir|
          listener = MiniTest::Mock.new
          repo = GitRepository.new(dir)

          listener.expect(
            :handle_clone_failure,
            nil,
            []
          )
          repo.fetch('/bad/url', listener)
          listener.verify
        end
      end

      it "does not create a new directory" do
        Dir.mktmpdir do |dir|
          original_listing = Dir.glob(dir + '/*')
          repo = GitRepository.new(dir)
          repo.fetch('/bad/url')
          Dir.glob(dir + '/*').must_equal original_listing
        end
      end
    end

    describe "when the destination already exists" do
      it "removes the directory and starts from scratch" do
        fixture_repo.create
        fixture_repo.create_good_commit

        Dir.mktmpdir do |projects_dir|
          project_dir = "#{projects_dir}/#{fixture_repo.project_name}"
          Dir.mkdir(project_dir)
          FileUtils.touch project_dir + '/foo'

          repo = GitRepository.new(projects_dir)
          repo.fetch(fixture_repo.url, spy)
          spy.filenames.wont_include 'foo'
        end
      end
    end
  end

  class ListenerSpy
    attr_reader :received_working_copy

    def process_working_copy(working_copy)
      @received_working_copy = working_copy
    end

    def filenames
      Dir.glob(@received_working_copy.path.join('*')).
        map &File.method(:basename)
    end
  end
end
