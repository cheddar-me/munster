# This is for Revolut V1 API for webhooks - https://developer.revolut.com/docs/business/webhooks-v-1-deprecated
class RevolutBusinessV1Handler < Munster::BaseHandler
  def valid?(_)
    # V1 of Revolut webhooks does not support signatures
    true
  end

  def self.process(webhook)
    parsed_payload = JSON.parse(webhook.body)
    topic = parsed_payload.fetch("Topic")
    case topic
    when "tokens" # Account access revocation payload
      # ...
    when "draftpayments/transfers" # Draft payment transfer notification payload
      # ...
    else
      # ...
    end
  end

  def self.extract_event_id_from_request(action_dispatch_request)
    # Since b-tree indices generally divide from the start of the string, place the highest
    # entropy component at the start (the EventId)
    key_components = %w[EventId Topic Version]
    key_components.map do |key|
      action_dispatch_request.params.fetch(key)
    end.join("-")
  end
end
