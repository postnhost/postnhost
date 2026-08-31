$LOAD_PATH.push File.expand_path("lib", __dir__)

require_relative "lib/postnhost/version"

Gem::Specification.new do |spec|
  spec.name        = "postnhost"
  spec.version     = Postnhost::VERSION
  spec.authors     = ["Kirill Shevchenko", "Maxim Sova"]
  spec.email       = ["kirills167@gmail.com", "maximsova@gmail.com"]
  spec.homepage    = "https://postnhost.com"
  spec.summary     = "Open-source, SEO-ready CMS engine for Rails"
  spec.description = "PostnHost is a mountable Rails CMS engine with structured data, multilingual publishing, version history, and a rich-text editor."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/postnhost/postnhost"
  spec.metadata["changelog_uri"] = "https://github.com/postnhost/postnhost/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,public}/**/*", "CHANGELOG.md", "LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.4.0"

  spec.add_dependency "bcrypt"
  spec.add_dependency "carrierwave", ">= 3.0"
  spec.add_dependency "carrierwave-aws", "~> 1.6"
  spec.add_dependency "crass"
  spec.add_dependency "nokogiri"
  spec.add_dependency "openai"
  spec.add_dependency "pagy", "~> 43.0"
  spec.add_dependency "paper_trail", ">= 16.0"
  spec.add_dependency "rails", ">= 7.2"
  spec.add_dependency "rails-i18n"
  spec.add_dependency "rouge"
  spec.add_dependency "ruby-vips"
  spec.add_dependency "turbo-rails"
end
