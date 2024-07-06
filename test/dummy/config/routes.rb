Rails.application.routes.draw do
  post "/per-user-munster/:user_id/:service_id", to: "munster/receive_webhooks#create"
  mount Munster::Engine => "/munster", :as => "webhooks"
end
