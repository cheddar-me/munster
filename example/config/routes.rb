Rails.application.routes.draw do
  # It's possible to constrain to certain domains, like the following:
  # mount Munster::Engine => "/", constraints: Rails.configuration.domains.webhooks

  # But this is a simple example, we'll just mount it to the root path.
  mount Munster::Engine => "/"
end
