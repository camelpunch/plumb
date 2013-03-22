module Plumb
  class FileSystemStorage
    include Enumerable

    def initialize(klass, storage_path)
      @klass = klass
      @storage_path = storage_path
    end

    def <<(new_item)
      new_items = updated_collection_for_item(new_item)
      File.open(@storage_path, 'w') do |file|
        file << new_items.to_json
      end
    end

    def update(name, &block)
      self << block.call(find {|item| item.name == name})
    end

    def clear
      File.unlink @storage_path
    rescue Errno::ENOENT
    end

    def each(&block)
      JSON.parse(data).each {|attributes| block.call klass.new(attributes)}
    end

    private

    attr_reader :klass

    def updated_collection_for_item(new_item)
      reject {|item| item == new_item} + [new_item]
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

