# frozen_string_literal: true

class CustomerIoHandler < Munster::BaseHandler
  class << self
    def process(webhook)
      return if webhook.status.eql?("processing")
      webhook.update!(status: :processing)

      json = JSON.parse(webhook.body, symbolize_names: true)

      case json[:metric]
      when "subscribed"
        ActiveRecord::Base.transaction do
          user = User.find(json.dig(:data, :identifiers, :id))

          user.update!(notifications: {marketing_email: true})
          user.modify_email_notification_setting("marketing", true)

          webhook.update!(status: :processed)
        end
      when "unsubscribed"
        ActiveRecord::Base.transaction do
          user = User.find(json.dig(:data, :identifiers, :id))

          user.update!(notifications: {marketing_email: false})
          user.modify_email_notification_setting("marketing", false)

          webhook.update!(status: :processed)
        end
      when "cio_subscription_preferences_changed"
        webhook.update!(status: :skipped)
      else
        webhook.update!(status: :skipped)
      end
    end

    def service_id
      :customer_io
    end

    def extract_event_id_from_request(action_dispatch_request)
      JSON.parse(action_dispatch_request.body.read).fetch("event_id")
    end

    def valid?(action_dispatch_request)
      true
    end
  end
end
