# frozen_string_literal: true

require_relative "../../app/webhooks/webhook_test_handler"
require_relative "../../app/webhooks/inactive_handler"
require_relative "../../app/webhooks/invalid_handler"

Munster.configure do |config|
  config.active_handlers = [WebhookTestHandler, InactiveHandler, InvalidHandler]
end
