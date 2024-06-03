# frozen_string_literal: true

require_relative "../../app/webhooks/test_handler"
require_relative "../../app/webhooks/customer_io_handler"

Munster.configure do |config|
  config.active_handlers = [WebhookTestHandler, CustomerIoHandler]
end
