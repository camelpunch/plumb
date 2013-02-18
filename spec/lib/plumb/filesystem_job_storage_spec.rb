require 'minitest/autorun'
require 'tmpdir'
require 'pathname'
require_relative '../../../lib/plumb/filesystem_job_storage'

module Plumb
  describe FileSystemJobStorage do
    it "stores and retrieves jobs, across instances" do
      with_nonexistent_file_path do |path|
        storage1 = FileSystemJobStorage.new(path)
        storage2 = FileSystemJobStorage.new(path)

        job = Job.new(id: 'bar')
        storage1 << job
        storage1.find {|job| job.id == 'bar'}.must_equal job
        storage1.to_a.must_equal [job]

        storage2.find {|job| job.id == 'bar'}.must_equal job
        storage2.to_a.must_equal [job]
      end
    end

    it "clears all jobs, across instances" do
      with_nonexistent_file_path do |path|
        storage1 = FileSystemJobStorage.new(path)
        storage2 = FileSystemJobStorage.new(path)
        storage1.clear
        storage1 << job = Job.new(foo: 'bar')

        storage2.to_a.wont_be :empty?
        storage1.clear
        storage1.to_a.must_be :empty?
        storage2.to_a.must_be :empty?
      end
    end

    it "can be mapped when jobs are present" do
      with_nonexistent_file_path do |path|
        storage = FileSystemJobStorage.new(path)
        storage << Job.new(name: 'foo')
        storage << Job.new(name: 'bar')

        storage.map(&:name).must_equal %w(foo bar)
      end
    end

    it "can be mapped when jobs aren't present" do
      with_nonexistent_file_path do |path|
        storage = FileSystemJobStorage.new(path)
        storage.map(&:name).must_be_empty
        storage.clear
        storage.map(&:name).must_be_empty
      end
    end

    it "updates existing jobs with the shovel" do
      with_nonexistent_file_path do |path|
        storage = FileSystemJobStorage.new(path)
        storage << Job.new(name: 'foo', script: 'rake')
        storage << Job.new(name: 'foo', script: 'rspec')

        storage.find {|job| job.name == 'foo'}.script.must_equal('rspec')
        storage.count.must_equal 1
      end
    end

    it "can update a job by name using a block that returns a new job" do
      with_nonexistent_file_path do |path|
        storage = FileSystemJobStorage.new(path)
        storage << Job.new(name: 'foo', script: 'rake')

        storage.update('foo') do |job|
          Job.new(name: 'foo', script: 'fake')
        end

        storage.find {|job| job.name == 'foo'}.script.must_equal('fake')
      end
    end

    def with_nonexistent_file_path
      Dir.mktmpdir do |dir|
        yield Pathname(dir).join('db.json')
      end
    end
  end
end
