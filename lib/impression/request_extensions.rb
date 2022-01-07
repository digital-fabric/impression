# frozen_string_literal: true

require 'qeweney'

require_relative './pages'
require_relative './request_routing'

class Qeweney::Request
  include Impression::Pages::RequestMethods
  include Impression::RequestRouting
end
