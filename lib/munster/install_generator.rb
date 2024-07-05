# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Munster
  #
  # Rails generator used for setting up Munster in a Rails application.
  # Run it with +bin/rails g munster:install+ in your console.
  #
  class InstallGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    source_root File.expand_path("../templates", __FILE__)

    def create_migration_file
      migration_template "create_munster_tables.rb.erb", File.join(db_migrate_path, "create_munster_tables.rb")
      migration_template "add_headers_to_munster_webhooks.rb.erb", File.join(db_migrate_path, "add_headers_to_munster_webhooks.rb")
    end

    def copy_files
      template "munster.rb", File.join("config", "initializers", "munster.rb")
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::STRING.to_f}]"
    end
  end
end
