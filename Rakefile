require 'rake/testtask'

integration_pattern = 'spec/integration/*_spec.rb'
acceptance_pattern = 'spec/end-end/*_spec.rb'

ENV['PLUMB_AWS_CONFIG'] = "#{ENV['HOME']}/plumb_aws.yml"

Rake::TestTask.new(:units) do |task|
  task.test_files = FileList.new('spec/**/*_spec.rb').
    exclude(integration_pattern, acceptance_pattern)
end

Rake::TestTask.new(:integration) do |task|
  task.pattern = integration_pattern
end

Rake::TestTask.new(:acceptance) do |task|
  ENV['N'] = '3' # number of tests to run in parallel
  task.pattern = acceptance_pattern
end

task default: [:units, :acceptance]

desc "Run all tests"
task all: [:units, :integration, :acceptance]
