
class PrivateHandler < WebhookTestHandler
  def self.valid?(request) = false
  def self.expose_errors_to_sender? = false
end
