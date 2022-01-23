require 'papercraft'

export_default Papercraft.html { |**props|
  html5 {
    head {
      title props[:title]
    }
    body {
      emit_yield **props
    }
  }
}