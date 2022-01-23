# frozen_string_literal: true

require 'fileutils'
require 'date'
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
        .map { |fn| get_path_info(File.join(dir, fn)) }# page_entry(fn, dir) }
        .sort_by { |i| i[:path] }
    end

    private

    DATE_REGEXP = /(\d{4}\-\d{2}\-\d{2})/.freeze
    FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze
    MD_EXT_REGEXP = /\.md$/.freeze
    PAGE_EXT_REGEXP = /^(.+)\.(md|html|rb)$/.freeze
    INDEX_PAGE_REGEXP = /^(.+)?\/index$/.freeze
    YAML_OPTS = {
      permitted_classes: [Date]
    }.freeze

    # Returns the path info for the given file path.
    #
    # @param path [String] file path
    # @return [Hash] path info
    def file_info(path)
      info = super
      case info[:ext]
      when '.md'
        atts, content = parse_markdown_file(path)
        info = info.merge(atts)
        info[:html_content] = Papercraft.markdown(content)
      when '.rb'
        info[:module] = import(path)
      end
      if (m = path.match(DATE_REGEXP))
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
        relative_path = m[1] || '/'
      end
      relative_path == '/' ? absolute_path : File.join(absolute_path, relative_path)
    end

    # Renders a file response for the given request and the given path info.
    #
    # @param req [Qeweney::Request] request
    # @param path_info [Hash] path info
    # @return [void]
    def render_file(req, path_info)
      case path_info[:ext]
      when '.rb'
        render_papercraft_module(req, path_info)
      when '.md'
        render_markdown_file(req, path_info)
      else
        req.serve_file(path_info[:path])
      end
    end

    # Renders a Papercraft module. The module is loaded using Modulation.
    #
    # @param req [Qeweney::Request] reqest
    # @param path_info [Hash] path info
    # @return [void]
    def render_papercraft_module(req, path_info)
      template = Papercraft.html(path_info[:module])
      body = template.render(request: req, resource: self)
      req.respond(body, 'Content-Type' => template.mime_type)
    end

    # Renders a markdown file using a layout.
    #
    # @param req [Qeweney::Request] reqest
    # @param path_info [Hash] path info
    # @return [void]
    def render_markdown_file(req, path_info)
      layout = get_layout(path_info[:layout])

      html = layout.render(request: req, resource: self, **path_info) {
        emit path_info[:html_content]
      }
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
      content = IO.read(path) || ''
      atts = {}

      # Parse date from file name
      if (m = path.match(DATE_REGEXP))
        atts[:date] ||= Date.parse(m[1])
      end

      if (m = content.match(FRONT_MATTER_REGEXP))
        front_matter = m[1]
        content = m.post_match
        
        yaml = YAML.load(front_matter, **YAML_OPTS)
        yaml.each_with_object(atts) do |(k, v), h|
          h[k.to_sym] = v
        end
      end
        
      [atts, content]
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
