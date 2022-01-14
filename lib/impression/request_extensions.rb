# frozen_string_literal: true

require 'qeweney'

# require_relative './pages'
require_relative './request_extensions/routing'
require_relative './request_extensions/responses'

# Extensions to `Qeweney::Request`
class Qeweney::Request
  
  # include Impression::Pages::RequestMethods
  include Impression::RequestExtensions::Routing
  include Impression::RequestExtensions::Responses
end
