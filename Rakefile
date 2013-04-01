require 'rake/testtask'

test_pattern = 'spec/**/*_spec.rb'

Rake::TestTask.new do |task|
  ENV['N'] = '3' # number of tests to run in parallel
  task.pattern = test_pattern
end

task default: :test
