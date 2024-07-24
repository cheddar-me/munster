# frozen_string_literal: true

# This handler accepts webhooks from our integration tests. This webhook gets dispatched
# if a banking provider test fails, indicating that the bank might be having an incident
class WebhookTestHandler < Munster::BaseHandler
  def valid?(request) = true

  def process(webhook)
    Rails.logger.info { webhook.request.params.fetch(:payment_id) }
  end

  def expose_errors_to_sender? = true
end
