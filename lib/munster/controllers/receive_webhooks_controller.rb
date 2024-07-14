# frozen_string_literal: true

module Munster
  class ReceiveWebhooksController < ActionController::API
    class HandlerInactive < StandardError
    end

    class UnknownHandler < StandardError
    end

    def create
      handler = lookup_handler(service_id)
      raise HandlerInactive unless handler.active?
      handler.handle(request)
      render(json: {ok: true, error: nil})
    rescue => e
      warn e
      warn e.backtrace
      # If exposing errors to sender is desired we can let the standard Rails stack take over
      # the error handling. This will differ depending on the environment the app runs in.
      raise e if handler && handler.expose_errors_to_sender?

      Rails.error.set_context(**Munster.configuration.error_context)
      # Rails 7.1 only requires `error` attribute for .report method, but Rails 7.0 requires `handled:` attribute additionally.
      # We're setting `handled:` and `severity:` attributes to maintain compatibility with all versions of > rails 7.
      Rails.error.report(e, handled: true, severity: :error)
      error_for_sender_from_exception(e, handler)
    end

    def service_id
      params.require(:service_id)
    end

    def error_for_sender_from_exception(e, maybe_handler)
      case e
      when UnknownHandler
        render_error_with_ok_status("No handler found for #{service_id.inspect}")
      when HandlerInactive
        render_error_with_ok_status("Webhook handler #{service_id.inspect} is inactive")
      when JSON::ParserError
        render_error_with_ok_status("Request body is not valid JSON")
      else
        render_error_with_ok_status("Internal error")
      end
    end

    def render_error_with_ok_status(message_str)
      json = {ok: false, error: message_str}.to_json
      render(json: json, status: :ok)
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
