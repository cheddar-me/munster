# frozen_string_literal: true

require_relative "../munster"
require_relative "jobs/processing_job"
require_relative "models/received_webhook"
require_relative "base_handler"
require_relative "web"

module Munster
  class Engine < ::Rails::Engine
    initializer "Munster.load_dependencies" do |app|
      require_relative 'web'
      require_relative 'routes'
    end

    config.after_initialize do
      Munster.configure
    end

    generators do
      require_relative "install_generator"
    end

    initializer "munster.add_reloader" do |app|
      app.middleware.use Munster::Reloader
    end
  end

  class Reloader
    def initialize(app)
      @app = app
      setup_reloader
    end

    def setup_reloader
      ActiveSupport::Reloader.to_prepare do
        Rails.application.reload_routes!
      end
    end

    def call(env)
      @app.call(env)
    end
  end
end
