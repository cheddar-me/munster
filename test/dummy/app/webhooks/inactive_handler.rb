# frozen_string_literal: true

# This handler accepts webhooks from our integration tests. This webhook gets dispatched
# if a banking provider test fails, indicating that the bank might be having an incident

class InactiveHandler < WebhookTestHandler
  def self.active? = false

  def self.service_id = :inactive
end
