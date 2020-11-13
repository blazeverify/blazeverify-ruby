require 'faraday'
require 'faraday_middleware'
require 'blazeverify/version'
require 'blazeverify/client'
require 'blazeverify/batch'
require 'blazeverify/resources/api_resource'
require 'blazeverify/resources/account'
require 'blazeverify/resources/batch_status'
require 'blazeverify/resources/verification'
if defined?(ActiveModel)
  require 'blazeverify/email_validator'
  I18n.load_path += Dir.glob(File.expand_path('../../config/locales/**/*', __FILE__))
end

module BlazeVerify
  @max_network_retries = 1

  class << self
    attr_accessor :api_key, :max_network_retries
  end

  module_function

  def verify(email, smtp: nil, accept_all: nil, timeout: nil)
    opts = {
      email: email, smtp: smtp, accept_all: accept_all, timeout: timeout
    }

    client = BlazeVerify::Client.new
    response = client.request(:get, 'verify', opts)

    if response.status == 249
      raise BlazeVerify::TimeoutError.new(
        code: response.status, message: response.body
      )
    else
      Verification.new(response.body)
    end
  end

  def account
    client = BlazeVerify::Client.new
    response = client.request(:get, 'account')
    Account.new(response.body)
  end


  class Error < StandardError
    attr_accessor :code, :message

    def initialize(code: nil, message: nil)
      @code = code
      @message = message
    end
  end
  class BadRequestError < Error; end
  class UnauthorizedError < Error; end
  class PaymentRequiredError < Error; end
  class ForbiddenError < Error; end
  class NotFoundError < Error; end
  class TooManyRequestsError < Error; end
  class InternalServerError < Error; end
  class ServiceUnavailableError < Error; end
  class TimeoutError < Error; end
end
