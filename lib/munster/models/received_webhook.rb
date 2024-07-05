# frozen_string_literal: true

require "state_machine_enum"

module Munster
  class ReceivedWebhook < ActiveRecord::Base
    self.implicit_order_column = "created_at"
    self.table_name = "received_webhooks"

    include StateMachineEnum

    state_machine_enum :status do |s|
      s.permit_transition(:received, :processing)
      s.permit_transition(:processing, :skipped)
      s.permit_transition(:processing, :processed)
      s.permit_transition(:processing, :error)
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
