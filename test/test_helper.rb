# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

def post_json(path, obj)
  post path, params: obj.to_json, headers: {"CONTENT_TYPE" => "application/json"}
end

class ActiveSupport::TestCase
  fixtures :all
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
