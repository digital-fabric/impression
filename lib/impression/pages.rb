# frozen_string_literal: true

require 'kramdown'
require 'rouge'
require 'kramdown-parser-gfm'
require 'yaml'

require_relative './errors'

module Impression
  class Pages
    module RequestMethods
      def serve_page(pages)
        pages.serve(self)
      end
    end

    def initialize(base_path, opts = {})
      @base_path = base_path
      @opts = opts

      load
    end

    def load
      @map = {}
      Dir['**/*', base: @base_path].each do |path|
        next if path =~ /\/_.+/

        full_path = File.join(@base_path, path)
        next unless File.file?(full_path)

        page = Page.new(path, full_path, @opts)
        @map[page.relative_permalink] = page
      end
      @map['/'] = @map['/index']

      puts '* loaded pages' * 40
      p page_keys: @map.keys
    end
    alias_method :reload, :load

    def load_file(path)
      content = IO.read(path)
    end

    def serve(req)
      p serve: req.route_relative_path
      page = @map[req.route_relative_path]
      raise NotFoundError unless page

      req.respond(page.to_html, 'Content-Type' => 'text/html')
    end

    class Page
      def initialize(path, full_path, opts = {})
        @path = path
        @full_path = full_path
        @opts = opts
        read_page
      end
    
      PAGE_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze
    
      def read_page
        data = IO.read(@full_path) || ''
        if data =~ PAGE_REGEXP
          front_matter = Regexp.last_match(1)
          @attributes = YAML.load(front_matter)
          @content = Regexp.last_match.post_match
        else
          @attributes = {}
          @content = data
        end
      end

      def relative_permalink
        @relative_permalink = @attributes[:permalink] || path_without_extension
      end

      def path_without_extension
        "/#{File.basename(@path, File.extname(@path))}"
      end
    
      def title
        @attributes['title'] || title_from_content
      end
    
      TITLE_REGEXP = /^#\s+([^\n]+)/.freeze
    
      def title_from_content
        (@content =~ TITLE_REGEXP) && Regexp.last_match(1)
      end
    
      def status
        @attributes['status'] || Qeweney::Status::OK
      end
    
      def to_html
        @html ||= render_html
      end

      def kramdown_options
        {
          entity_output: :numeric,
          syntax_highlighter: :rouge,
          input: 'GFM'
        }
      end

      def render_html
        html_layout { Kramdown::Document.new(@content, **kramdown_options).to_html }
      end

      def html_layout
        <<~HTML
        <!DOCTYPE html>
        <html lang="en-us">
          <head>
            <title>#{title}</title>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="chrome=1">
            <meta name="HandheldFriendly" content="True">
            <meta name="MobileOptimized" content="320">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="referrer" content="no-referrer">
            <link rel="stylesheet" href="/assets/style.css">
          </head>
          <body>#{yield}</body>
        </html>
        HTML
      end
    end
  end
end

class Qeweney::Request
  include Impression::Pages::RequestMethods
end
