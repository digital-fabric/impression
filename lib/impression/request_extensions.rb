# frozen_string_literal: true

require 'qeweney'

require_relative './pages'

class Qeweney::Request
  include Impression::Pages::RequestMethods
end
