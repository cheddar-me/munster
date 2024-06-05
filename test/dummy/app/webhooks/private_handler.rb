
class PrivateHandler < WebhookTestHandler
  def self.valid?(request) = false

  def self.service_id = :private
  def self.expose_errors_to_sender? = false
end
