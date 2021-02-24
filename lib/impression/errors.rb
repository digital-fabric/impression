# frozen_string_literal: true

require 'qeweney/status'

module Impression
  class BaseError < StandardError
    def http_status
      raise NotImplementedError
    end
  end

  class NotFoundError < BaseError
    def http_status
      Qeweney::Status::NOT_FOUND
    end
  end
end
