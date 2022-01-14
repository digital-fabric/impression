# frozen_string_literal: true

require 'json'

module Impression
  
  module RequestExtensions

    # Response extensions for `Qeweney::Request`
    module Responses

      def respond_text(text, **headers)
        headers = headers.merge('Content-Type' => Qeweney::MimeTypes[:txt])
        respond(text, headers)
      end

      def respond_html(html, **headers)
        headers = headers.merge('Content-Type' => Qeweney::MimeTypes[:html])
        respond(html, headers)
      end

      def respond_json(object, **headers)
        headers = headers.merge('Content-Type' => Qeweney::MimeTypes[:json])
        respond(object.to_json, headers)
      end
    end

  end
end