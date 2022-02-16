# frozen_string_literal: true

require 'polyphony'

require_relative './impression/request_extensions'
require_relative './impression/resource'
require_relative './impression/file_tree'
require_relative './impression/app'
require_relative './impression/rack_app'

# The Impression module contains convenience methods for creating resources.
module Impression

  # Creates a new `Impression::Resource` instance with the given parameters and
  # block.
  #
  # @param path [String] resource path (defaults to `"/"`)
  # @param **props [Hash] other resource properties
  # @param &block [Proc] optional block for overriding default request handler
  # @return [Impression::Resource] new resource
  def self.resource(path: '/', **props, &block)
    Resource.new(path: path, **props, &block)
  end

  # Creates a new `Impression::FileTree` instance with the given parameters.
  #
  # @param path [String] resource path (defaults to `"/"`)
  # @param **props [Hash] other resource properties
  # @param &block [Proc] optional block for overriding default request handler
  # @return [Impression::FileTree] new resource
  def self.file_tree(path: '/', **props, &block)
    FileTree.new(path: path, **props, &block)
  end

  # Creates a new `Impression::App` instance with the given parameters.
  #
  # @param path [String] resource path (defaults to `"/"`)
  # @param **props [Hash] other resource properties
  # @param &block [Proc] optional block for overriding default request handler
  # @return [Impression::App] new resource
  def self.app(path: '/', **props, &block)
    App.new(path: path, **props, &block)
  end

  # Creates a new `Impression::RackApp` instance with the given parameters.
  #
  # @param path [String] resource path (defaults to `"/"`)
  # @param **props [Hash] other resource properties
  # @param &block [Proc] Rack app proc (can also be passed using the `app:` parameter)
  # @return [Impression::RackApp] new resource
  def self.rack_app(path: '/', **props, &block)
    RackApp.new(path: path, **props, &block)
  end
end
