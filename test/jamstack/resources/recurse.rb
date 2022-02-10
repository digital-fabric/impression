# frozen_string_literal: true

export :resource

def resource
  Impression.jamstack(
    directory: File.expand_path('..', __dir__)
  )
end
