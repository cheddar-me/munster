# frozen_string_literal: true

Rails.application.routes.draw do
  mount Munster::Engine, at: "/webhooks"
end
