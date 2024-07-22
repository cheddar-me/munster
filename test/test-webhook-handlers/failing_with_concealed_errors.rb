class FailingWithConcealedErrors < Munster::BaseHandler
  def handle(_request)
    raise "oops"
  end

  def expose_errors_to_sender? = false
end
