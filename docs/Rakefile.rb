
desc "do all"
task :all => [:html, :md]

desc "generate html file"
task :html do
  sh "TAB=Python ruby ./md2 readme-python.mdx > python.html"
  sh "TAB=Ruby   ruby ./md2 readme-ruby.mdx   > ruby.html"
  sh "TAB=HOME   ruby ./md2 index.mdx         > index.html"
end

desc "generate markdown file"
task :md do
  sed  = 's/^(##*)\* /\1 /; /^```/,/^```/s/(\{\{\*|\*\}\})//g; /^ *\{\{=.*=\}\} *$/d'
  sh "sed -E '#{sed}' readme-python.mdx > readme-python.md"
  sh "sed -E '#{sed}' readme-ruby.mdx   > readme-ruby.md"
  sh "pbcopy < readme-python.md"
  #sh "pbcopy < readme-ruby.md"
end

desc "show diff betwwen *-python.md and *-python.mdx"
task :'md:diff:python' do
  base = "readme-python"
  sh "colordiff -u #{base}.mdx #{base}.md | lv" do end
end

desc "show diff betwwen *-ruby.md and *-ruby.mdx"
task :'md:diff:ruby' do
  base = "readme-ruby"
  sh "colordiff -u #{base}.mdx #{base}.md | lv" do end
end

desc "retrieve sample code"
task :retrieve do
  content = File.read("readme-ruby.mdx")
  content.scan(/^```ruby\n(.*?)^```/m) do
    before = $`
    srccode = $1
    srccode = srccode.gsub(/\{\{\*|\*\}\}/, '')
    srccode = srccode.gsub(/^ *\{\{=.*?=\}\}\n/, '')
    srccode = srccode.gsub(/\{\{=.*?=\}\}/, '')
    if before =~ /^File: (\S+)\n*\z/
      filename = $1
      File.write(filename, srccode)
      puts "filename: #{filename}"
    end
  end
end

desc "remove intermediate files"
task :clean do
  rm_f Dir.glob('ex?.rb') + Dir.glob('mybench.rb')
end
