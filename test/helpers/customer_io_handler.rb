require "test_helper"

class Webhooks::CustomerIoHandlerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "can process subscription_preferences_changed event" do
    record = received_webhooks(:customer_io_changes)

    Webhooks::CustomerIoHandler.process(record)

    # TODO: customer.io topics integration is not finished yeat. So we skip it for now.
    assert_equal("skipped", record.reload.status)
  end

  test "should save event and enque a job to process" do
    template_webhook = received_webhooks(:customer_io_changes)
    test_request = ActionDispatch::TestRequest.create("RAW_POST_DATA" => template_webhook.body)
    ReceivedWebhook.delete_all # We use a sample payload from fixtures which are already inserted

    Webhooks::CustomerIoHandler.handle(test_request)

    assert_enqueued_with(job: WebhookProcessingJob)
    last_inserted_webhook = ReceivedWebhook.last
    assert_equal(Webhooks::CustomerIoHandler, last_inserted_webhook.handler)
    assert_equal(JSON.parse(template_webhook.body).fetch("event_id"), last_inserted_webhook.handler_event_id)
  end

  test "should handle same event sent twice, but insert it only once" do
    request = ActionDispatch::TestRequest.create(
      "RAW_POST_DATA" => received_webhooks(:customer_io_changes).body
    )
    ReceivedWebhook.delete_all # We use a sample payload from fixtures which are already inserted

    assert_changes_by("ReceivedWebhook.count", exactly: 1) do
      Webhooks::CustomerIoHandler.handle(request)
      Webhooks::CustomerIoHandler.handle(request)
      Webhooks::CustomerIoHandler.handle(request)
    end
  end

  test "can process subscribed event" do
    record = received_webhooks(:customer_io_subscribed)
    user = users(:feta)
    v = JSON.parse(record.body)

    v["data"]["identifiers"]["id"] = user.id
    v["data"]["customer_id"] = user.id

    record.body = v.to_json
    record.save!

    Webhooks::CustomerIoHandler.process(record)

    assert_equal("processed", record.reload.status)
    assert(
      user.reload.notifications["marketing_email"],
      "Email preferences for marketing notifications haven't been updated"
    )

    assert(
      user.notification_settings.where(name: "marketing").first!.email_enabled,
      "Marketing email preferences in notification_settings haven't been updated"
    )
  end

  test "can process unsubscribed event" do
    record = received_webhooks(:customer_io_unsubscribed)
    user = users(:loner)
    v = JSON.parse(record.body)

    user.notification_settings.create!(name: "marketing", email_enabled: true, push_enabled: true)

    v["data"]["identifiers"]["id"] = user.id
    v["data"]["customer_id"] = user.id

    record.body = v.to_json
    record.save!

    Webhooks::CustomerIoHandler.process(record)

    assert_equal("processed", record.reload.status)
    refute(
      user.reload.notifications["marketing_email"],
      "Email preferences for marketing notifications haven't been updated"
    )

    refute(
      user.notification_settings.where(name: "marketing").first!.email_enabled,
      "Marketing email preferences in notification_settings haven't been updated"
    )
  end

  test "can process unsubscribed event, even when notification_setting is missing" do
    record = received_webhooks(:customer_io_unsubscribed)
    user = users(:loner)
    v = JSON.parse(record.body)

    v["data"]["identifiers"]["id"] = user.id
    v["data"]["customer_id"] = user.id

    record.body = v.to_json
    record.save!

    Webhooks::CustomerIoHandler.process(record)

    refute(
      user.notification_settings.where(name: "marketing").first!.email_enabled,
      "Marketing email preferences in notification_settings haven't been updated"
    )
  end

  test "processing webhooks will not accepted" do
    record = received_webhooks(:customer_io_unsubscribed)
    record.update(status: :processing)

    Webhooks::CustomerIoHandler.process(record)

    assert_equal("processing", record.reload.status)
  end
end
