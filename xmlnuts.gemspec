gemspec = Gem::Specification.new do |s|
  s.name = 'xmlnuts'
  s.version = '0.0.5'
  s.date = '2008-12-16'
  s.authors = ['Igor Gunko']
  s.email = 'tekmon@gmail.com'
  s.summary = 'Making xml<->ruby binding easy'
  s.description = <<-EOS
    XmlNuts is an XML to ruby object and back again mapping library.
  EOS
  s.homepage = 'http://github.com/pipa/xmlnuts'
  s.rubygems_version = '1.3.1'

  s.require_paths = %w(lib)

  s.files = %w(
    README MIT-LICENSE
    lib/xmlnuts.rb
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
  s.rdoc_options = %w(--line-numbers --inline-source --main README)
  s.extra_rdoc_files = %w(README MIT-LICENSE)

  # s.add_development_dependency('thoughtbot-shoulda', ['>= 2.0.6'])
end
