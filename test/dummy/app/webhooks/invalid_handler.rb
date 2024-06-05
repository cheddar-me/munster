# frozen_string_literal: true

class InvalidHandler < WebhookTestHandler
  def self.valid?(request) = false

  def self.service_id = :invalid
end
