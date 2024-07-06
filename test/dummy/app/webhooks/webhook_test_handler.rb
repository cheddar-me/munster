# frozen_string_literal: true

# This handler accepts webhooks from our integration tests. This webhook gets dispatched
# if a banking provider test fails, indicating that the bank might be having an incident

class WebhookTestHandler < Munster::BaseHandler
  def self.valid?(request) = true

  def self.process(webhook)
    return unless webhook.received?
    webhook.update!(status: "processing")
    webhook.update!(status: "processed")
  rescue
    webhook.update!(status: "error")
  end

  def self.expose_errors_to_sender? = true
end
