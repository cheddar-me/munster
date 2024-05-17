# frozen_string_literal: true

require 'active_record' if defined?(Rails)
require_relative '../state_machine_enum'

unless defined?(ApplicationRecord)
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end

module Munster
  class ReceivedWebhook < ApplicationRecord
    self.implicit_order_column = "created_at"
    # self.table_name = Munster.receive_webhooks_table_name

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
