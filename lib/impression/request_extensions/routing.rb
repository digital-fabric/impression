# frozen_string_literal: true

module Impression
  
  # Extensions for `Qeweney::Request`
  module RequestExtensions

    # Routing extensions for `Qeweney::Request`
    module Routing

      # Matches a route regexp against the relative request path. The relative
      # request path is a separate string (stored in `@resource_relative_path`)
      # that is updated as routes are matched against it. The `route_regexp`
      # should be either `nil` for root routes (`/`) or a Regexp of the form
      # `/^#{route}(\/.*)?$/`. See also `Resource#initialize`.
      #
      # @param route_regexp [Regexp, nil] Route regexp to match against
      # @return [String, nil] The remainder of the path (relative to the route)
      def match_resource_path?(route_regexp)
        @resource_relative_path ||= path.dup

        return @resource_relative_path unless route_regexp

        # Simplified logic: no match returns nil, otherwise we set the relative path for 
        @resource_relative_path = match_resource_relative_path(
          @resource_relative_path, route_regexp
        )
      end

      # Returns the relative_path for the latest matched resource
      #
      # @return [String]
      def resource_relative_path
        @resource_relative_path ||= path
      end

      # Recalculates the relative_path from the given base path
      #
      # @param base_path [String] base path
      # @return [String] new relative path
      def recalc_resource_relative_path(base_path)
        @resource_relative_path = @resource_relative_path.gsub(
          /^#{base_path}/, ''
        )
      end

      private

      # Matches the given path against the given route regexp. If the path matches
      # the regexp, the relative path for the given route is returned. Otherwise,
      # this method returns `nil`.
      #
      # @param path [String] path to match
      # @param route_regexp [Regexp] route regexp to match against
      # @return [String, nil] the relative path for the given route, or nil if no match.
      def match_resource_relative_path(path, route_regexp)
        match = path.match(route_regexp)
        match && (match[1] || '/')
      end
    end
  end
end