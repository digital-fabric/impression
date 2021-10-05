# frozen_string_literal: true

require 'kramdown'
require 'rouge'
require 'kramdown-parser-gfm'
require 'yaml'
require 'rb-inotify'
require 'rubyoshka'

require_relative './errors'

module Impression
  class Pages
    module RequestMethods
      def serve_page(pages)
        pages.serve(self)
      end
    end

    def initialize(base_path, opts = {})
    p base_path: base_path
      @base_path = base_path
      @opts = opts
      @opts[:pages] = self

      load

      if opts[:auto_reload]
        start_automatic_reloader
      end
    end

    def start_automatic_reloader
      notifier = INotify::Notifier.new
      watched = {}
      @map.each_value do |entry|
        path = entry[:full_path]
        next if watched[path]

        notifier.watch(path, :modify, :delete_self) { |e| handle_changed_file(path) }
        watched[path] = true
      end
      notifier.watch(@base_path, :moved_to, :create) do |event|
        path = event.absolute_name
        if File.file?(path)
          notifier.watch(path, :modify, :delete_self) { |e| handle_changed_file(path) }
        end
        handle_changed_file(path)
      end
      @reloader = spin do
        notify_io = notifier.to_io
        loop do
          notify_io.wait_readable
          notifier.process
        end
      end
    end

    def handle_changed_file(full_path)
      p handle_changed_file: full_path
      if !File.file?(full_path)
        @map.reject! { |k, v| v[:full_path] == full_path }
        return
      end

      path = File.basename(full_path)
      page = Page.new(path, full_path, @opts)
      permalink = page.permalink
      @map[permalink] = { page: page, full_path: full_path }
      @map['/'] = @map[permalink] if permalink == '/index'
    end

    def load
      @map = {}
      Dir['**/*', base: @base_path].each do |path|
        next if path =~ /\/_.+/

        full_path = File.join(@base_path, path)
        next unless File.file?(full_path)

        page = Page.new(path, full_path, @opts)
        @map[page.permalink] = { page: page, full_path: full_path }
      end
      @map['/'] = @map['/index']
    end
    alias_method :reload, :load

    def prev_page(page)
      keys = @map.keys
      case idx = keys.index(page.permalink)
      when 0, nil
        nil
      else
        @map[keys[idx - 1]][:page]
      end
    end

    def next_page(page)
      keys = @map.keys
      case idx = keys.index(page.permalink)
      when keys.size - 1, nil
        nil
      else
        @map[keys[idx + 1]][:page]
      end
    end

    def load_file(path)
      content = IO.read(path)
    end

    def serve(req)
      entry = @map[req.route_relative_path]
      raise NotFoundError unless entry

      body = render_page(entry[:page])
      req.respond(body, 'Content-Type' => 'text/html')
    rescue NotFoundError => e
      req.respond('Not found.', ':status' => e.http_status)
    end
    alias_method :call, :serve

    def render_page(page)
      layout_proc(page.layout).().render(pages: self, page: page)
    end

    def layout_proc(layout)
      full_path = File.expand_path("../_layouts/#{layout}.rb", @base_path)
      instance_eval("->(&block) do; #{IO.read(full_path)}; end", full_path)
    end

    def select(selector)
      @map.inject([]) do |array, (permalink, entry)|
        array << entry[:page] if permalink =~ selector
        array
      end
    end
  end

  class Page
    attr_reader :attributes

    def initialize(path, full_path, opts = {})
      @path = path
      @full_path = full_path
      @opts = opts
      @kind = detect_page_kind(full_path)
      read_page
    end

    EXTNAME_REGEXP = /^\.(.+)$/.freeze

    def detect_page_kind(path)
      File.extname(path).match(EXTNAME_REGEXP)[1].to_sym
    end
  
    PAGE_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze
  
    def read_page
      data = IO.read(@full_path) || ''
      if data =~ PAGE_REGEXP
        front_matter = Regexp.last_match(1)
        @content_start_line = front_matter.lines.size + 2
        @attributes = YAML.load(front_matter)
        @content = Regexp.last_match.post_match
      else
        @attributes = {}
        @content_start_line = 1
        @content = data
      end
    end

    def permalink
      @permalink = @attributes[:permalink] || path_without_extension
    end

    def path_without_extension
      "/#{@path.delete_suffix(File.extname(@path))}"
    end
  
    def title
      @attributes['title'] || title_from_content
    end

    def prev_page
      @opts[:pages].prev_page(self)
    end

    def next_page
      @opts[:pages].next_page(self)
    end
  
    TITLE_REGEXP = /^#\s+([^\n]+)/.freeze
  
    def title_from_content
      (@content =~ TITLE_REGEXP) && Regexp.last_match(1)
    end
  
    def status
      @attributes['status'] || Qeweney::Status::OK
    end

    def layout
      layout = @attributes['layout'] || 'default'
    end
  
    def render
      case @kind
      when :md
        render_markdown
      when :rb
        render_rubyoshka
      else
        raise "Invalid page kind #{kind.inspect}"
      end
    end

    def render_markdown
      Kramdown::Document.new(@content, **kramdown_options).to_html
    end

    def kramdown_options
      {
        entity_output: :numeric,
        syntax_highlighter: :rouge,
        input: 'GFM',
        hard_wrap: false
      }
    end

    def render_rubyoshka
      proc = instance_eval("->(&block) do; #{@content}; end", @full_path, @content_start_line)
      proc.().render(page: self, pages: @opts[:pages])
    end
  end
end

class Qeweney::Request
  include Impression::Pages::RequestMethods
end
