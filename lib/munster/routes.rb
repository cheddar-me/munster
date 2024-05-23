require_relative "engine"

Munster::Engine.routes.draw do
  require 'munster/web'

  mount Munster::Web.new => "/:service_id"
end
