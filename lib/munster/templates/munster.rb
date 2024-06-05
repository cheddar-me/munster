Munster.configure do |config|
  # Active Handlers are defined as hash with key as a service_id and handler class  that would handle webhook request.
  # Example:
  #   {:test => TestHandler, :inactive => InactiveHandler}
  config.active_handlers = {}
  config.processing_job_class = Munster::ProcessingJob
end
