# frozen_string_literal: true

layout = import('./_layouts/default')

export_default layout.apply(title: 'Foobar') { |resource:, request:, **props|
  h1 request.query[:q]
  resource.page_list('/articles').each do |i|
    a i[:title], href: i[:url]
  end
}
