# frozen_string_literal: true
require 'active_record'
require 'action_pack'
require 'action_controller'
require 'rails'

database = 'development.sqlite3'
ENV['DATABASE_URL'] = "sqlite3:#{database}"
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: database)
ActiveRecord::Base.logger = Logger.new(nil)
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
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

  routes.append do
    mount Munster::Engine, at: "/wehbooks"
    post "/per-user-munster/:user_id/private" => "munster/receive_webhooks#create"
  end
end

MunsterTestApp.initialize!

# run MunsterTestApp
