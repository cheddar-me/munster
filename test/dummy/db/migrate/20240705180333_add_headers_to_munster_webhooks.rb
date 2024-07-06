class AddHeadersToMunsterWebhooks < ActiveRecord::Migration[7.1]
  def change
    add_column :received_webhooks, :request_headers, :jsonb, null: true
  end
end
