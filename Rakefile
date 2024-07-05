# frozen_string_literal: true

require "bundler/setup"
require "rake/testtask"
require "bundler/gem_tasks"
require "standard/rake"

task :format do
  `bundle exec standardrb --fix`
  `bundle exec magic_frozen_string_literal .`
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"

  file_name = ARGV[1]

  t.test_files = if file_name
    [file_name]
  else
    FileList["test/**/*_test.rb"]
  end
end

task default: [:test, :standard]
