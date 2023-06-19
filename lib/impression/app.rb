# frozen_string_literal: true

require 'fileutils'
require 'date'
require 'yaml'
require 'modulation'
require 'papercraft'

require_relative './resource'
require_relative './file_tree'

module Impression

  # `App` implements a resource that maps to a generic app directory.
  class App < FileTree
    def initialize(**props)
      super
      @layouts = {}
      @file_info_loader = spin { run_file_info_loader }
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
      permitted_classes: [Date],
      symbolize_names: true
    }.freeze

    # Runs a file info loader handling incoming requests for file info. This
    # method is run in a fiber setup in #initialize.
    #
    # @return [void]
    def run_file_info_loader
      loop do
        peer, path = receive
        begin
          info = calculate_path_info(path)
          peer << info
        rescue Polyphony::BaseException
          raise
        rescue => e
          peer.raise(e)
        end
      end
    end

    def safe_calculate_path_info(path)
      @file_info_loader << [Fiber.current, path]
      receive
    end

    # Returns the path info for the given relative path.
    #
    # @param path [String] relative path
    # @return [Hash] path info
    def get_path_info(path)
      @path_info_cache[path] ||= safe_calculate_path_info(path)
    end

    # Returns complete file info for Markdown files
    #
    # @param info [Hash] file info
    # @param path [String] file path
    # @return [Hash] file info
    def file_info_md(info, path)
      atts, content = parse_markdown_file(path)
      info = info.merge(atts)
      info[:html_content] = Papercraft.markdown(content)
      info[:kind] = :markdown
      if !info[:date] && (m = path.match(DATE_REGEXP))
        info[:date] = Date.parse(m[1])
      end
      info
    end

    # Returns complete file info for Ruby files
    #
    # @param info [Hash] file info
    # @param path [String] file path
    # @return [Hash] file info
    def file_info_rb(info, path)
      info.merge(
        kind: :module,
        module: import(path)
      )
    end

    # Returns the path info for the given file path.
    #
    # @param path [String] file path
    # @return [Hash] path info
    def file_info(path)
      info = super
      case info[:ext]
      when '.md'
        file_info_md(info, path)
      when '.rb'
        file_info_rb(info, path)
      else
        info
      end
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

    # Renders a response according to the given path info.
    # 
    # @param req [Qeweney::Request] request
    # @param path_info [Hash] path info
    # @return [void]
    def render_from_path_info(req, path_info)
      case (kind = path_info[:kind])
      when :not_found
        mod_path_info = up_tree_resource_module_path_info(req, path_info)
        if mod_path_info
          render_module(req, mod_path_info)
        else
          req.respond(nil, ':status' => Qeweney::Status::NOT_FOUND)
        end
      when :module
        render_module(req, path_info)
      when :markdown
        render_markdown_file(req, path_info)
      when :file
        render_file(req, path_info)
      else
        raise "Invalid path info kind #{kind.inspect}"
      end
    end

    # Returns the path info for an up-tree resource module, or false if not
    # found. the :up_tree_resource_module_path_info KV can be either:
    # - nil (default): up tree module search has not been performed.
    # - false: no up tree module was found.
    # - module path info: up tree module info (subsequent requests will be
    #   directly routed to the module).
    #
    # @param req [Qeweney::Request] request
    # @param path_info [Hash] path info
    # @return [Hash, false] up-tree resource module path info
    def up_tree_resource_module_path_info(req, path_info)
      if path_info[:up_tree_resource_module_path_info].nil?
        if (mod_path_info = find_up_tree_resource_module(req, path_info))
          path_info[:up_tree_resource_module_path_info] = mod_path_info
          return mod_path_info;
        else
          path_info[:up_tree_resource_module_path_info] = false
          return false
        end
      end
      path_info[:up_tree_resource_module_path_info]
    end

    # Performs a recursive search for an up-tree resource module from the given
    # path info. If a resource module is found up the tree, its path_info is
    # returned, otherwise returns nil.
    # 
    # @param req [Qeweney::Request] request
    # @param path_info [Hash] path info
    # @return [Hash, nil] up-tree resource module path info
    def find_up_tree_resource_module(req, path_info)
      relative_path = req.resource_relative_path

      while relative_path != path
        up_tree_path = File.expand_path('..', relative_path)
        return nil if up_tree_path == relative_path

        up_tree_path_info = get_path_info(up_tree_path)
        case up_tree_path_info[:kind]
        when :not_found
          relative_path = up_tree_path
          next
        when :module
          return up_tree_path_info
        else
          return nil
        end
      end
      nil
    end

    # Renders a file response for the given request and the given path info,
    # according to the file type.
    #
    # @param req [Qeweney::Request] request
    # @param path_info [Hash] path info
    # @return [void]
    # def render_file(req, path_info)
    #   case path_info[:kind]
    #   else
    #     req.serve_file(path_info[:path])
    #   end
    # end

    # Renders a module. If the module is a Resource, it is mounted, and then the
    # request is rerouted from the new resource and rendered. If the module is a
    # Proc or a Papercraft::Template, it is rendered as such. Otherwise, an
    # error is raised.
    #
    # @param req [Qeweney::Request] request
    # @param path_info [Hash] path info
    # @return [void]
    def render_module(req, path_info)
      # p render_module: path_info
      case (mod = path_info[:module])
      when Module
        resource = mod.resource
        resource.remount(self, path_info[:url])
        # p path_info_url: path_info[:url], relative_path: req.resource_relative_path
        relative_url = path_info[:url].gsub(/^#{path}/, '')
        # p relative_url: relative_url
        req.recalc_resource_relative_path(relative_url)
        # p resource_relative_path: req.resource_relative_path
        resource.route(req).call(req)
      when Impression::Resource
        mod.remount(self, path_info[:url])
        req.recalc_resource_relative_path(path_info[:url])
        mod.route(req).call(req)
      when Proc, Papercraft::Template
        render_papercraft_module(req, mod)
      else
        raise "Unsupported module type #{mod.class}"
      end
    end

    # Renders a Papercraft module.
    #
    # @param mod [Module] Papercraft module
    # @param path_info [Hash] path info
    # @return [void]
    def render_papercraft_module(req, mod)
      template = Papercraft.html(mod)
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
      req.respond(html, 'Content-Type' => layout.mime_type)
    end

    # Returns a layout component based on the given name. The given name
    # defaults to 'default' if nil.
    #
    # @param layout [String, nil] layout name
    # @return [Papercraft::Template] layout component
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

        yaml = YAML.safe_load(front_matter, **YAML_OPTS)
        atts = atts.merge(yaml)
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
