require 'papercraft'

default = import('./default')

export_default default.apply { |**props|
  article {
    emit_yield
  }
}