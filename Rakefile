# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "standard/rake"

Minitest::TestTask.create

task :format do
  `bundle exec standardrb --fix`
  `bundle exec magic_frozen_string_literal .`
end

task default: %i[test standard]
