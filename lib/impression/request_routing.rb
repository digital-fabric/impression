# frozen_string_literal: true

require 'fileutils'

module Impression
  module RequestRouting
    def impression_path_parts
      @impression_path_parts ||= path.split('/')[1..-1] || []
    end
  end
end
