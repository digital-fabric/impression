# frozen_string_literal: true

require 'bundler/setup'
require_relative './coverage' if ENV['COVERAGE']
require 'minitest/autorun'
require 'impression'
require 'qeweney/test_adapter'

module Kernel
  def mock_req(**args)
    Qeweney::TestAdapter.mock(**args)
  end

  def capture_exception
    yield
  rescue Exception => e
    e
  end

  def trace(*args)
    STDOUT.orig_write(format_trace(args))
  end

  def format_trace(args)
    if args.first.is_a?(String)
      if args.size > 1
        format("%s: %p\n", args.shift, args)
      else
        format("%s\n", args.first)
      end
    else
      format("%p\n", args.size == 1 ? args.first : args)
    end
  end
end

module Minitest::Assertions
  def assert_in_range exp_range, act
    msg = message(msg) { "Expected #{mu_pp(act)} to be in range #{mu_pp(exp_range)}" }
    assert exp_range.include?(act), msg
  end

  def assert_response exp_body, exp_content_type, req
    actual = req.response_body
    assert_equal exp_body, actual

    return unless exp_content_type

    if Symbol === exp_content_type
      exp_content_type = Qeweney::MimeTypes[exp_content_type]
    end
    actual = req.response_content_type
    assert_equal exp_content_type, actual
  end
end

class Impression::Resource
  def route_and_call(req)
    route(req).call(req)
  end
end

class PathRenderingResource < Impression::Resource
  def call(req)
    req.respond(absolute_path)
  end
end

class CompletePathInfoRenderingResource < Impression::Resource
  def call(req)
    req.respond("#{absolute_path} #{req.resource_relative_path}")
  end
end

# Extensions to be used in conjunction with `Qeweney::TestAdapter`
class Qeweney::Request
  def response_headers
    adapter.headers
  end

  def response_body
    adapter.body
  end

  def response_status
    adapter.status
  end

  def response_content_type
    response_headers['Content-Type']
  end
end

puts "Polyphony backend: #{Thread.current.backend.kind}"
