# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "sklik-api"
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ondrej Bartas"]
  s.date = "2013-06-23"
  s.description = "Sklik advertising PPC api for creating campaigns and updating them when they runs"
  s.email = "ondrej@bartas.cz"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.markdown"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "LICENSE.txt",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "config/access.rb.example",
    "lib/sklik-api.rb",
    "lib/sklik-api/access.rb",
    "lib/sklik-api/campaign.rb",
    "lib/sklik-api/campaign_parts/adgroup.rb",
    "lib/sklik-api/campaign_parts/adtext.rb",
    "lib/sklik-api/campaign_parts/keyword.rb",
    "lib/sklik-api/client.rb",
    "lib/sklik-api/connection.rb",
    "lib/sklik-api/exceptions.rb",
    "lib/sklik-api/sklik_object.rb",
    "lib/sklik-api/xmlrpc_setup.rb",
    "sklik-api.gemspec",
    "test/fake_web.rb",
    "test/helper.rb",
    "test/integration/adgroup_test.rb",
    "test/integration/adtext_test.rb",
    "test/integration/campaign_test.rb",
    "test/integration/errors_test.rb",
    "test/integration/keyword_test.rb",
    "test/unit/adgroup_test.rb",
    "test/unit/campaign_test.rb",
    "test/unit/client_test.rb"
  ]
  s.homepage = "http://github.com/ondrejbartas/sklik-api"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Sklik advertising PPC api for creating campaigns"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<unicode>, [">= 0"])
      s.add_runtime_dependency(%q<text>, [">= 0"])
      s.add_runtime_dependency(%q<i18n>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<shoulda-context>, [">= 0"])
      s.add_development_dependency(%q<turn>, ["~> 0.8.2"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<ansi>, ["~> 1.2.5"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.3"])
      s.add_development_dependency(%q<fakeweb>, [">= 0"])
      s.add_development_dependency(%q<thin>, [">= 0"])
      s.add_development_dependency(%q<shotgun>, [">= 0"])
      s.add_development_dependency(%q<rcov>, ["= 0.9.10"])
    else
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<unicode>, [">= 0"])
      s.add_dependency(%q<text>, [">= 0"])
      s.add_dependency(%q<i18n>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<shoulda-context>, [">= 0"])
      s.add_dependency(%q<turn>, ["~> 0.8.2"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<ansi>, ["~> 1.2.5"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
      s.add_dependency(%q<fakeweb>, [">= 0"])
      s.add_dependency(%q<thin>, [">= 0"])
      s.add_dependency(%q<shotgun>, [">= 0"])
      s.add_dependency(%q<rcov>, ["= 0.9.10"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<unicode>, [">= 0"])
    s.add_dependency(%q<text>, [">= 0"])
    s.add_dependency(%q<i18n>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<shoulda-context>, [">= 0"])
    s.add_dependency(%q<turn>, ["~> 0.8.2"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<ansi>, ["~> 1.2.5"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
    s.add_dependency(%q<fakeweb>, [">= 0"])
    s.add_dependency(%q<thin>, [">= 0"])
    s.add_dependency(%q<shotgun>, [">= 0"])
    s.add_dependency(%q<rcov>, ["= 0.9.10"])
  end
end

