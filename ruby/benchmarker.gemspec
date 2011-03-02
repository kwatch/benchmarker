#!/usr/bin/ruby

###
### $Release: $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require 'rubygems'

spec = Gem::Specification.new do |s|
  ## package information
  s.name        = "benchmarker"
  s.author      = "makoto kuwata"
  s.email       = "kwa(at)kuwata-lab.com"
  s.rubyforge_project = 'benchmarker'
  s.version     = "$Release: 0.1.0 $".split(/ /)[1]
  s.platform    = Gem::Platform::RUBY
  #s.homepage    = "http://www.kuwata-lab.com/benchmarker/"
  s.homepage    = "http://github.com/kwatch/benchmarker/"
  s.summary     = "a small utility for benchmarking"
  s.description = <<-'END'
Benchmarker is a small utility for benchmarking.

Quick Example (ex0.rb):

    require 'rubygems'
    require 'benchmarker'

    Benchmarker.new(:width=>20, :loop=>100*1000, :cycle=>5, :extra=>1) do |bm|
      range = 1..1000
      bm.task("each") do
        arr = []
        range.each {|n| arr << n }
      end
      bm.task("collect") do
        arr = range.collect {|n| n }
      end
      bm.task("inject") do
        arr = range.inject([]) {|a, n| a << n; a }
      end
    end
END

  ## files
  files = [
    'benchmarker.rb',
    'test/**/*',
    'examples/**/*',
    'REAMDE.txt', 'CHANGES.txt',
    'setup.rb', 'benchmarker.gemspec',
  ]
  s.files       = files.collect {|pat| Dir.glob(pat) }.flatten
  s.test_file   = 'test/benchmarker_test.rb'
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
