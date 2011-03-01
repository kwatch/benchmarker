###
### benchmarks to measure library loading times.
###


require 'benchmarker'

targets = %w[cgi cgi/session erb tempfile tmpdir openssl
             logger pathname pstore time date2 uri drb fileutils
             rss rexml/document yaml psych json rubygems]

if RUBY_VERSION >= '1.9'
  targets.delete('date2')
elsif RUBY_VERSION < '1.9'
  targets.delete('psych')
  targets.delete('json')
end

loop = 10
cycle = 1   # or 5
Benchmarker.new(:loop=>loop, :cycle=>cycle, :extra=>1) do |bm|

  #bm.empty_task "(Empty) ruby" do
  bm.task "ruby" do
    system "ruby -e nil"
  end

  targets.each do |lib|
    bm.task "ruby -r #{lib}" do
      system "ruby -r #{lib} -e nil"
    end
  end

end
