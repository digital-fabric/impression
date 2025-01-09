# frozen_string_literal: true

require 'fileutils'
require_relative './resource'

module Impression

  # The `RackApp` class represents Rack apps as resources.
  class RackApp < Resource
    def initialize(app: nil, **props, &block)
      raise "No Rack app given" unless app || block

      # We pass nil as the block, otherwise the block will pass to
      # Resource#initialize, which will cause #call to be overidden.
      super(**props, &nil) 
      @handler = RackAdapter.run(app || block)
    end

    def call(req)
      if @path != '/'
        req.rewrite!(@path, '/')
      end
      @handler.(req)
    end
  end

  module RackAdapter
    class << self
      def run(app)
        ->(req) { respond(req, app.(env(req))) }
      end

      def load(path)
        src = IO.read(path)
        instance_eval(src, path, 1)
      end

      def env(request)
        Qeweney.rack_env_from_request(request)
      end

      def respond(request, (status_code, headers, body))
        headers[':status'] = status_code.to_s

        content =
          if body.respond_to?(:to_path)
            File.open(body.to_path, 'rb') { |f| f.read }
          else
            body.first
          end

        request.respond(content, headers)
      end
    end
  end
  
end
