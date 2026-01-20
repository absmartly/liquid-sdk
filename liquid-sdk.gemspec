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

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    # Use git ls-files if in git repo, otherwise use Dir.glob
    if File.directory?('.git')
      `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
    else
      Dir.glob('**/*').reject { |f| File.directory?(f) || f.match(%r{\A(?:test|spec|features)/}) }
    end
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
