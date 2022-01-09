# frozen_string_literal: true

require_relative 'helper'
require 'fileutils'

class FileWatcherTest < MiniTest::Test
  skip
  
  def setup
    @tmp_path = File.expand_path('../tmp', __dir__)
    FileUtils.mkdir(@tmp_path)
  end

  def teardown
    FileUtils.rm_rf(@tmp_path)
  end

  def test_directory_watcher
    watcher = Impression::FileWatcher.new(@tmp_path)
    file_path = File.join(@tmp_path, 'foo')

    buffer = []
    spin do
      watcher.each { |kind, path| buffer << [kind, path] }
    end

    assert_equal [], buffer

    # create
    buffer.clear
    IO.write(file_path, 'bar')
    sleep 0.01
    assert_equal [[:create, file_path]], buffer

    # modify
    buffer.clear
    IO.write(file_path, 'baz')
    sleep 0.01
    assert_equal [[:modify, file_path]], buffer

    # move
    tmp_file_path = File.join("/tmp/#{rand(1024)}")
    file2_path = File.join(@tmp_path, 'foo2')
    buffer.clear
    IO.write(tmp_file_path, '---')
    FileUtils.mv(tmp_file_path, file2_path)
    sleep 0.01
    assert_equal [[:moved_to, file2_path]], buffer

    # delete
    buffer.clear
    FileUtils.rm(file_path)
    sleep 0.01
    assert_equal [[:delete, file_path]], buffer
  end

  def test_recursive_directory_watcher
  end
end
