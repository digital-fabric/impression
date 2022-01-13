# frozen_string_literal: true

require_relative 'helper'

class AppTest < MiniTest::Test
  def test_empty_app
    app = Impression::App.new(path: '/')
    req = mock_req(':method' => 'GET', ':path' => '/')

    app.respond(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status
  end

  def test_app_each
    app = Impression::App.new(path: '/')
    
    buffer = []
    app.each { |r| buffer << r }
    assert_equal [app], buffer

    foo = PathRenderingResource.new(parent: app, path: 'foo')
    bar = PathRenderingResource.new(parent: app, path: 'bar')
    
    buffer = []
    app.each { |r| buffer << r }
    assert_equal [app, foo, bar], buffer
  end

  def test_app_to_proc
    app = Impression::App.new(path: '/')
    app_proc = app.to_proc

    foo = PathRenderingResource.new(parent: app, path: 'foo')
    bar = PathRenderingResource.new(parent: app, path: 'bar')

    # req = mock_req(':method' => 'GET', ':path' => '/')
    # app_proc.(req)
    # assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status

    req = mock_req(':method' => 'GET', ':path' => '/foo')
    app_proc.(req)
    assert_equal '/foo', req.adapter.body

    req = mock_req(':method' => 'GET', ':path' => '/bar')
    app_proc.(req)
    assert_equal '/bar', req.adapter.body

    req = mock_req(':method' => 'GET', ':path' => '/baz')
    app_proc.(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status
  end
end
