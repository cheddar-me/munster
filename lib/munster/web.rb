# frozen_string_literal: true

require 'rack'
require 'json'

class HandlerRefused < StandardError; end

module Munster
  class Web
    def call(env)
      request = Rack::Request.new(env)
      params = request.params
      handler = lookup_handler(params['service_id'])

      unless handler && handler.active?
        return render_error("Webhook handler is inactive", 503)
      end

      raise HandlerRefused unless handler.valid?(request)

      begin
        # FIXME: Duplicated webhook will be overwritten here and processing job will be quite for second time.
        # This will generate a following error in this case:
        #    Error performing Munster::ProcessingJob (Job ID: b40f3f28-81be-4c99-bce8-9ad879ec9754) from Async(default) in 9.95ms: ActiveRecord::RecordInvalid (Validation failed: Status Invalid transition from processing to received):
        #
        # This should be handled properly

        handler.handle(request)
        return response(200)
      rescue => e
        # TODO: add exception handler here
        # Appsignal.add_exception(e)

        if handler&.expose_errors_to_sender?
          return error_for_sender_from_exception(e)
        else
          return response(200)
        end
      end
    end

    def error_for_sender_from_exception(exception)
      case exception
      when HandlerRefused
        render_error("Webhook handler did not validate the request (signature or authentication may be invalid)", 403)
      when JSON::ParserError, KeyError
        render_error("Required parameters were not present in the request or the request body was not valid JSON", 400)
      else
        render_error("Internal error", 500)
      end
    end

    def render_error(message, status)
      response(status, { error: message }.to_json, { 'Content-Type' => 'application/json' })
    end

    def lookup_handler(service_id)
      Munster.configuration.active_handlers.index_by(&:service_id).fetch(service_id.to_sym, nil)
    end

    def response(status, body = '', headers = {})
      [status, { 'Content-Type' => headers['Content-Type'] || 'text/plain' }.merge(headers), [body]]
    end
  end
end
