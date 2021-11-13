###
### benchmarks to measure library loading times.
###


require 'benchmarker'

targets = %w[
  cgi cgi/session erb tempfile tmpdir openssl uri net/http
  optparse logger pathname pstore time date fileutils
  rss rexml/document yaml json rubygems
]

if RUBY_VERSION < '1.9'
  targets.delete('json')
elsif RUBY_VERSION >= '2.0'
  targets.delete('rubygems')
end

title = "library loading time"
Benchmarker.scope title, width: 22, loop: 10, iter: 5, extra: 1 do

  task nil do
    system "ruby -e nil"
  end

  targets.each do |lib|
    task "ruby -r #{lib}" do
      #system "ruby -r #{lib} -e nil"
      system "ruby -e \"require '#{lib}'\""
    end
  end

end
