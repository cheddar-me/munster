# frozen_string_literal: true

require_relative "../../app/webhooks/test_handler"

Munster.active_handlers = [WebhookTestHandler]
