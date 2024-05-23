# frozen_string_literal: true

require_relative "../munster"
require_relative "jobs/processing_job"
require_relative "models/received_webhook"
require_relative "base_handler"
require_relative "web"

module Munster
  class Engine < ::Rails::Engine
    isolate_namespace Munster

    autoload :Munster, "munster"
    autoload :ProcessingJob, "munster/jobs/processing_job"
    autoload :BaseHandler, "munster/base_handler"

    config.after_initialize do
      Munster.configure
    end

    generators do
      require_relative "install_generator"
    end

    initializer "Munster.add_middleware" do |app|
      require_relative 'web'
    end
  end
end

Munster::Engine.routes.draw do
  webhook_controller = Munster::Web.new

  mount webhook_controller => "/:service_id"
end
