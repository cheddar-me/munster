Rails.application.routes.draw do
  mount Munster::Engine => "/munster", as: "webhooks"
end
