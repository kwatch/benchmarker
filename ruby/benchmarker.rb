# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

###
### benchmarker.rb - benchmark library
###
### ex (example.rb).
###
###    require 'benchmarker'
###
###    n = (ARGV[0] || 10000).to_i
###    nums = (1..100).to_a
###
###    bm = Benchmarker.new(:width=>30, :loop=>n, :verbose=>true)
###    print bm.platform, "\n"
###
###    bm.repeat(5, :extra=>1) do    # you can omit repeat() if no need to repeat
###
###      bm.bench("Enumerable#each & '+='") do
###        total = 0
###        nums.each {|n| total += n }
###        total
###      end
###
###      bm.bench("Enumerable#inject") do
###        total = nums.inject(0) {|t, n| t += n }
###      end
###
###      bm.bench("while-stmt") do
###        total = 0
###        i, len = 0, nums.length
###        while i < len
###          total += nums[i]
###          i += 1
###        end
###        total
###      end
###
###    end
###
###    puts bm.stats()   # or bm.stats(:compensate=>-100.0)
###    ### or
###    # puts bm.ranking
###    # puts bm.matrix
###
###
### output example:
###
###    $ ruby example.rb 2>/dev/null   # or 'ruby example.rb' to view details
###    ## RUBY_PLATFORM:      x86_64-darwin10.4.0
###    ## RUBY_ENGINE:        ruby
###    ## RUBY_VERSION:       1.9.2
###    ## RUBY_PATCHLEVEL:    0
###    ## RUBY_RELEASE_DATE:  2010-08-18
###
###    ## Average (7-2*1)                  user       sys     total      real
###    Enumerable#each & '+='            0.1420    0.0000    0.1420    0.1469
###    Enumerable#inject                 0.1760    0.0000    0.1760    0.1797
###    while-stmt                        0.0740    0.0000    0.0740    0.0811
###
###    ## Ranking                          real  ratio
###    while-stmt                        0.0811 (100.0) ********************
###    Enumerable#each & '+='            0.1469 ( 55.2) ***********
###    Enumerable#inject                 0.1797 ( 45.1) *********
###
###    ## Matrix                           real   [01]   [02]   [03]
###    [01] while-stmt                   0.0811  100.0  181.2  221.6
###    [02] Enumerable#each & '+='       0.1469   55.2  100.0  122.3
###    [03] Enumerable#inject            0.1797   45.1   81.8  100.0
###
module Benchmarker


  VERSION = "$Release: 0.0.0 $".split(/ /)[1]


  class Result


    def initialize(label, user=nil, sys=nil, real=nil)
      @label, @user, @sys, @real = label, user, sys, real
    end


    attr_accessor :label, :user, :sys, :real


    def total
      @user + @sys
    end


    def self.average(results)
      label = nil
      user = sys = real = 0.0
      results.each do |r|
        (label ||= r.label) == r.label  or
          raise "*** assertion: #{label.inspect} == #{r.label.inspect}: failed."
        user += r.user
        sys  += r.sys
        real += r.real
      end
      n = results.length
      return self.new(label, user/n, sys/n, real/n)
    end


  end



  class Reporter


    DEFAULTS = {
      :out     => $stdout,
      :width   => 30,
      :fmt     => "%9.4f",
      :header  => " %9s %9s %9s %9s" % ['user', 'sys', 'total', 'real'],
      :verbose => true,
      :verbose_out => $stderr,
    }


    def initialize(opts={})
      opts = DEFAULTS.merge(opts)
      @out, @width, @fmt, @header, @verbose, @verbose_out = \
        opts.values_at(:out, :width, :fmt, :header, :verbose, :verbose_out)
      @verbose_out = '' unless @verbose
    end


    attr_accessor :out, :width, :fmt, :header, :verbose, :verbose_out


    def start_verbose_region
      @__out = @out
      @out = @verbose_out
    end


    def stop_verbose_region
      @out = @__out
      @__out = nil
    end


    def <<(str)
      @out << str
    end


    def flush
      @out.flush if @out.respond_to?(:flush)
      nil
    end


    def print_header(title)
      @out << ("%-#{@width}s" % "## #{title}") << @header << "\n"
      nil
    end


    def print_label(label)
      @out << "%-#{@width}s" % label[0, @width]
      flush()
      nil
    end


    def print_times(user, sys, real)
      total = user + sys
      [user, sys, total, real].each {|t| @out << " #{@fmt}" % t }
      @out << "\n"
      nil
    end


  end



  class Statistics


    DEFAULTS = {
      :key   => :real,
      :width => Reporter::DEFAULTS[:width],
      :fmt   => Reporter::DEFAULTS[:fmt],
      :sort  => true,
      :compensate => 0.0,
    }


    def initialize(opts={})
      @opts = DEFAULTS.merge(opts)
    end


    def ranking(results, opts={})
      key, width, fmt = @opts.merge(opts).values_at(:key, :width, :fmt)
      sb = ""
      sb << "%-#{width}s %9s  %5s\n" % ['## Ranking', key, 'ratio']
      base = nil
      results.sort_by {|r| r.__send__(key) }.each do |r|
        val = r.__send__(key)
        base ||= 100.0 * val
        percent = base / val
        sb << "%-#{width}s #{fmt} (%5.1f) " % [r.label[0, width], val, percent]
        sb << ( '*' * (percent / 5.0).to_i )
        sb << "\n"
      end
      return sb
    end


    def matrix(results, opts={})
      key, width, fmt, sort, compensate = \
        DEFAULTS.merge(opts).values_at(:key, :width, :fmt, :sort, :compensate)
      results = results.sort_by {|r| r.__send__(key) } if sort
      sb = ""
      sb << "%-#{width}s %9s" % ['## Matrix', key.to_s]
      width -= "[00] ".length
      (1..results.length).each {|n| sb << "   [%02d]" % n }
      sb << "\n"
      values = results.collect {|r| r.__send__(key) }
      results.each_with_index do |r, i|
        val = r.__send__(key)
        sb << "[%02d] %-#{width}s #{fmt}" % [i+1, r.label[0, width], val]
        values.each_with_index do |other, j|
          ratio = block_given? ? yield(val, other) : 100.0 * other / val
          sb << " %6.1f" % (ratio + compensate)
        end
        sb << "\n"
      end
      return sb
    end


  end



  class Runner


    DEFAULTS = {
      :loop   => 1,
    }


    def initialize(opts={})
      @loop, = DEFAULTS.merge(opts).values_at(:loop)
      @results = []
    end


    attr_accessor :results, :results_list, :loop, :reporter, :statistics


    def before
      if @header_title
        @reporter.print_header(@header_title)
        @header_title = nil
      end
      if @loop > 1 && ! @_dummy_result
        @_skip = true
        bench('(Empty loop)') do end
        @_skip = nil
        @_dummy_result = @results.pop
      end
    end
    protected :before


    def after
    end
    protected :after


    def bench(label)
      before() unless @_skip
      @reporter.print_label(label)
      loop = @loop
      GC.start
      pt1 = Process.times
      t1  = Time.now
      loop == 1 ? yield : loop.times { yield }
      t2  = Time.now
      pt2 = Process.times
      user, sys, real = pt2.utime - pt1.utime, pt2.stime - pt1.stime, t2 - t1
      if (r = @_dummy_result)
        user -= r.user
        sys  -= r.sys
        real -= r.real
      end
      @reporter.print_times(user, sys, real)
      @results << RESULT.new(label, user, sys, real)
      after() unless @_skip
      @results[-1]
    end


    private


    def _reset(header_title)
      @header_title = header_title
      @_dummy_result = nil
      @results = []
    end


    def _delete_minmax_from(results, key, extra, fmt, label_fmt)
      sorted = results.sort_by {|r| r.__send__(key) }
      min_arr, max_arr = sorted[0...extra], sorted[-extra..-1].reverse
      label = results.first.label
      min_arr.zip(max_arr) do |min_r, max_r|
        min = min_r.__send__(key);  min_idx = results.index(min_r)
        max = max_r.__send__(key);  max_idx = results.index(max_r)
        @reporter << (label_fmt % label) \
                  << (fmt % min) << (" %9s" % "(#{min_idx+1})") \
                  << (fmt % max) << (" %9s" % "(#{max_idx+1})") << "\n"
        results.delete_at(min_idx)
        results.delete_at(max_idx)
      end
    end


    def _average_results(results_matrix, key, extra)
      if extra > 0
        fmt, label_fmt = " #{@reporter.fmt}", "%-#{@reporter.width}s"
        @reporter << (label_fmt % "## Remove min & max") \
                  << (" %9s %9s %9s %9s" % ['min', 'repeat', 'max', 'repeat']) << "\n"
        avg_results = results_matrix.collect {|results|
          results = results.dup
          _delete_minmax_from(results, key, extra, fmt, label_fmt)
          RESULT.average(results)
        }
        @reporter << "\n"
      else
        avg_results = results_matrix.collect {|results|
          RESULT.average(results)
        }
      end
      return avg_results
    end


    def _print_results(results, title)
      @reporter.print_header(title)
      results.each do |r|
        @reporter.print_label(r.label)
        @reporter.print_times(r.user, r.sys, r.real)
      end
    end


    public


    def repeat(n, opts={})
      opts = {:key=>:real, :extra=>0}.merge(opts)
      key, extra = opts.values_at(:key, :extra)
      @reporter.start_verbose_region
      @results_matrix = []
      (n + 2 * extra).times do |i|
        _reset("Repeat (#{i+1})")
        yield
        @results.each_with_index do |r, j|
          (@results_matrix[j] ||= []) << r
        end
        @reporter << "\n"
      end
      @results = _average_results(@results_matrix, key, extra)
      @reporter.stop_verbose_region
      _print_results(@results, "Average (#{n + 2*extra}-2*#{extra})")
    end


    def print(arg)
      @reporter << arg
    end


    def ranking(opts={})
      opts[:width] ||= @reporter.width
      return @statistics.ranking(@results, opts)
    end


    def matrix(opts={})
      opts[:width] ||= @reporter.width
      return @statistics.matrix(@results, opts)
    end


    def stats(opts={})
      sb = ""
      sb << "\n" << ranking(opts)
      sb << "\n" << matrix(opts)
      return sb
    end


    def platform
      sb = ""
      sb << "## RUBY_PLATFORM:      #{RUBY_PLATFORM}\n"
      sb << "## RUBY_ENGINE:        #{(RUBY_ENGINE rescue nil)}\n"
      sb << "## RUBY_VERSION:       #{RUBY_VERSION}\n"
      sb << "## RUBY_PATCHLEVEL:    #{RUBY_PATCHLEVEL}\n"
      sb << "## RUBY_RELEASE_DATE:  #{RUBY_RELEASE_DATE}\n"
      return sb
    end


  end



  RESULT     = Result
  REPORTER   = Reporter
  STATISTICS = Statistics
  RUNNER     = Runner

  #--
  #s =''
  #constants().grep(/^[A-Z0-9_]+$/).each do |const_name|
  #  next unless const_get(const_name).is_a?(Class)
  #  s << "def self.#{const_name}=(klass)
  #          remove_const :#{const_name}; const_set :#{const_name}, klass
  #        end;"
  #end
  #eval s
  #++


  def self.RESULT=(klass)
    remove_const :RESULT; const_set :RESULT, klass
  end


  def self.REPORTER=(klass)
    remove_const :REPORTER; const_set :REPORTER, klass
  end


  def self.STATISTICS=(klass)
    remove_const :STATISTICS; const_set :STATISTICS, klass
  end


  def self.RUNNER=(klass)
    remove_const :RUNNER; const_set :RUNNER, klass
  end



  ##
  ## create Runner object.
  ##
  ## options:
  ##   :width=>30     : width of benchmark label
  ##   :out=>$stdout  : stream to write result (I/O or String)
  ##   :verbose=>true : verbose mode
  ##   :fmt=>'%9.4f'  : format of benchmark time
  ##
  def self.new(opts={})
    runner = RUNNER.new(opts)
    runner.reporter = REPORTER.new(opts)
    runner.statistics = STATISTICS.new(opts)
    return runner
  end



end
