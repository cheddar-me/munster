# frozen_string_literal: true

require_relative "controllers/receive_webhooks_controller"
require_relative "jobs/processing_job"
require_relative "models/received_webhook"
require_relative "base_handler"

module Munster
  class Engine < ::Rails::Engine
    isolate_namespace Munster

    autoload :ReceiveWebhooksController, "munster/controllers/receive_webhooks_controller"
    autoload :ProcessingJob, "munster/jobs/processing_job"
    autoload :BaseHandler, "munster/base_handler"

    generators do
      require_relative "install_generator"
    end

    routes do
      post "/:service_id" => "received_webhooks#create"
    end
  end
end
