require 'minitest/autorun'
require 'tmpdir'
require 'pathname'
require_relative '../../../lib/plumb/filesystem_job_storage'

module Plumb
  describe FileSystemJobStorage do
    it "stores and retrieves jobs, across instances" do
      with_nonexistent_file_path do |path|
        storage1 = FileSystemJobStorage.new('test', path)
        storage2 = FileSystemJobStorage.new('test', path)

        job = Job.new(name: 'bar')
        storage1 << job
        storage1.find {|job| job.name == 'bar'}.must_equal job
        storage1.to_a.must_equal [job]

        storage2.find {|job| job.name == 'bar'}.must_equal job
        storage2.to_a.must_equal [job]
      end
    end

    it "clears all jobs, across instances" do
      with_nonexistent_file_path do |path|
        storage1 = FileSystemJobStorage.new('test', path)
        storage2 = FileSystemJobStorage.new('test', path)
        storage1.clear
        storage1 << job = Job.new(foo: 'bar')

        storage2.to_a.wont_be :empty?
        storage1.clear
        storage1.to_a.must_be :empty?
        storage2.to_a.must_be :empty?
      end
    end

    it "can be mapped" do
      with_nonexistent_file_path do |path|
        storage = FileSystemJobStorage.new('test', path)
        storage << Job.new(name: 'foo')
        storage << Job.new(name: 'bar')

        storage.map {|job| job.name}.must_equal %w(foo bar)
      end
    end

    it "updates existing jobs" do
      with_nonexistent_file_path do |path|
        storage = FileSystemJobStorage.new('test', path)
        storage << Job.new(name: 'foo')
        storage << Job.new(name: 'foo', bob: 'fred')

        storage.find {|job| job.name == 'foo'}.bob.must_equal('fred')
        storage.count.must_equal 1
      end
    end

    def with_nonexistent_file_path
      Dir.mktmpdir do |dir|
        yield Pathname(dir).join('db.json')
      end
    end
  end
end
