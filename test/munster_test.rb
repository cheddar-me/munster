# frozen_string_literal: true

require "test_helper"
require_relative "test_app"

class TestMunster < ActionDispatch::IntegrationTest
  def test_that_it_has_a_version_number
    refute_nil ::Munster::VERSION
  end

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
      "failing-with-exposed-errors": "FailingWithExposedErrors",
      "failing-with-concealed-errors": "FailingWithConcealedErrors",
      extract_id: "ExtractIdHandler"
    }
  end
  self.app = MunsterTestApp

  def self.xtest(msg)
    test(msg) { skip }
  end

  test "accepts a webhook without an event ID and stores it" do
    Munster::ReceivedWebhook.delete_all

    post "/munster/test", params: webhook_body, headers: {"CONTENT_TYPE" => "application/json"}
    assert_response 200

    webhook = Munster::ReceivedWebhook.last!

    assert_equal "WebhookTestHandler", webhook.handler_module_name
    assert_equal webhook.status, "received"
    assert_equal webhook.body, webhook_body
  end

  test "raises an error if the service_id is not known" do
    post "/munster/missing_service", params: webhook_body, headers: {"CONTENT_TYPE" => "application/json"}
    assert_response 404
  end

  test "inactive handlers" do
    post "/munster/inactive", params: webhook_body, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response 503
    assert_equal 'Webhook handler "inactive" is inactive', response.parsed_body["error"]
  end

  test "returns a 200 status and error message if the handler does not expose errors" do
    post "/munster/failing-with-concealed-errors", params: webhook_body, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response 200
    assert_equal false, response.parsed_body["ok"]
    assert response.parsed_body["error"]
  end

  test "returns a 500 status and error message if the handler does not expose errors" do
    post "/munster/failing-with-exposed-errors", params: webhook_body, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response 500
    # The response generation in this case is done by Rails, through the
    # common Rails error page
  end

  test "deduplicates received webhooks based on the event ID" do
    body = {event_id: SecureRandom.uuid, body: "test"}.to_json

    assert_changes_by -> { Munster::ReceivedWebhook.count }, exactly: 1 do
      3.times do
        post "/munster/extract_id", params: body, headers: {"CONTENT_TYPE" => "application/json"}
        assert_response 200
      end
    end
  end

  test "preserves the route params and the request params in the serialised request stored with the webhook" do
    body = {user_name: "John", number_of_dependents: 14}.to_json

    Munster::ReceivedWebhook.delete_all
    post "/per-user-munster/123/private", params: body, headers: {"CONTENT_TYPE" => "application/json"}
    assert_response 200

    received_webhook = Munster::ReceivedWebhook.first!
    assert_predicate received_webhook, :received?
    assert_equal body, received_webhook.request.body.read
    assert_equal "John", received_webhook.request.params["user_name"]
    assert_equal 14, received_webhook.request.params["number_of_dependents"]
    assert_equal "123", received_webhook.request.params["user_id"]
  end
end
