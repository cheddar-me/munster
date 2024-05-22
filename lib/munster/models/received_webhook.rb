# frozen_string_literal: true

require_relative "../../munster"
require_relative "../state_machine_enum"

autoload :Munster, "munster"

module Munster
  class ReceivedWebhook < ActiveRecord::Base
    self.implicit_order_column = "created_at"
    #self.table_name = Munster.configuration.receive_webhooks_table_name

    include Munster::StateMachineEnum

    state_machine_enum :status do |s|
      s.permit_transition(:received, :processing)
      s.permit_transition(:processing, :skipped)
      s.permit_transition(:processing, :processed)
      s.permit_transition(:processing, :error)
    end

    def handler
      handler_module_name.constantize
    end
  end
end