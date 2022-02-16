# frozen_string_literal: true

require_relative 'helper'

class RackAppTest < MiniTest::Test
  def test_basic_rack_app
    app = Impression.rack_app(path: '/etc/rack') { |env|
      [
        200,
        {'Content-Type' => 'text/plain'},
        ['Hello, world!']
      ]
    }

    req = mock_req(':method' => 'GET', ':path' => '/foobar')
    assert_nil app.route(req)

    req = mock_req(':method' => 'GET', ':path' => '/etc/rack')
    app.route_and_call(req)
    assert_equal '200', req.response_status
    assert_equal 'text/plain', req.response_headers['Content-Type']
    assert_equal 'Hello, world!', req.response_body
  end

  def test_path_rewriting
    app = Impression.rack_app(path: '/') { |env|
      [200, {}, ["path: #{env['PATH_INFO']}"]]
    }

    req = mock_req(':method' => 'GET', ':path' => '/foo/bar')
    app.route_and_call(req)
    assert_equal 'path: /foo/bar', req.response_body

    ###

    app = Impression.rack_app(path: '/etc/rack') { |env|
      [200, {}, ["path: #{env['PATH_INFO']}"]]
    }

    req = mock_req(':method' => 'GET', ':path' => '/etc/rack')
    app.route_and_call(req)
    assert_equal 'path: /', req.response_body

    req = mock_req(':method' => 'GET', ':path' => '/etc/rack/foo/bar')
    app.route_and_call(req)
    assert_equal 'path: /foo/bar', req.response_body
  end
end
