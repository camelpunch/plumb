require 'securerandom'

module SpecSupport
  class QueueSpec < MiniTest::Spec
    @@test_suites.delete QueueSpec

    THREADS = []

    before do
      @queues = []
    end

    after do
      THREADS << Thread.new do
        @queues.each(&:destroy)
      end
    end

    MiniTest::Unit.after_tests do
      THREADS.each(&:join)
    end

    def generate_name
      "test-#{SecureRandom.uuid}"
    end

    def item(json_string)
      Object.new.tap do |obj|
        obj.define_singleton_method(:to_json) {|*| json_string }
        obj.define_singleton_method(:to_s) { json_string }
      end
    end

    it "reports its name" do
      name = generate_name
      queue = queue_named(name)
      queue.name.must_equal name
    end

    it "pops nil when everything has been popped" do
      @queues << queue = queue_named(generate_name)
      queue << item('[]')
      queue.pop
      queue.pop.must_be_nil
    end

    it "can add and pop items in a single instance" do
      @queues << queue = queue_named(generate_name)
      obj = item('{"foo":"bar"}')
      queue << obj
      queue.pop.must_equal obj.to_json
    end

    it "can add and pop items across instances with same name" do
      shared_name = generate_name
      @queues << queue1 = queue_named(shared_name)
      @queues << queue2 = queue_named(shared_name)
      obj = item('{"baz":"qux"}')
      queue1 << obj
      queue2.pop.must_equal obj.to_json
    end

    it "doesn't share queue items across instances with different names" do
      @queues << queue1 = queue_named(generate_name)
      @queues << queue2 = queue_named(generate_name)
      obj = item('{"baz":"qux"}')
      queue1 << obj
      queue2.pop.must_be_nil
    end

    it "can enqueue the direct output of another queue" do
      @queues << queue1 = queue_named(generate_name)
      @queues << queue2 = queue_named(generate_name)
      obj = item('{"baz":"qux"}')
      queue1 << obj
      queue2 << queue1.pop
      queue2.pop.must_equal '{"baz":"qux"}'
    end

    it "returns multiple queued items" do
      @queues << queue = queue_named(generate_name)
      item1 = item('{"baz":"qux"}')
      item2 = item('{"bar":"foo"}')
      queue << item1
      queue << item2

      expected_items = [item1, item2]

      tries = 0
      until expected_items.empty? || (tries += 1) == 5 do
        message = queue.pop
        expected_items.delete_if {|item| item.to_json == message.to_json}
      end

      expected_items.must_be_empty
    end

    it "allows access to message properties" do
      @queues << queue = queue_named(generate_name)
      queue << item('{"baz":"qux"}')
      queue.pop['baz'].must_equal 'qux'
    end
  end
end
