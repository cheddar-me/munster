# ENV["RAILS_ENV"] = "test"
#
# require "rails/all"
#
# database = 'development.sqlite3'
# ENV['DATABASE_URL'] = "sqlite3:#{database}"
# ENV['DATABASE_URL'] = "sqlite3:#{database}"
# ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: database)
# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Schema.define do
#   create_table :posts, force: true do |t|
#   end
#
#   create_table :comments, force: true do |t|
#     t.integer :post_id
#   end
# end

# require_relative "../test/dummy/config/environment"
# ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
# ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
# require "rails/test_help"

# Load fixtures from the engine
# if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
#   ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
#   ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
#   ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
#   ActiveSupport::TestCase.fixtures :all
# end

require_relative "test_app"
require "rails/test_help"

class ActiveSupport::TestCase
  # fixtures :all
  # Same as "assert_changes" in Rails but for countable entities.
  # @return [*] return value of the block
  # @example
  #   assert_changes_by("Notification.count", exactly: 2) do
  #     cause_two_notifications_to_get_delivered
  #   end
  def assert_changes_by(expression, message = nil, exactly: nil, at_least: nil, at_most: nil, &block)
    # rubocop:disable Security/Eval
    exp = expression.respond_to?(:call) ? expression : -> { eval(expression.to_s, block.binding) }
    # rubocop:enable Security/Eval

    raise "either exactly:, at_least: or at_most: must be specified" unless exactly || at_least || at_most
    raise "exactly: is mutually exclusive with other options" if exactly && (at_least || at_most)
    raise "at_most: must be larger than at_least:" if at_least && at_most && at_most < at_least

    before = exp.call
    retval = assert_nothing_raised(&block)

    after = exp.call
    delta = after - before

    if exactly
      at_most = exactly
      at_least = exactly
    end

    # We do not make these an if/else since we allow both at_most and at_least
    if at_most
      error = "#{expression.inspect} changed by #{delta} which is more than #{at_most}"
      error = "#{error}. It was #{before} and became #{after}"
      error = "#{message.call}.\n" if message&.respond_to?(:call)
      error = "#{message}.\n#{error}" if message && !message.respond_to?(:call)
      assert delta <= at_most, error
    end

    if at_least
      error = "#{expression.inspect} changed by #{delta} which is less than #{at_least}"
      error = "#{error}. It was #{before} and became #{after}"
      error = "#{message.call}.\n" if message&.respond_to?(:call)
      error = "#{message}.\n#{error}" if message && !message.respond_to?(:call)
      assert delta >= at_least, error
    end

    retval
  end
end
