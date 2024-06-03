require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  test "accepts a customer.io webhook with changed notification preferences" do
    body_str = received_webhooks(:customer_io_subscribed).body

    Munster::ReceivedWebhook.delete_all
    assert_changes_by -> { Munster::ReceivedWebhook.count }, exactly: 1 do
      3.times do
        post webhooks_url(service_id: "customer_io"), params: body_str, headers: {"CONTENT_TYPE" => "application/json"}
        assert_response 200
      end
    end

    webhook = ReceivedWebhook.last!

    assert_equal Webhooks::CustomerIoHandler, webhook.handler
    assert_equal "01E4C4CT6YDC7Y5M7FE1GWWPQJ", webhook.handler_event_id
    assert_equal webhook.status, "received"
    assert_equal webhook.body, body_str
  end
end
