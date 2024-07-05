# frozen_string_literal: true

require "state_machine_enum"

module Munster
  class ReceivedWebhook < ActiveRecord::Base
    self.implicit_order_column = "created_at"
    self.table_name = "received_webhooks"

    include StateMachineEnum

    state_machine_enum :status do |s|
      s.permit_transition(:received, :processing)
      s.permit_transition(:received, :failed_validation)
      s.permit_transition(:processing, :skipped)
      s.permit_transition(:processing, :processed)
      s.permit_transition(:processing, :error)
    end

    def assign_from_request(action_dispatch_request)
      # Filter out all Rack-specific headers such as "rack.input" and the like. We are
      # only interested in the headers presented by the webserver
      headers = action_dispatch_request.env.filter_map do |(request_header, header_value)|
        if request_header.is_a?(String) && request_header.upcase == request_header && header_value.is_a?(String)
          [request_header, header_value]
        end
      end.to_h
      # If the migration hasn't been applied yet, we can't save the headers.
      if self.class.column_names.include?("request_headers")
        write_attribute("request_headers", headers)
      else
        Rails.logger.warn { "You need to run Munster migrations so that request headers can be persisted with the model. Async validation is not going to work without that column being set." }
      end
      write_attribute("body", action_dispatch_request.body.read.force_encoding(Encoding::BINARY))
    ensure
      action_dispatch_request.body.rewind
    end

    # @return [ActionDispatch::Request]
    def revived_request
      headers = try(:request_headers) || {}
      ActionDispatch::Request.new(headers.merge!("rack.input" => StringIO.new(body)))
    end

    def handler
      handler_module = handler_module_name.constantize

      # A bit of a workaround for the fact that older Munster versions used
      # class/module for handlers, but we found that it was annoying
      # with inheritance and the like. So, check a couple of methods and
      # return either an instance of the handler or the handler module itself
      calls_on_instance = handler_module.instance_methods.include?(:process) && handler_module.instance_methods.include?(:valid?)
      calls_on_instance ? handler_module.new : handler_module
    end
  end
end
