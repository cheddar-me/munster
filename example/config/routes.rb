# frozen_string_literal: true


require "munster"

Rails.application.routes.draw do
  # It's possible to constrain to certain domains, like the following:
  # mount Munster::Engine => "/webhooks", constraints: Rails.configuration.domains.webhooks
  mount Munster::Engine, at: "/munster"

end
