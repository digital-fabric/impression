# frozen_string_literal: true

require 'fileutils'

module Impression
  class Resource
    attr_reader :parent, :path, :children

    def initialize(parent: nil, path:)
      @parent = parent
      @path = path
      @children = {}

      @parent&.add_child(self)
    end

    def absolute_path
      File.join(@parent ? @parent.absolute_path : '/', @path)
    end

    def each(&block)
      block.(self)
      @children.values.each { |c| c.each(&block) }
    end

    def add_child(child)
      @children[child.path] = child
    end

    def render(req)
      req.respond(nil, ':status' => Qeweney::Status::NOT_FOUND)
    end

    def route(req)
      path_parts = req.impression_path_parts

      if path != '/'
        part = path_parts.shift
        return nil if part != @path
      end

      child_part = path_parts[0]
      return self unless child_part

      child = @children[child_part]
      return nil unless child
      
      child.route(req)
    end

    def render_tree_to_static_files(base_path)
      each do |r|
        path = File.join(base_path, r.relative_static_file_path)
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) if !File.directory?(dir)
        File.open(path, 'w') { |f| r.render_to_file(f) }
      end
    end

    def to_proc
      ->(req) do
        resource = route(req) || self
        resource.render(req)
      end
    end
  end
end
