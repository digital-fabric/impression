# frozen_string_literal: true

require_relative 'helper'
require 'qeweney/test_adapter'

class AppTest < MiniTest::Test
  def test_empty_app
    app = Impression::App.new(path: '/')
    req = Qeweney::TestAdapter.mock(':method' => 'GET', ':path' => '/')

    app.render(req)
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
end
