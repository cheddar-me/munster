Munster::Engine.routes.draw do
  post "/:service_id", to: "receive_webhooks#create", as: 'webhook'
end
