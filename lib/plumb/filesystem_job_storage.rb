require_relative 'job'

module Plumb
  class FileSystemJobStorage
    include Enumerable

    def initialize(storage_path)
      @storage_path = storage_path
    end

    def <<(new_job)
      new_jobs = updated_collection_for_job(new_job)
      File.open(@storage_path, 'w') do |file|
        file << new_jobs.to_json
      end
    end

    def update(name, &block)
      self << block.call(find {|job| job.name == name})
    end

    def clear
      File.unlink @storage_path
    rescue Errno::ENOENT
    end

    def each(&block)
      JSON.parse(data).each {|attributes| block.call Plumb::Job.new(attributes)}
    end

    private

    def updated_collection_for_job(new_job)
      reject {|job| job == new_job} + [new_job]
    end

    def data
      unless File.exists?(@storage_path)
        File.open(@storage_path, 'w') do |file|
          file << '[]'
        end
      end
      File.read(@storage_path)
    end
  end
end

