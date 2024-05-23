# frozen_string_literal: true

Rails.application.routes.draw do
  # It's possible to constrain to certain domains, like the following:
  # mount Munster::Engine => "/webhooks", constraints: Rails.configuration.domains.webhooks
  mount Munster::Engine, at: "/webhooks"
  # Read more:
  #   https://www.marcelofossrj.com/recipe/2018/08/22/engines-routes.html
end
