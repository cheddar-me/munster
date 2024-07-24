# This handler accepts webhooks from our integration tests. This webhook gets dispatched
# if a banking provider test fails, indicating that the bank might be having an incident

class WebhookTestHandler < Munster::BaseHandler
  def valid?(request)
    request.params.fetch(:isValid, false)
  end

  def process(webhook)
    filename = webhook.request.params.fetch(:outputToFilename)
    File.binwrite(filename, webhook.body)
  end

  def expose_errors_to_sender? = true
end
