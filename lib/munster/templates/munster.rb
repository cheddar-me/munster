Munster.configure do |config|
  # Active Handlers are defined as hash with key as a service_id and handler class  that would handle webhook request.
  # Example:
  #   {:test => TestHandler, :inactive => InactiveHandler}
  config.active_handlers = {}

  # It's possible to overwrite default processing job to enahance it. As example if you want to add proper locking or retry mechanism.
  #
  # Example:
  #
  # class WebhookProcessingJob < Munster::ProcessingJob
  #   def perform(webhook)
  #     TokenLock.with(name: "webhook-processing-#{webhook.id}") do
  #       super(webhook)
  #     end
  #   end
  #
  # This is how you can change processing job:
  #
  # config.processing_job_class = WebhookProcessingJob

  # We're using a common interface for error report provided by Rails, e.g Rails.error.report. In some cases
  # you want to enhance those errors with additional context. As example to provide a namespace:
  #
  # { appsignal: { namespace: "webhooks" } }
  #
  # config.error_context = { appsignal: { namespace: "webhooks" } }
end
