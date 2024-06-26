# Changelog
All notable changes to this project will be documented in this file.

This format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.3.1

### Changed

- BaseHandler#expose_errors_to_sender? default to true now.

## 0.3.0

### Changed
- state_machine_enum library was moved in it's own library/gem.

### Fixed
- Provide handled: true attribute for Rails.error.report method, because it is required in Rails 7.0.

## 0.2.0

### Changed

- Handler methods are now defined as instance methods for simplicity.
- Define service_id in initializer with active_handlers, instead of handler class.
- Use ruby 3.0 as a base for standard/rubocop, format all code according to it.

### Added

- Introduce Rails common error reporter ( https://guides.rubyonrails.org/error_reporting.html )

## 0.1.0

- Initial release
