Munster.configure do |config|
  # Active Handlers are defined as hash with key as a service_id and handler class  that would handle webhook request.
  # A Handler must respond to `.new` and return an object roughly matching `Munster::BaseHandler` in terms of interface.
  # Use module names (strings) here to allow the handler modules to be lazy-loaded by Rails.
  #
  # Example:
  #   {:test => "TestHandler", :inactive => "InactiveHandler"}
  config.active_handlers = {}

  # It's possible to overwrite default processing job to enahance it. As example if you want to add custom
  # locking or retry mechanism. You want to inherit that job from Munster::ProcessingJob because the background
  # job also manages the webhook state.
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
  # In the config a string with your job' class name can be used so that the job can be lazy-loaded by Rails:
  #
  # config.processing_job_class = "WebhookProcessingJob"

  # We're using a common interface for error reporting provided by Rails, e.g Rails.error.report. In some cases
  # you want to enhance those errors with additional context. As example to provide a namespace:
  #
  # { appsignal: { namespace: "webhooks" } }
  #
  # config.error_context = { appsignal: { namespace: "webhooks" } }

  # Incoming webhooks will be written into your DB without any prior validation. By default, Munster limits the
  # request body size for webhooks to 512 KiB, so that it would not be too easy for an attacker to fill your
  # database with junk. However, if you are receiving very large webhook payloads you might need to increase
  # that limit (or make it even smaller for extra security)
  #
  # config.request_body_size_limit = 2.megabytes
end
