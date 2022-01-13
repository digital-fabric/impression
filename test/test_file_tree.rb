# frozen_string_literal: true

require_relative 'helper'
require 'qeweney/test_adapter'

class FileTreeTest < MiniTest::Test
  STATIC_PATH = File.join(__dir__, 'static')

  def setup
    @file_tree = Impression::FileTree.new(path: '/', directory: STATIC_PATH)
  end

  def test_file_tree_routing
    req = mock_req(':method' => 'GET', ':path' => '/')
    assert_equal @file_tree, @file_tree.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/nonexistent')
    assert_equal @file_tree, @file_tree.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/index.html')
    assert_equal @file_tree, @file_tree.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    assert_equal @file_tree, @file_tree.route(req)
  end

  def static(path)
    IO.read(File.join(STATIC_PATH, path))
  end

  def test_file_tree_response
    req = mock_req(':method' => 'GET', ':path' => '/roo')
    @file_tree.route_and_respond(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/foo2')
    @file_tree.route_and_respond(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/bar2')
    @file_tree.route_and_respond(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/js/a.js')
    @file_tree.route_and_respond(req)
    assert_response static('js/a.js'), :js, req

    req = mock_req(':method' => 'GET', ':path' => '/foo.html')
    @file_tree.route_and_respond(req)
    assert_response static('foo.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    @file_tree.route_and_respond(req)
    assert_response static('foo.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/index.html')
    @file_tree.route_and_respond(req)
    assert_response static('index.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/')
    @file_tree.route_and_respond(req)
    assert_response static('index.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/bar/index.html')
    @file_tree.route_and_respond(req)
    assert_response static('bar/index.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/bar')
    @file_tree.route_and_respond(req)
    assert_response static('bar/index.html'), :html, req
  end

  def test_non_root_file_tree_response
    @file_tree = Impression::FileTree.new(path: '/app', directory: STATIC_PATH)

    req = mock_req(':method' => 'GET', ':path' => '/app/roo')
    @file_tree.route_and_respond(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/foo2')
    @file_tree.route_and_respond(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/bar2')
    @file_tree.route_and_respond(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/app/js/a.js')
    @file_tree.route_and_respond(req)
    assert_response static('js/a.js'), :js, req

    req = mock_req(':method' => 'GET', ':path' => '/app/foo.html')
    @file_tree.route_and_respond(req)
    assert_response static('foo.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/foo')
    @file_tree.route_and_respond(req)
    assert_response static('foo.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/index.html')
    @file_tree.route_and_respond(req)
    assert_response static('index.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/')
    @file_tree.route_and_respond(req)
    assert_response static('index.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/bar/index.html')
    @file_tree.route_and_respond(req)
    assert_response static('bar/index.html'), :html, req

    req = mock_req(':method' => 'GET', ':path' => '/app/bar')
    @file_tree.route_and_respond(req)
    assert_response static('bar/index.html'), :html, req
  end
end
