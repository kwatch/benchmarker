#!/usr/bin/ruby

###
### $Release: $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name        = "benchmarker"
  s.author      = "kwatch"
  s.email       = "kwatch@gmail.com"
  #s.rubyforge_project = 'benchmarker'
  s.version     = "$Release: 0.0.0 $".split()[1]
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  #s.license     = 'CC-PDDC'  # public domain
  #s.homepage    = "https://github.com/kwatch/benchmarker/"
  s.homepage    = "https://kwatch.github.io/benchmarker/ruby.html"
  s.summary     = "pretty good benchmark library"
  s.description = <<-'END'
Benchmarker is a pretty good benchmark tool for Ruby.
Compared to `benchmark.rb` (standard library), Benchmarker has a lot of useful features.
See: https://kwatch.github.io/benchmarker/ruby.html
END

  ## files
  files = [
    'lib/benchmarker.rb',
    'test/**/*',
    #'examples/**/*',
    'README.md', 'CHANGES.md', 'Rakefile', 'MIT-LICENSE',
    'setup.rb', 'benchmarker.gemspec',
  ]
  s.files       = files.collect {|pat| Dir.glob(pat) }.flatten
  s.test_file   = 'test/benchmarker_test.rb'
  s.required_ruby_version = '>= 2.0'
  s.add_development_dependency "oktest", '~> 1.0'
end

# Quick fix for Ruby 1.8.3 / YAML bug   (thanks to Ross Bamford)
if (RUBY_VERSION == '1.8.3')
  def spec.to_yaml
    out = super
    out = '--- ' + out unless out =~ /^---/
    out
  end
end

spec
