
class PrivateHandler < WebhookTestHandler
  def valid?(request) = false
  def expose_errors_to_sender? = false
end
