module Munster
  class Railtie < Rails::Railtie
    generators do
      require_relative "install_generator"
    end
  end
end
