# frozen_string_literal: true

require_relative "../../app/webhooks/webhook_test_handler"
require_relative "../../app/webhooks/inactive_handler"
require_relative "../../app/webhooks/invalid_handler"
require_relative "../../app/webhooks/private_handler"
require_relative "../../app/webhooks/extract_id_handler"

Munster.configure do |config|
  config.active_handlers = {
    test: WebhookTestHandler,
    inactive: InactiveHandler,
    invalid: InvalidHandler,
    private: PrivateHandler,
    extract_id: ExtractIdHandler
  }
end
