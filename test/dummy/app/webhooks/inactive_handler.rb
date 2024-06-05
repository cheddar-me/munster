# frozen_string_literal: true

class InactiveHandler < WebhookTestHandler
  def active? = false
end
