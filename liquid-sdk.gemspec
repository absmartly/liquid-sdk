require_relative 'lib/absmartly/liquid/version'

Gem::Specification.new do |spec|
  spec.name          = 'absmartly-liquid-sdk'
  spec.version       = ABsmartly::Liquid::VERSION
  spec.authors       = ['ABsmartly']
  spec.email         = ['support@absmartly.com']

  spec.summary       = 'ABsmartly SDK for Shopify Liquid'
  spec.description   = 'A/B testing SDK for Shopify Liquid templating language with server-side rendering support'
  spec.homepage      = 'https://github.com/absmartly/liquid-sdk'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/absmartly/liquid-sdk'
  spec.metadata['changelog_uri'] = 'https://github.com/absmartly/liquid-sdk/blob/main/CHANGELOG.md'

  spec.files = Dir['lib/**/*', 'examples/**/*', 'README.md', 'LICENSE', 'CHANGELOG.md'].select do |f|
    File.file?(f) && !f.match?(%r{\.DS_Store$})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'liquid', '~> 5.0'
  spec.add_dependency 'absmartly-sdk', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
