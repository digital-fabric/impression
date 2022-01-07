# frozen_string_literal: true

module Impression
  class App
    def render(req)
      req.respond(nil, ':status' => Qeweney::Status::NOT_FOUND)
    end
  end
end
