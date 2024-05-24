Munster::Engine.routes.draw do
  post "/:service_id", to: "receive_webhooks#create", namespace: "munster"
end
