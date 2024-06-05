# frozen_string_literal: true

# This handler accepts webhooks from our integration tests. This webhook gets dispatched
# if a banking provider test fails, indicating that the bank might be having an incident

class WebhookTestHandler < Munster::BaseHandler
  def valid?(request) = true

  def process(webhook)
    return unless webhook.received?
    webhook.update!(status: "processing")
    webhook.update!(status: "processed")
  rescue
    webhook.update!(status: "error")
    raise
  end

  def expose_errors_to_sender? = true
end
