# frozen_string_literal: true

module Munster
  class ReceiveWebhooksController < ActionController::API
    class HandlerRefused < StandardError
    end

    class HandlerInactive < StandardError
    end

    def create
      handler = lookup_handler(params[:service_id]).new

      raise HandlerInactive unless handler.active?
      raise HandlerRefused unless handler.valid?(request)

      handler.handle(request)
      head :ok
    rescue KeyError # handler was not found, so we return generic 404 error.
      render_error("Required parameters were not present in the request", :not_found)
    rescue => e
      Rails.error.set_context(**Munster.configuration.error_context)
      # Rails 7.1 only requires `error` attribute for .report method, but Rails 7.0 requires `handled:` attribute additionally.
      # We're setting `handled:` and `severity:` attributes to maintain compatibility with all versions of > rails 7.
      Rails.error.report(e, handled: true, severity: :error)

      if handler&.expose_errors_to_sender?
        error_for_sender_from_exception(e)
      else
        head :ok
      end
    end

    def error_for_sender_from_exception(e)
      case e
      when HandlerRefused
        render_error("Webhook handler did not validate the request (signature or authentication may be invalid)", :forbidden)
      when HandlerInactive
        render_error("Webhook handler is inactive", :service_unavailable)
      when JSON::ParserError
        render_error("Request body is not a valid JSON", :bad_request)
      else
        render_error("Internal error", :internal_server_error)
      end
    end

    def render_error(message_str, status_sym)
      json = {error: message_str}.to_json
      render(json: json, status: status_sym)
    end

    def lookup_handler(service_id_str)
      Munster.configuration.active_handlers.with_indifferent_access.fetch(service_id_str)
    end
  end
end
