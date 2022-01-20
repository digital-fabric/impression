# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'date'
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

    # Returns a list of pages found in the given directory (relative to the base
    # directory). Each entry containins the absolute file path, the pretty URL,
    # the possible date parsed from the file name, and any other front matter
    # attributes (for .md files). This method will detect only pages with the
    # extensions .html, .md, .rb. The returned entries are sorted by file path.
    #
    # @param dir [String] relative directory
    # @return [Array<Hash>] array of page entries
    def page_list(dir)
      base = File.join(@directory, dir)
      Dir.glob('*.{html,md}', base: base)
        .map { |fn| page_entry(fn, dir) }
        .sort_by { |i| i[:path] }
    end

    private

    DATE_REGEXP = /^(\d{4}\-\d{2}\-\d{2})/.freeze
    MARKDOWN_PAGE_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze
    MD_EXT_REGEXP = /\.md$/.freeze
    PAGE_EXT_REGEXP = /^(.+)\.(md|html|rb)$/.freeze
    INDEX_PAGE_REGEXP = /^(.+)\/index$/.freeze

    # Returns a page entry for the given file.
    #
    # @param fn [String] file name
    # @param dir [String] relative directory
    # @return [Hash] page entry
    def page_entry(fn, dir)
      relative_path = File.join(dir, fn)
      absolute_path = File.join(@directory, relative_path)
      info = {
        path: absolute_path,
        url: pretty_url(relative_path)
      }
      if fn =~ MD_EXT_REGEXP
        atts, _ = parse_markdown_file(absolute_path)
        info.merge!(atts)
      end

      if (m = fn.match(DATE_REGEXP))
        info[:date] ||= Date.parse(m[1])
      end

      info
    end

    # Returns the pretty URL for the given relative path. For pages, the
    # extension is removed. For index pages, the index suffix is removed.
    #
    # @param relative_path [String] relative path
    # @return [String] pretty URL
    def pretty_url(relative_path)
      if (m = relative_path.match(PAGE_EXT_REGEXP))
        relative_path = m[1]
      end
      if (m = relative_path.match(INDEX_PAGE_REGEXP))
        relative_path = m[1]
      end
      File.join(absolute_path, relative_path)
    end

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

      html = H(mod).render(request: req, resource: self)
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

      html = layout.render(request: req, resource: self, **attributes) { emit_markdown markdown }
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
  
    # Parses the markdown file at the given path.
    #
    # @param path [String] file path
    # @return [Array] an tuple containing properties<Hash>, contents<String>
    def parse_markdown_file(path)
      data = IO.read(path) || ''
      atts = {}

      # Parse date from file name
      if (m = path.match(DATE_REGEXP))
        atts[:date] ||= Date.parse(m[1])
      end

      if (m = data.match(MARKDOWN_PAGE_REGEXP))
        front_matter = m[1]
        data = m.post_match
        
        YAML.load(front_matter).each_with_object(atts) do |(k, v), h|
          h[k.to_sym] = v
        end
      end
        
      [atts, data]
    end

    # Converts a hash with string keys to one with symbol keys.
    #
    # @param hash [Hash] input hash
    # @return [Hash] output hash
    def symbolize_keys(hash)
      
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
