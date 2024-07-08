# frozen_string_literal: true
require 'rails/all'
database = 'development.sqlite3'

ENV['DATABASE_URL'] = "sqlite3:#{database}"
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: database)
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
  end
end

class MunsterTestApp < Rails::Application
  config.root = __dir__
  config.eager_load = false
  config.consider_all_requests_local = true
  config.secret_key_base = 'i_am_a_secret'
  config.active_support.cache_format_version = 7.0

  routes.append do
    root to: 'munster_test_app/welcome#index'
  end

  class WelcomeController < ActionController::Base
    def index
      render inline: 'Hi!'
    end
  end
end

MunsterTestApp.initialize!

# run MunsterTestApp
