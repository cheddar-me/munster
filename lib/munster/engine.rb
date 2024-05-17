require_relative "controllers/receive_webhooks_controller"
require_relative "jobs/processing_job"
require_relative "models/received_webhook"
require_relative "base_handler"

module Munster
  class Engine < ::Rails::Engine
    autoload :ReceiveWebhooksController, "munster/controllers/receive_webhooks_controller"
    autoload :ProcessingJob, "munster/jobs/processing_job"
    autoload :ReceivedWebhook, "munster/models/received_webhook"
    autoload :BaseHandler, "munster/base_handler"

    isolate_namespace Munster

    generators do
      require_relative "install_generator"
    end
  end
end
