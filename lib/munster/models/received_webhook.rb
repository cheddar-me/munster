# frozen_string_literal: true

require "state_machine_enum"

module Munster
  class ReceivedWebhook < ActiveRecord::Base
    self.implicit_order_column = "created_at"
    self.table_name = "received_webhooks"

    include StateMachineEnum

    state_machine_enum :status do |s|
      s.permit_transition(:received, :processing)
      s.permit_transition(:processing, :failed_validation)
      s.permit_transition(:processing, :skipped)
      s.permit_transition(:processing, :processed)
      s.permit_transition(:processing, :error)
    end

    # Store the pertinent data from an ActionDispatch::Request into the webhook.
    # @param [ActionDispatch::Request]
    def request=(action_dispatch_request)
      # Filter out all Rack-specific headers such as "rack.input" and the like. We are
      # only interested in the actual HTTP headers presented by the webserver. Mostly...
      headers = action_dispatch_request.env.filter_map do |(header_name, header_value)|
        if header_name.is_a?(String) && header_name.upcase == header_name && header_value.is_a?(String)
          [header_name, header_value]
        end
      end.to_h

      # ...except the path parameters - they do not get parsed from the headers, but instead get set by Journey - the Rails
      # router - when the ActionDispatch::Request object gets instantiated. They need to be preserved separately in case the Munster
      # controller gets mounted under a parametrized path - and the path component actually is a parameter that the webhook
      # handler either needs for validation or for processing
      headers["action_dispatch.request.path_parameters"] = action_dispatch_request.env.fetch("action_dispatch.request.path_parameters")

      # ...and the raw request body - because we already save it separately
      headers.delete("RAW_POST_DATA")

      request_body_io = action_dispatch_request.env.fetch("rack.input")
      write_attribute("body", request_body_io.read.force_encoding(Encoding::BINARY))
      write_attribute("request_headers", headers)
    ensure
      request_body_io.rewind
    end

    # A Munster handler is, in a way, a tiny Rails controller which runs in a background job. To allow this,
    # we need to provide access not only to the webhook payload (the HTTP request body, usually), but also
    # to the rest of the HTTP request - such as headers and route params. For example, imagine you use
    # a system where your multiple tenants (users) may receive webhooks from the same sender. However, you
    # need to dispatch those webhooks to those particular tenants of your application. Instead of mounting
    # Munster as an engine under a common route, you mount it like so:
    #
    #    post "/incoming-webhooks/:user_id/:service_id" => "munster/receive_webhooks#create"
    #
    # This way, the tenant ID (the `user_id`) parameter is not going to be provided to you inside the webhook
    # payload, as the sender is not sending it to you at all. However, you do have that parameter in your
    # route. When processing the webhook, it is important for you to know which tenant has received the
    # webhook - so that you can manipulate their data, and not the data belonging to another tenant. With
    # validation, it is important too - in such a multitenant setup every user is likely to have their own,
    # specific signing secret that they have set up. To find that secret and compare the signature, you
    # need access to that `user_id` parameter.
    #
    # To allow access to these, Munster allows the ActionDispatch::Request object to be persisted. The
    # persistence is not 1:1 - the Request is a fairly complex object, with lots of things injected into it
    # by the Rails stack. Not all of those injected properties (Rack headers) are marshalable, some of them
    # depend on the Rails application configuration, etc. However, we do retain the most important things
    # for webhooks to be correctly handled.
    #
    # * The HTTP request body
    # * The headers set by the webserver and the downstream proxies
    # * The request body and query string params, depending on the MIME type
    # * The route params. These are set by Journey (the Rails router) and cannot be reconstructed from a "bare" request
    #
    # While this reconstruction is best-effort it might not be lossless. For example, there might be no access
    # to Rack hijack, streaming APIs, the cookie jar or other more high-level Rails request access features.
    # You will, however, have the basics in place - such as the params, the request body, the path params
    # (as were decoded by your routes) etc. But it should be sufficient to do the basic tasks to process a webhook.
    #
    # @return [ActionDispatch::Request]
    def request
      ActionDispatch::Request.new(request_headers.merge!("rack.input" => StringIO.new(body.to_s.b)))
    end

    def handler
      handler_module_name.constantize.new
    end
  end
end
