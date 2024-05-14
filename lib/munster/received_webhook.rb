# frozen_string_literal: true

module Munster
  class ReceivedWebhook < ApplicationRecord
    self.implicit_order_column = "created_at"
    # TODO: this should take a configured table name, e.g. it should be possible to use 'received_webhooks' table.
    # self.table_name = "munster_received_webhooks"

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
