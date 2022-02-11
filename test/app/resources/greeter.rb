# frozen_string_literal: true

export :resource

def resource
  Impression.resource { |req|
    req.respond("Hello, #{req.query[:name]}!", 'Content-Type' => 'text/plain')
  }
end
