# frozen_string_literal: true

require_relative "../munster"
require_relative "controllers/receive_webhooks_controller"
require_relative "jobs/processing_job"
require_relative "models/received_webhook"
require_relative "base_handler"


module Munster
  class Engine < ::Rails::Engine
    isolate_namespace Munster

    autoload :Munster, "munster"
    autoload :ReceiveWebhooksController, "munster/controllers/receive_webhooks_controller"
    autoload :ProcessingJob, "munster/jobs/processing_job"
    autoload :BaseHandler, "munster/base_handler"

    config.after_initialize do
      Munster.configure
    end

    generators do
      require_relative "install_generator"
    end
  end
end
