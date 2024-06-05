# frozen_string_literal: true

class InactiveHandler < WebhookTestHandler
  def self.active? = false
end
