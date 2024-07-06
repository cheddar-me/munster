require "test_helper"

class TestHandlerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "can process" do
    received_webhook = received_webhooks(:received_provider_disruption)

    WebhookTestHandler.new.process(received_webhook)

    assert_equal("processed", received_webhook.reload.status)
  end
end
