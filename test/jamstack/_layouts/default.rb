require 'papercraft'

export_default H { |**props|
  html5 {
    head {
      title props[:title]
    }
    body {
      emit_yield **props
    }
  }
}