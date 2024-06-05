require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup { @body_str = received_webhooks(:received_provider_disruption).body}
  test "accepts a customer.io webhook with changed notification preferences" do
    post "/munster/test", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}
    assert_response 200

    webhook = Munster::ReceivedWebhook.last!

    assert_equal WebhookTestHandler, webhook.handler
    assert_equal webhook.status, "received"
    assert_equal webhook.body, @body_str
  end

  test "will throw a proper error, if service_id is not handled" do
    post "/munster/missing_service", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}
    assert_response 404
  end

  test "inactive handlers" do
    post "/munster/inactive", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response 503
    assert_equal "Webhook handler is inactive", response.parsed_body["error"]
  end

  test "invalid handlers" do
    post "/munster/invalid", params: @body_str, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response 403
    assert_equal "Webhook handler did not validate the request (signature or authentication may be invalid)", response.parsed_body["error"]
  end
end
