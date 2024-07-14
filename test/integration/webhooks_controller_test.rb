require "test_helper"
require_relative "../test_app"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  def webhook_body
    <<~JSON
      {
        "provider_id": "musterbank-flyio",
        "starts_at": "<%= Time.now.utc %>",
        "external_source": "The Forge Of Downtime",
        "external_ticket_title": "DOWN-123",
        "internal_description_markdown": "A test has failed"
      }
    JSON
  end

  Munster.configure do |config|
    config.active_handlers = {
      test: WebhookTestHandler,
      inactive: "InactiveHandler",
      invalid: "InvalidHandler",
      private: "PrivateHandler",
      extract_id: "ExtractIdHandler"
    }
  end
  self.app = MunsterTestApp

  def self.xtest(msg)
    test(msg) { skip }
  end

  test "accepts a customer.io webhook with changed notification preferences" do
    Munster::ReceivedWebhook.delete_all

    post "/munster/test", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}
    assert_response 200

    webhook = Munster::ReceivedWebhook.last!

    assert_equal "WebhookTestHandler", webhook.handler_module_name
    assert_equal webhook.status, "received"
    assert_equal webhook.body, @body_str
  end

  xtest "will throw a proper error, if service_id is not handled" do
    post "/missing_service", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}
    assert_response 404
  end

  xtest "inactive handlers" do
    post "/inactive", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response 503
    assert_equal 'Webhook handler "inactive" is inactive', response.parsed_body["error"]
  end

  xtest "invalid handlers" do
    post "/invalid", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response 403
    assert_equal 'Webhook handler "invalid" did not validate the request (signature or authentication may be invalid)', response.parsed_body["error"]
  end

  xtest "does not respond with a non-OK status but does return an error to the caller if the handler does not want to expose errors" do
    post "/private", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response 200
    assert response.parsed_body["error"]
  end

  xtest "deduplicates received webhooks based on the event ID" do
    body = {event_id: SecureRandom.uuid, body: "test"}.to_json

    assert_changes_by -> { Munster::ReceivedWebhook.count }, exactly: 1 do
      3.times do
        post "/extract_id", params: body, headers: {"CONTENT_TYPE" => "application/json"}
        assert_response 200
      end
    end
  end

  xtest "preserves the route params and the request params in the serialised request stored with the webhook" do
    body = {user_name: "John", number_of_dependents: 14}.to_json

    Munster::ReceivedWebhook.delete_all
    post "/per-user-munster/123/private", params: body, headers: {"CONTENT_TYPE" => "application/json"}
    assert_response 200

    received_webhook = Munster::ReceivedWebhook.first!
    assert_equal body, received_webhook.request.body.read
    assert_equal "John", received_webhook.request.params["user_name"]
    assert_equal 14, received_webhook.request.params["number_of_dependents"]
    assert_equal "123", received_webhook.request.params["user_id"]
  end
end
