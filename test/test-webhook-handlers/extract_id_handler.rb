class ExtractIdHandler < WebhookTestHandler
  def extract_event_id_from_request(action_dispatch_request)
    JSON.parse(action_dispatch_request.body.read).fetch("event_id")
  end
end
