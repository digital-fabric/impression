# frozen_string_literal: true

require_relative 'helper'

class ImpressionModuleTest < Minitest::Test
  def test_resource_method
    r1 = Impression.resource do |req|
      req.respond('foobar', ':status' => Qeweney::Status::TEAPOT)
    end

    req = mock_req(':method' => 'GET', ':path' => '/')
    r1.route_and_call(req)
    assert_equal 'foobar', req.adapter.body
    assert_equal Qeweney::Status::TEAPOT, req.response_status
  end

  def test_file_tree_method
    r1 = Impression.file_tree(path: '/foo', directory: '/bar')

    assert_kind_of Impression::FileTree, r1
    assert_equal '/foo', r1.path
    assert_equal '/bar', r1.directory
  end

  def test_app_method
    r1 = Impression.app(path: '/foo', directory: '/bar')

    assert_kind_of Impression::App, r1
    assert_equal '/foo', r1.path
    assert_equal '/bar', r1.directory
  end
end
