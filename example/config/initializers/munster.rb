# frozen_string_literal: true

require_relative "../../app/webhooks/test_handler"

Munster.configure do |config|
  config.active_handlers = [WebhookTestHandler]
  config.receive_webhooks_table_name = :munster_received_webhooks
end
