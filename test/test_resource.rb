# frozen_string_literal: true

require_relative 'helper'
require 'qeweney/test_adapter'

class ResourceTest < MiniTest::Test
  def test_absolute_path
    r1 = Impression::Resource.new(path: 'foo')
    assert_equal '/foo', r1.absolute_path

    r2 = Impression::Resource.new(parent: r1, path: 'bar')
    assert_equal '/foo/bar', r2.absolute_path
  end

  def test_each
    r1 = Impression::Resource.new(path: 'foo')
    r2 = Impression::Resource.new(parent: r1, path: 'bar')
    r3 = Impression::Resource.new(parent: r1, path: 'baz')

    assert_equal [r2, r3], r1.children.values

    buffer = []
    r1.each { |r| buffer << r }
    assert_equal [r1, r2, r3], buffer
  end

  def test_route
    r1 = Impression::Resource.new(path: 'foo')
    r2 = Impression::Resource.new(parent: r1, path: 'bar')
    r3 = Impression::Resource.new(parent: r1, path: 'baz')
    r4 = Impression::Resource.new(parent: r2, path: 'littlebar')

    assert_equal [r2, r3], r1.children.values
    assert_equal [r4], r2.children.values

    req = mock_req(':method' => 'GET', ':path' => '/')
    assert_nil r1.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    assert_equal r1, r1.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar')
    assert_equal r2, r1.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo/baz')
    assert_equal r3, r1.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar/littlebar')
    assert_equal r4, r1.route(req)
  end

  def test_nested_resource_rendering
    r1 = Impression::Resource.new(path: 'foo')
    r2 = PathRenderingResource.new(parent: r1, path: 'bar')
    r3 = PathRenderingResource.new(parent: r1, path: 'baz')

    req = mock_req(':method' => 'GET', ':path' => '/')
    r1.render(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    r1.render(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar')
    r1.render(req)
    assert_equal '/foo/bar', req.adapter.body

    req = mock_req(':method' => 'GET', ':path' => '/foo/baz')
    r1.render(req)
    assert_equal '/foo/baz', req.adapter.body

    req = mock_req(':method' => 'GET', ':path' => '/foo/bbb')
    r1.render(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status
  end
end
