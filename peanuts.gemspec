gemspec = Gem::Specification.new do |s|
  s.name = 'peanuts'
  s.version = '2.0.0'
  s.date = '2009-09-24'
  s.authors = ['Igor Gunko']
  s.email = 'tekmon@gmail.com'
  s.summary = 'Making XML <-> Ruby binding easy'
  s.description = <<-EOS
    Peanuts is an XML to Ruby and back again mapping library.
  EOS
  s.homepage = 'http://github.com/omg/peanuts'
  s.rubygems_version = '1.3.1'

  s.require_paths = %w(lib)

  s.files = %w(
    README.rdoc MIT-LICENSE Rakefile
    lib/peanuts.rb
    lib/omg-peanuts.rb
    lib/peanuts/nuts.rb
    lib/peanuts/mappings.rb
    lib/peanuts/converters.rb
    lib/peanuts/mapper.rb
    lib/peanuts/xml.rb
    lib/peanuts/xml/reader.rb
    lib/peanuts/xml/libxml.rb
  )

  s.test_files = %w(
    test/parsing_test.rb
  )

  s.has_rdoc = true
  s.rdoc_options = %w(--line-numbers --main README.rdoc)
  s.extra_rdoc_files = %w(README.rdoc MIT-LICENSE)

  s.add_dependency('libxml-ruby', [">= 1.1.3"])

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
