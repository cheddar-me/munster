# frozen_string_literal: true
require 'active_record'
require 'action_pack'
require 'action_controller'
require 'active_job'
require 'rails'

database = 'development.sqlite3'
ENV['DATABASE_URL'] = "sqlite3:#{database}"
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: database)
ActiveRecord::Base.logger = Logger.new(nil)
ActiveRecord::Schema.define do
  create_table "received_webhooks", force: :cascade do |t|
    t.string "handler_event_id", null: false
    t.string "handler_module_name", null: false
    t.string "status", default: "received", null: false
    t.binary "body", null: false
    t.json "request_headers", null: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["handler_module_name", "handler_event_id"], name: "webhook_dedup_idx", unique: true
    t.index ["status"], name: "index_received_webhooks_on_status"
  end
end

require_relative "../lib/munster"
require_relative "test-webhook-handlers/webhook_test_handler"

class MunsterTestApp < Rails::Application
  config.logger = Logger.new(nil)
  config.autoload_paths << File.dirname(__FILE__) + "/test-webhook-handlers"
  config.root = __dir__
  config.eager_load = false
  config.consider_all_requests_local = true
  config.secret_key_base = 'i_am_a_secret'
  config.active_support.cache_format_version = 7.0
  config.hosts << ->(host) { true } # Permit all hosts
  routes.append do
    mount Munster::Engine, at: "/munster"
    post "/per-user-munster/:user_id/private" => "munster/receive_webhooks#create"
  end
end

MunsterTestApp.initialize!

# run MunsterTestApp
