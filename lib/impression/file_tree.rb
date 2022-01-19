# frozen_string_literal: true

require 'fileutils'
require_relative './resource'

module Impression

  # `FileTree` implements a resource that maps to a static file hierarchy.
  class FileTree < Resource

    # Initializes a `FileTree` resource.
    #
    # @param directory [String] static directory path
    # @return [void]
    def initialize(directory:, **props)
      super(**props)
      @directory = directory
      @path_info_cache = {}
    end

    # Responds to a request.
    #
    # @param req [Qeweney::Request] request
    # @return [void]
    def call(req)
      path_info = get_path_info(req.resource_relative_path)
      render_from_path_info(req, path_info)
    end

    private

    # Renders a response from the given response kind and path.
    #
    # @param req [Qeweney::Request] request
    # @param kind [Symbol] path kind (`:not_found` or `:file`)
    # @param path [String, nil] file path
    def render_from_path_info(req, path_info)
      case path_info[:kind]
      when :not_found
        req.respond(nil, ':status' => Qeweney::Status::NOT_FOUND)
      when :file
        render_file(req, path_info)
      else
        raise "Invalid path info kind #{kind.inspect}"
      end
    end

    private

    # Renders a file response for the given request and the given path info.
    #
    # @param req [Qeweney::Request] request
    # @param path_info [Hash] path info
    # @return [void]
    def render_file(req, path_info)
      req.serve_file(path_info[:path])
    end

    # Returns the path info for the given relative path.
    #
    # @param path [String] relative path
    # @return [Hash] path info
    def get_path_info(path)
      @path_info_cache[path] ||= calculate_path_info(path)
    end

    # Calculates the path info for the given relative path.
    #
    # @param path [String] relative path
    # @param add_ext [bool] whether to add .html extension if not found
    # @return [Hash] path info
    def calculate_path_info(path)
      full_path = File.join(@directory, path)

      path_info(full_path) || search_path_info_with_extension(full_path) || { kind: :not_found }
    end

    # Returns the path info for the given path. If the path refers to a file,
    # returns a hash containing the file information. If the path refers to a
    # directory, performs a search for an index file using #directory_path_info.
    # Otherwise, returns nil.
    #
    # @param path [String] path
    # @return [Hash, nil] path info
    def path_info(path)
      stat = File.stat(path) rescue nil
      if !stat
        nil
      elsif stat.directory?
        return directory_path_info(path)
      else
        return { kind: :file, path: path, ext: File.extname(path) }
      end
    end

    # Calculates the path info for a directory. If an index file exists, its
    # path info is returned, otherwise, returns nil.
    #
    # @param path [String] directory path
    # @return [Hash, nil] path info
    def directory_path_info(path)
      search_path_info_with_extension(File.join(path, 'index'))
    end

    # Returns the supported path extensions for paths without extension.
    #
    # @return [Array] supported extensions
    def supported_path_extensions
      [:html]
    end

    # Searches for files with extensions for the given path.
    #
    # @param path [String] path
    # @return [Hash, nil] path info
    def search_path_info_with_extension(path)
      supported_path_extensions.each do |ext|
        info = path_info("#{path}.#{ext}")
        return info if info
      end
      nil
    end
  end
end
