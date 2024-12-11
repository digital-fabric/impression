# frozen_string_literal: true

require 'fileutils'
# require 'tipi'
require_relative './resource'

module Impression

  # The `RackApp` class represents Rack apps as resources.
  class RackApp < Resource
    def initialize(app: nil, **props, &block)
      raise "No Rack app given" unless app || block

      # We pass nil as the block, otherwise the block will pass to
      # Resource#initialize, which will cause #call to be overidden.
      super(**props, &nil) 
      @handler = Tipi::RackAdapter.run(app || block)
    end

    def call(req)
      if @path != '/'
        req.rewrite!(@path, '/')
      end
      @handler.(req)
    end
  end
end
