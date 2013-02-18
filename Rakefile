require 'rake/testtask'

integration_pattern = 'spec/integration/*_spec.rb'
acceptance_pattern = 'spec/end-end/*_spec.rb'

Rake::TestTask.new(:units) do |task|
  task.test_files = FileList.new('spec/**/*_spec.rb').
    exclude(integration_pattern, acceptance_pattern)
end

Rake::TestTask.new(:integration) do |task|
  task.test_files = FileList.new(integration_pattern)
end

Rake::TestTask.new(:acceptance) do |task|
  task.test_files = FileList.new(acceptance_pattern)
end

task default: :units

desc "Run all tests"
task all: [:units, :integration, :acceptance]
