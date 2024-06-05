require "test_helper"

class TestHandlerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "can process" do
    record = received_webhooks(:received_provider_disruption)

    WebhookTestHandler.process(record)

    assert_equal("processed", record.reload.status)
  end
end
