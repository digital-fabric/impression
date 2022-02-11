# frozen_string_literal: true

layout = import('./_layouts/default')

export_default layout.apply(title: 'Foo title') {
  h1 'foo'
}
