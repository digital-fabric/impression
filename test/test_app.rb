# frozen_string_literal: true

require_relative 'helper'
require 'qeweney/test_adapter'

class AppTest < MiniTest::Test
  def test_empty_app
    app = Impression::App.new
    req = Qeweney::TestAdapter.mock(':method' => 'GET', ':path' => '/')

    app.render(req)
    assert_equal Qeweney::Status::NOT_FOUND, req.adapter.status
  end
end
