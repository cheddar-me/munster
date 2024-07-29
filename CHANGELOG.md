# Changelog
All notable changes to this project will be documented in this file.

This format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.4.1

- Webhook processor now requires `active_job/railtie`, instead of `active_job`. It requires GlobalID to work and that get's required only with railtie.
- Adding a state transition from `error` to `received`. Proccessing job will be enqueued automatic after this transition was executed.

## 0.4.0

- Limit the size of the request body, since otherwise there can be a large attack vector where random senders can spam the database with data and cause a denial of service. With background validation, this is one of the few cases where we want to reject the payload without persisting it.
- Manage the `state` of the `ReceivedWebhook` from the background job itself. This frees up the handler to actually do the work associated with processing only. The job will manage the rest.
- Use `valid?` in the background job instead of the controller. Most common configuration issue is an incorrectly specified signing secret, or an incorrectly implemented input validation. When these happen, it is better to allow the webhook to be reprocessed
- Use instance methods in handlers instead of class methods, as they are shorter to define. Assume a handler module supports `.new` - with a module using singleton methods it may return `self` from `new`.
- In the config, allow the handlers specified as strings. Module resolution in Rails happens after the config gets loaded, because the config may alter the Zeitwerk load paths. To allow the config to get loaded and to allow handlers to be autoloaded using Zeitwerk, the handler modules have to be resolved lazily. This also permits the handlers to be reloadable, like any module under Rails' autoloading control.
- Simplify the Rails app used in tests to be small and keep it in a single file
- If a handler is willing to expose errors to the caller, let Rails rescue the error and display an error page or do whatever else is configured for Rails globally.
- Store request headers with the received webhook to allow for async validation. Run `bin/rails g munster:install` to add the required migration.

## 0.3.1

- BaseHandler#expose_errors_to_sender? default to true now.

## 0.3.0

- state_machine_enum library was moved in it's own library/gem.
- Provide handled: true attribute for Rails.error.report method, because it is required in Rails 7.0.

## 0.2.0

- Handler methods are now defined as instance methods for simplicity.
- Define service_id in initializer with active_handlers, instead of handler class.
- Use ruby 3.0 as a base for standard/rubocop, format all code according to it.
- Use Rails common error reporter ( https://guides.rubyonrails.org/error_reporting.html )

## 0.1.0

- Initial release
