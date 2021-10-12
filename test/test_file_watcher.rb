# frozen_string_literal: true

require_relative 'helper'
require 'fileutils'

class FileWatcherTest < MiniTest::Test
  def setup
    @tmp_path = File.expand_path('../tmp', __dir__)
    FileUtils.mkdir(@tmp_path)
  end

  def teardown
    FileUtils.rm_rf(@tmp_path)
  end

  def test_watcher
    watcher = Impression::FileWatcher.new(@tmp_path)
    buffer = []
    spin do
      watcher.each { |kind, path| buffer << [kind, path] }
    end

    assert_equal [], buffer
    file_path = File.join(@tmp_path, 'foo')
    IO.write(file_path, 'bar')

    sleep 0.01
    assert_equal [[:create, file_path]], buffer

    buffer.clear
    FileUtils.rm(file_path)

    sleep 0.01
    assert_equal [[:delete, file_path]], buffer
  end
end
