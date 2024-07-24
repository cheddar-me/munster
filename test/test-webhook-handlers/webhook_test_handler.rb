class WebhookTestHandler < Munster::BaseHandler
  def valid?(request)
    request.params.fetch(:isValid, false)
  end

  def process(webhook)
    raise "Oops, failed" if webhook.request.params[:raiseDuringProcessing]
    filename = webhook.request.params.fetch(:outputToFilename)
    File.binwrite(filename, webhook.body)
  end

  def expose_errors_to_sender? = true
end
