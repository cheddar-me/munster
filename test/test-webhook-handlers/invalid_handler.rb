# frozen_string_literal: true

class InvalidHandler < WebhookTestHandler
  def valid?(request) = false
end
