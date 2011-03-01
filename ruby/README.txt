= Benchmarker README

* $Release: $
* $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
* $License: Public Domain $


== About

Benchmarker is a small utility to help benchmarking.

Features:

* Repeat benchmarks and calculate average times if you want
* Remove min and max results to exclude abnormal value.
* Remove loop times from each benchmark results if you want.
* Prints platform information automatically.
* Prints ranking graph and ratio matrix automatically.


== Install

    $ gem install benchmarker


== Quick Example


ex0.rb:

    require 'rubygems'
    require 'benchmarker'
    
    nums = (1..10000).to_a #.shuffle
    
    Benchmarker.new(:width=>24, :loop=>1000, :cycle=>5, :extra=>1) do |bm|
      # or Benchmarker.bm(24) do |bm| ... end
    
      bm.empty_task do
        nil
      end
    
      bm.task("each() & '+='") do      # or bm.report("...") do ... end
        total = 0
        nums.each {|n| total += n }
        total
      end
    
      bm.task("inject()") do
        total = nums.inject(0) {|t, n| t += n }
        total
      end
    
      bm.task("while statement") do
        i, len = 0, nums.length
        total = 0
        while i < len
          total += nums[i]
          i += 1
        end
      end
    
    end


Output:

    $ ruby ex0.rb 2>/dev/null
    benchmarker.rb:   release 0.1.0
    RUBY_VERSION:     1.9.2
    RUBY_PATCHLEVEL:  180
    RUBY_PLATFORM:    x86_64-darwin10.6.0
    
    ## Remove Min & Max            min     cycle       max     cycle
    each() & '+='               1.4091      (#5)    1.4330      (#3)
    inject()                    1.8125      (#5)    1.8357      (#7)
    while statement             0.7518      (#3)    0.7535      (#6)
    
    ## Average of 5 (=7-2*1)      user       sys     total      real
    each() & '+='               1.4020    0.0000    1.4020    1.4210
    inject()                    1.8020    0.0060    1.8080    1.8222
    while statement             0.7520    0.0000    0.7520    0.7524
    
    ## Ranking                    real
    while statement             0.7524 (100.0%) ********************
    each() & '+='               1.4210 ( 52.9%) ***********
    inject()                    1.8222 ( 41.3%) ********
    
    ## Matrix                     real     [01]     [02]     [03]
    [01] while statement        0.7524   100.0%   188.9%   242.2%
    [02] each() & '+='          1.4210    52.9%   100.0%   128.2%
    [03] inject()               1.8222    41.3%    78.0%   100.0%
