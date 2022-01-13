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
    def respond(req)
      path_info = get_path_info(req.resource_relative_path)
      render_from_path_info(req, *path_info)
    end

    private

    # Renders a response from the given response kind and path.
    #
    # @param req [Qeweney::Request] request
    # @param kind [Symbol] path kind (`:not_found` or `:file`)
    # @param path [String, nil] file path
    def render_from_path_info(req, kind, path = nil)
      case kind
      when :not_found
        req.respond(nil, ':status' => Qeweney::Status::NOT_FOUND)
      when :file
        req.serve_file(path)
      else
        raise "Invalid path info kind #{kind.inspect}"
      end
    end

    # Returns the path info for the given relative path.
    #
    # @param path [String] relative path
    # @return [Array] path info (a tuple comprising kind and file path)
    def get_path_info(path)
      @path_info_cache[path] || calculate_path_info(path)
    end

    # Calculates the path info for the given relative path.
    #
    # @param path [String] relative path
    # @param add_html_ext [bool] whether to add .html extension if not found
    # @return [Array] path info
    def calculate_path_info(path, add_html_ext = true)
      full_path = File.join(@directory, path)

      stat = File.stat(full_path) rescue nil
      if !stat
        return add_html_ext ?
          calculate_path_info("#{path}.html", false) : [:not_found]
      elsif stat.directory?
        return calculate_directory_path_info(full_path)
      else
        return [:file, full_path]
      end
    end

    # Calculates the path info for a directory. If an `index.html` file exists,
    # its path info is returned, otherwise a `:not_found` path info is returned.
    #
    # @param path [String] directory path
    # @return [Array] path info
    def calculate_directory_path_info(path)
      index_path = File.join(path, 'index.html')
      if File.file?(index_path)
        [:file, index_path]
      else
        [:not_found]
      end
    end
  end
end
