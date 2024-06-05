# frozen_string_literal: true

require_relative "../../app/webhooks/webhook_test_handler"

Munster.configure do |config|
  config.active_handlers = [WebhookTestHandler]
end
