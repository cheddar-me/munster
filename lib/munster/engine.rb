module Munster
  class Railtie < Rails::Engine
    isolate_namespace Munster

    generators do
      require_relative "install_generator"
    end
  end
end
