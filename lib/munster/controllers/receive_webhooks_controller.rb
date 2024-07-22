# frozen_string_literal: true

module Munster
  class ReceiveWebhooksController < ActionController::API
    class HandlerInactive < StandardError
    end

    class UnknownHandler < StandardError
    end

    def create
      Rails.error.set_context(**Munster.configuration.error_context)
      handler = lookup_handler(service_id)
      raise HandlerInactive unless handler.active?
      handler.handle(request)
      render(json: {ok: true, error: nil})
    rescue UnknownHandler => e
      Rails.error.report(e, handled: true, severity: :error)
      render_error_with_status("No handler found for #{service_id.inspect}", status: :not_found)
    rescue HandlerInactive => e
      Rails.error.report(e, handled: true, severity: :error)
      render_error_with_status("Webhook handler #{service_id.inspect} is inactive", status: :service_unavailable)
    rescue => e
      raise e unless handler
      raise e if handler.expose_errors_to_sender?
      Rails.error.report(e, handled: true, severity: :error)
      render_error_with_status("Internal error (#{e})")
    end

    def service_id
      params.require(:service_id)
    end

    def render_error_with_status(message_str, status: :ok)
      json = {ok: false, error: message_str}.to_json
      render(json: json, status: status)
    end

    def lookup_handler(service_id_str)
      active_handlers = Munster.configuration.active_handlers.with_indifferent_access
      # The config can specify a mapping of:
      # {"service-1" => MyHandler }
      # or
      # {"service-2" => "MyOtherHandler"}
      # We need to support both, because `MyHandler` is not loaded yet when Rails initializers run.
      # Zeitwerk takes over after the initializers. So we can't really use a module in the init cycle just yet.
      # We can, however, use the module name - and resolve it lazily, later.
      handler_class_or_class_name = active_handlers.fetch(service_id_str)
      handler_class = handler_class_or_class_name.respond_to?(:constantize) ? handler_class_or_class_name.constantize : handler_class_or_class_name
      handler_class.new
    rescue KeyError
      raise UnknownHandler
    end
  end
end
