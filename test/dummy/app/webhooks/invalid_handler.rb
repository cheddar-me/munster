# frozen_string_literal: true

class InvalidHandler < WebhookTestHandler
  def self.valid?(request) = false
end
