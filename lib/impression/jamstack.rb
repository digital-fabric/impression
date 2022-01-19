# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'modulation'
require 'papercraft'

require_relative './resource'
require_relative './file_tree'

module Impression

  # `Jamstack` implements a resource that maps to a Jamstack app directory.
  class Jamstack < FileTree
    def initialize(**props)
      super
      @layouts = {}
    end

    private

    # Renders a file response for the given request and the given path info.
    #
    # @param req [Qeweney::Request] request
    # @param path_info [Hash] path info
    # @return [void]
    def render_file(req, path_info)
      case path_info[:ext]
      when '.rb'
        render_papercraft_module(req, path_info[:path])
      when '.md'
        render_markdown_file(req, path_info[:path])
      else
        req.serve_file(path_info[:path])
      end
    end

    # Renders a Papercraft module. The module is loaded using Modulation.
    #
    # @param req [Qeweney::Request] reqest
    # @param path [String] file path
    # @return [void]
    def render_papercraft_module(req, path)
      mod = import path

      html = H(mod).render
      req.respond(html, 'Content-Type' => Qeweney::MimeTypes[:html])
    end

    # Renders a markdown file using a layout.
    #
    # @param req [Qeweney::Request] reqest
    # @param path [String] file path
    # @return [void]
    def render_markdown_file(req, path)
      attributes, markdown = parse_markdown_file(path)

      layout = get_layout(attributes[:layout])

      html = layout.render(**attributes) { emit_markdown markdown }
      req.respond(html, 'Content-Type' => Qeweney::MimeTypes[:html])
    end

    # Returns a layout component based on the given name. The given name
    # defaults to 'default' if nil.
    #
    # @param layout [String, nil] layout name
    # @return [Papercraft::Component] layout component
    def get_layout(layout)
      layout ||= 'default'
      path = File.join(@directory, "_layouts/#{layout}.rb")
      raise "Layout not found #{path}" unless File.file?(path)
      
      import path
    end

    MARKDOWN_PAGE_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze
  
    # Parses the markdown file at the given path.
    #
    # @param path [String] file path
    # @return [Array] an tuple containing properties<Hash>, contents<String>
    def parse_markdown_file(path)
      data = IO.read(path) || ''
      if (m = data.match(MARKDOWN_PAGE_REGEXP))
        front_matter = m[1]

        [symbolize_keys(YAML.load(front_matter)), m.post_match]
      else
        [{}, data]
      end
    end

    # Converts a hash with string keys to one with symbol keys.
    #
    # @param hash [Hash] input hash
    # @return [Hash] output hash
    def symbolize_keys(hash)
      hash.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
    end

    # Returns the supported path extensions used for searching for files based
    # on pretty URLs.
    #
    # @return [Array] list of supported path extensions
    def supported_path_extensions
      [:html, :rb, :md]
    end
  end
end
