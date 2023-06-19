# frozen_string_literal: true

require 'json'

module Impression

  module RequestExtensions

    # Response extensions for `Qeweney::Request`
    module Responses

      TEXT_HEADERS = { 'Content-Type' => Qeweney::MimeTypes[:txt] }.freeze
      HTML_HEADERS = { 'Content-Type' => Qeweney::MimeTypes[:html] }.freeze
      JSON_HEADERS = { 'Content-Type' => Qeweney::MimeTypes[:json] }.freeze

      # Send an HTTP response with plain text content. The content type is set
      # to `text/plain`.
      #
      # @param text [String] response body
      # @param **headers [Hash] additional response headers
      def respond_text(text, **headers)
        headers = headers.empty? ? TEXT_HEADERS : headers.merge(TEXT_HEADERS)
        respond(text, headers)
      end

      # Send an HTTP response with HTML content. The content type is set to
      # `text/html`.
      #
      # @param html [String] response body
      # @param **headers [Hash] additional response headers
      def respond_html(html, **headers)
        headers = headers.empty? ? HTML_HEADERS : headers.merge(HTML_HEADERS)
        respond(html, headers)
      end

      # Send an JSON response. The given object is converted to JSON. The
      # content type is set to `application/json`.
      #
      # @param object [any] object to convert to JSON
      # @param **headers [Hash] additional response headers
      def respond_json(object, **headers)
        headers = headers.empty? ? JSON_HEADERS : headers.merge(JSON_HEADERS)
        respond(object.to_json, headers)
      end
    end

  end
end