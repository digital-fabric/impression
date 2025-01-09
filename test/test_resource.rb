# frozen_string_literal: true

require_relative 'helper'

class ResourceTest < Minitest::Test
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
    assert_equal '/', req.resource_relative_path

    req = mock_req(':method' => 'GET', ':path' => '/foo2')
    assert_nil r1.route(req)
    assert_equal '/foo2', req.resource_relative_path

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    assert_equal r1, r1.route(req)
    assert_equal '/', req.resource_relative_path

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar')
    assert_equal r2, r1.route(req)
    assert_equal '/', req.resource_relative_path

    req = mock_req(':method' => 'GET', ':path' => '/foo/baz')
    assert_equal r3, r1.route(req)
    assert_equal '/', req.resource_relative_path

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar/littlebar')
    assert_equal r4, r1.route(req)
    assert_equal '/', req.resource_relative_path

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar/littlebar/littlebaz')
    assert_equal r4, r1.route(req)
    assert_equal '/littlebaz', req.resource_relative_path

    req = mock_req(':method' => 'GET', ':path' => '/foo/hi')
    assert_equal r1, r1.route(req)
    assert_equal '/hi', req.resource_relative_path

    req = mock_req(':method' => 'GET', ':path' => '/foo/hi/bye')
    assert_equal r1, r1.route(req)
    assert_equal '/hi/bye', req.resource_relative_path
  end

  def test_nested_resource_rendering
    r1 = Impression::Resource.new(path: 'foo')
    r2 = PathRenderingResource.new(parent: r1, path: 'bar')
    r3 = PathRenderingResource.new(parent: r1, path: 'baz')

    req = mock_req(':method' => 'GET', ':path' => '/')
    assert_nil r1.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    r1.route_and_call(req)
    # default reply
    assert_equal Qeweney::Status::NOT_FOUND, req.response_status

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar')
    r1.route_and_call(req)
    assert_equal '/foo/bar', req.response_body

    req = mock_req(':method' => 'GET', ':path' => '/foo/baz')
    r1.route_and_call(req)
    assert_equal '/foo/baz', req.response_body

    req = mock_req(':method' => 'GET', ':path' => '/foo/bbb')
    assert_equal r1, r1.route(req)
  end

  def test_relative_path
    r1 = CompletePathInfoRenderingResource.new(path: 'foo')
    r2 = CompletePathInfoRenderingResource.new(parent: r1, path: 'bar')
    r3 = CompletePathInfoRenderingResource.new(parent: r1, path: 'baz')

    req = mock_req(':method' => 'GET', ':path' => '/')
    assert_nil r1.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    r1.route_and_call(req)
    assert_equal '/foo /', req.response_body

    req = mock_req(':method' => 'GET', ':path' => '/foo/zzz')
    r1.route_and_call(req)
    assert_equal '/foo /zzz', req.response_body

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar')
    r1.route_and_call(req)
    assert_equal '/foo/bar /', req.response_body

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar/zzz')
    r1.route_and_call(req)
    assert_equal '/foo/bar /zzz', req.response_body

    req = mock_req(':method' => 'GET', ':path' => '/foo/baz')
    r1.route_and_call(req)
    assert_equal '/foo/baz /', req.response_body

    req = mock_req(':method' => 'GET', ':path' => '/foo/baz/xxx/yyy')
    r1.route_and_call(req)
    assert_equal '/foo/baz /xxx/yyy', req.response_body
  end

  class CallableResource < Impression::Resource
    def initialize(**props, &block)
      super(**props)
      @block = block
    end

    def call(req)
      @block.call(req)
    end
  end

  def test_callable_resource
    r1 = CompletePathInfoRenderingResource.new(path: 'foo')
    r2 = CallableResource.new(parent: r1, path: 'bar') { |req| req.respond('hi') }

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar')
    r1.route_and_call(req)
    assert_equal 'hi', req.response_body
  end

  class CallableRouteResource < Impression::Resource
    def initialize(**props, &block)
      super(**props)
      @block = block
    end

    def route(req)
      @block
    end
  end

  def test_callable_from_route_method
    r1 = CompletePathInfoRenderingResource.new(path: 'foo')
    r2 = CallableRouteResource.new(parent: r1, path: 'bar') { |req| req.respond('bye') }

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar')
    r1.route_and_call(req)
    assert_equal 'bye', req.response_body
  end

  def test_text_response
    c = Class.new(Impression::Resource) do
      def route(req)
        case req.path
        when '/text'
          text_response('foo')
        when '/html'
          html_response('bar')
        when '/json'
          json_response({ :baz => 123 })
        end
      end
    end

    r = c.new(path: '/')

    req = mock_req(':method' => 'GET', ':path' => '/text')
    r.route_and_call(req)
    assert_equal 'foo', req.response_body
    assert_equal 'text/plain', req.response_content_type

    req = mock_req(':method' => 'GET', ':path' => '/html')
    r.route_and_call(req)
    assert_equal 'bar', req.response_body
    assert_equal 'text/html', req.response_content_type

    req = mock_req(':method' => 'GET', ':path' => '/json')
    r.route_and_call(req)
    assert_equal '{"baz":123}', req.response_body
    assert_equal 'application/json', req.response_content_type
  end

  def test_resource_with_block
    r1 = Impression::Resource.new(path: '/') do |req|
      req.respond('foobar', ':status' => Qeweney::Status::TEAPOT)
    end

    req = mock_req(':method' => 'GET', ':path' => '/')
    r1.route_and_call(req)
    assert_equal 'foobar', req.response_body
    assert_equal Qeweney::Status::TEAPOT, req.response_status
  end
end
