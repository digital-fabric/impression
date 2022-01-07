# frozen_string_literal: true

module Impression
  class App < Resource
    def initialize(path: '/', **opts)
      super(path: path, **opts)
    end
  end
end
