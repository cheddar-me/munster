# frozen_string_literal: true

class InactiveHandler < WebhookTestHandler
  def self.active? = false

  def self.service_id = :inactive
end
