require_relative './lib/impression/version'

Gem::Specification.new do |s|
  s.name        = 'impression'
  s.version     = Impression::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'Impression - a modern web framework for Ruby'
  s.author      = 'Sharon Rosner'
  s.email       = 'sharon@noteflakes.com'
  s.files       = `git ls-files`.split
  s.homepage    = 'http://github.com/digital-fabric/impression'
  s.metadata    = {
    "source_code_uri" => "https://github.com/digital-fabric/impression",
    "documentation_uri" => "https://www.rubydoc.info/gems/impression",
    "homepage_uri" => "https://github.com/digital-fabric/impression",
    "changelog_uri" => "https://github.com/digital-fabric/impression/blob/master/CHANGELOG.md"
  }
  s.rdoc_options = ["--title", "impression", "--main", "README.md"]
  s.extra_rdoc_files = ["README.md"]
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 3.3'

  s.add_runtime_dependency      'qeweney',    '~>0.21'
  s.add_runtime_dependency      'papercraft', '~>1.4'

  s.add_development_dependency  'modulation', '~>1.2'
  s.add_development_dependency  'rake',       '~>13.2.1'
  s.add_development_dependency  'minitest',   '~>5.25.4'
  s.add_development_dependency  'simplecov',  '~>0.22.0'
end
