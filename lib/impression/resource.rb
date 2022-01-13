# frozen_string_literal: true

require 'fileutils'
require 'qeweney'

module Impression

  # The `Resource` class represents an abstract web resource. Resources are
  # organized in tree like structure, with the structure normally corresponding
  # to the URL path hierarchy. Other ways of organising resources, according to
  # other taxonomies, can be implemented as long as the resources implement the
  # same interface as the `Resource` class, which includes the following
  # methods:
  #
  # - `Resource#route` - returns the resource which should respond to the
  #   request.
  # - `Resource#respond` - responds to the request.
  #
  class Resource
    # Reference to the parent resource
    attr_reader :parent

    # The resource's path relative to its parent
    attr_reader :path

    # A hash mapping relative paths to child resources
    attr_reader :children

    # Initalizes a new resource instance.
    #
    # @param parent [Impression::Resource, nil] the parent resource (or nil)
    # @param path [String] the resource's relative path
    # @return [void]
    def initialize(parent: nil, path:)
      @parent = parent
      @path = normalize_route_path(path)
      @route_regexp = @path == '/' ? nil : /^#{@path}(\/.*)?$/.freeze
      @children = {}

      @parent&.add_child(self)
    end

    # Returns the resource's absolute path, according to its location in the
    # resource hierarchy.
    #
    # @return [String] absolute path
    def absolute_path
      @absoulte_path ||= File.join(@parent ? @parent.absolute_path : '/', @path)
    end

    # Iterates over the resource and any of its sub-resources, passing each to
    # the given block.
    # 
    # @return [Impression::Resource] self
    def each(&block)
      block.(self)
      @children.values.each { |c| c.each(&block) }
      self
    end

    # Adds a child reference to the children map.
    #
    # @param child [Impression::Resource] child resource
    # @return [Impression::Resource] self
    def add_child(child)
      @children[child.path] = child
      self
    end

    # Responds to the given request by rendering a 404 Not found response.
    #
    # @param req [Qeweney::Request] request
    # @return [void]
    def respond(req)
      req.respond(nil, ':status' => Qeweney::Status::NOT_FOUND)
    end

    FIRST_PATH_SEGMENT_REGEXP = /^(\/[^\/]+)\//.freeze

    # Routes the request by matching self and any children against the request
    # path, returning the target resource, or nil if there's no match.
    #
    # @param req [Qeweney::Request] request
    # @return [Impression::Resource, nil] target resource
    def route(req)
      case (relative_path = req.match_resource_path?(@route_regexp))
      when nil
        return nil
      when '/'
        return self
      else
        # naive case
        child = @children[relative_path]
        return child.route(req) if child

        if (m = relative_path.match(FIRST_PATH_SEGMENT_REGEXP))
          child = @children[m[1]]
          return child.route(req) if child
        end

        return self
      end
    end

    # Renders the resource and all of its sub-resources to static files.
    #
    # @param base_path [String] base path of target directory
    # @return [Impression::Resource] self
    def render_tree_to_static_files(base_path)
      each do |r|
        path = File.join(base_path, r.relative_static_file_path)
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) if !File.directory?(dir)
        File.open(path, 'w') { |f| r.render_to_file(f) }
      end
      self
    end

    # Converts the resource to a Proc, for use as a Qeweney app.
    #
    # @return [Proc] web app proc
    def to_proc
      ->(req) do
        resource = route(req) || self
        resource.respond(req)
      end
    end

    private

    SLASH_PREFIXED_PATH_REGEXP = /^\//.freeze

    # Normalizes the given path by ensuring it starts with a slash.
    #
    # @param path [String] path to normalize
    # @return [String] normalized path
    def normalize_route_path(path)
      path =~ SLASH_PREFIXED_PATH_REGEXP ? path : "/#{path}"
    end
  end
end
