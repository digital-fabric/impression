# frozen_string_literal: true

require 'bundler/setup'
require_relative './coverage' if ENV['COVERAGE']
require 'minitest/autorun'
require 'impression'

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
end

class PathRenderingResource < Impression::Resource
  def render(req)
    req.respond(absolute_path)
  end
end
