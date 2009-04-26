gemspec = Gem::Specification.new do |s|
  s.name = 'xmlnuts'
  s.version = '0.2.5'
  s.date = '2009-04-26'
  s.authors = ['Igor Gunko']
  s.email = 'tekmon@gmail.com'
  s.summary = 'Making XML <-> Ruby binding easy'
  s.description = <<-EOS
    XmlNuts is an XML to Ruby and back again mapping library.
  EOS
  s.homepage = 'http://github.com/pipa/xmlnuts'
  s.rubygems_version = '1.3.1'

  s.require_paths = %w(lib)

  s.files = %w(
    README.rdoc MIT-LICENSE Rakefile
    lib/xmlnuts.rb
    lib/pipa-xmlnuts.rb
    lib/xmlnuts/nuts.rb
    lib/xmlnuts/mappings.rb
    lib/xmlnuts/converters.rb
    lib/xmlnuts/backend.rb
    lib/xmlnuts/rexml.rb
  )

  s.test_files = %w(
    test/parsing_test.rb
  )

  s.has_rdoc = true
  s.rdoc_options = %w(--line-numbers --main README.rdoc)
  s.extra_rdoc_files = %w(README.rdoc MIT-LICENSE)

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency('thoughtbot-shoulda', ['>= 2.0.6'])
    else
    end
  else
  end
end
