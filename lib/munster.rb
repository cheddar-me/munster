# frozen_string_literal: true

require_relative "munster/version"
require_relative "munster/railtie" if defined?(Rails::Railtie)

module Munster
  class Error < StandardError; end
  # Your code goes here...
end
