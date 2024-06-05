# frozen_string_literal: true

# This handler accepts webhooks from our integration tests. This webhook gets dispatched
# if a banking provider test fails, indicating that the bank might be having an incident

class InvalidHandler < WebhookTestHandler
  def self.valid?(request) = false

  def self.service_id = :invalid
end
