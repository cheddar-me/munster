# Munster

Munster is a Rails engine that provides a webhook endpoint for receiving and processing webhooks from various services. Engine stores received webhook first and later processes webhook in a separete async process.

Source code is extracted from https://cheddar.me/ main service to be used in internal microservices. Code here could be a subject to change while we flesh out details.

Due to that, support for this gem is limited. But we're always happy to hear your feedback!

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add munster

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install munster

## Usage

Generate migrations and initializer file.

`munster:install`

Mount munster engine in your routes.

`mount Munster::Engine, at: "/webhooks"`

## Requirements

This project depends on two dependencies:

- Ruby >= 3.0
- Rails >= 7.0

## Error reporter

This gem uses [Rails common error reporter](https://guides.rubyonrails.org/error_reporting.html) to report any possible error to services like Honeybadger, Appsignal, Sentry and etc. Most of those services already support this common interface, if not - it's not that hard to add this support on your own.

It's possible to provide additional context for every error. e.g.
```
Munster.configure do |config|
  config.error_context = { appsignal: { namespace: "webhooks" } }
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cheddar-me/munster.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
