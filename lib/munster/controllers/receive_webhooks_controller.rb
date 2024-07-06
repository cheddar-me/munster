# frozen_string_literal: true

module Munster
  class ReceiveWebhooksController < ActionController::API
    class InvalidRequest < StandardError
    end

    class HandlerInactive < StandardError
    end

    class UnknownHandler < StandardError
    end

    def create
      handler = lookup_handler(params[:service_id])
      raise HandlerInactive unless handler.active?
      raise InvalidRequest if !handler.validate_async? && !handler.valid?(request)
      handler.handle(request)
      render(json: {ok: true, error: nil})
    rescue => e
      Rails.error.set_context(**Munster.configuration.error_context)
      # Rails 7.1 only requires `error` attribute for .report method, but Rails 7.0 requires `handled:` attribute additionally.
      # We're setting `handled:` and `severity:` attributes to maintain compatibility with all versions of > rails 7.
      Rails.error.report(e, handled: true, severity: :error)
      error_for_sender_from_exception(e, handler)
    end

    def error_for_sender_from_exception(e, maybe_handler)
      force_ok = !maybe_handler.try(:expose_errors_to_sender?)
      case e
      when UnknownHandler
        render_error("No handler found for #{params[:service_id.inspect]}", :not_found)
      when InvalidRequest
        render_error("Webhook handler did not validate the request (signature or authentication may be invalid)", force_ok ? :ok : :bad_request)
      when HandlerInactive
        render_error("Webhook handler is temporarily deactivated", force_ok ? :ok : :service_unavailable)
      when JSON::ParserError
        render_error("Request body is not valid JSON", force_ok ? :ok : :bad_request)
      else
        render_error("Internal error", force_ok ? :ok : :internal_server_error)
      end
    end

    def render_error(message_str, status_sym)
      json = {ok: false, error: message_str}.to_json
      render(json: json, status: status_sym)
    end

    def lookup_handler(service_id_str)
      Munster.configuration.active_handlers.with_indifferent_access.fetch(service_id_str)
    rescue KeyError
      raise UnknownHandler
    end
  end
end
