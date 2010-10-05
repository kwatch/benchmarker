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
###    n = ($n || 10000).to_i
###
###    bm = Benchmarker.new(:width=>30, :loop=>n, :verbose=>false)
###    print bm.platform, "\n"
###
###    bm.repeat(5, :extra=>1) do    # you can omit repeat() if no need to repeat
###
###      nums = (1..100).to_a.shuffle
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
###    $ ruby example.rb
###    # RUBY_PLATFORM:      x86_64-darwin10.4.0
###    # RUBY_VERSION:       1.9.2
###    # RUBY_PATCHLEVEL:    0
###    # RUBY_RELEASE_DATE:  2010-08-18
###
###    # Average (7-2*1)                   user       sys     total      real
###    Enumerable#each & '+='            0.1420    0.0000    0.1420    0.1469
###    Enumerable#inject                 0.1760    0.0000    0.1760    0.1797
###    while-stmt                        0.0740    0.0000    0.0740    0.0811
###
###    # Ranking                           real  ratio
###    while-stmt                        0.0811 (100.0) ********************
###    Enumerable#each & '+='            0.1469 ( 55.2) ***********
###    Enumerable#inject                 0.1797 ( 45.1) *********
###
###    # Matrix                            real   [01]   [02]   [03]
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
      :fmt     => " %9.4f",
      :header  => " %9s %9s %9s %9s" % ['user', 'sys', 'total', 'real'],
      :verbose => true,
    }


    def initialize(opts={})
      opts = DEFAULTS.merge(opts)
      @out, @width, @fmt, @header, @verbose = \
        opts.values_at(:out, :width, :fmt, :header, :verbose)
      @in_verbose_region = false
    end


    attr_accessor :out, :width, :fmt, :header, :verbose


    def start_verbose_region
      @in_verbose_region = true
    end


    def stop_verbose_region
      @in_verbose_region = false
    end


    def should_skip?
      @verbose == false && @in_verbose_region
    end
    private :should_skip?


    def <<(str)
      return self if should_skip?
      @out << str
    end


    def flush
      return if should_skip?
      @out.flush if @out.respond_to?(:flush)
      nil
    end


    def print_header(title)
      return if should_skip?
      @out << ("# %-#{@width-2}s" % title) << @header << "\n"
      nil
    end


    def print_label(label)
      return if should_skip?
      @out << "%-#{@width}s" % label[0, @width]
      flush()
      nil
    end


    def print_times(user, sys, real)
      return if should_skip?
      total = user + sys
      [user, sys, total, real].each {|t| @out << (@fmt % t) }
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
      sb << "\# %-#{width-2}s %9s  %5s\n" % ['Ranking', key, 'ratio']
      base = nil
      results.sort_by {|r| r.__send__(key) }.each do |r|
        val = r.__send__(key)
        base ||= 100.0 * val
        percent = base / val
        sb << "%-#{width}s#{fmt} (%5.1f) " % [r.label[0, width], val, percent]
        sb << ('*' * (percent / 5.0).to_i )
        sb << "\n"
      end
      return sb
    end


    def matrix(results, opts={})
      key, width, fmt, sort, compensate = \
        DEFAULTS.merge(opts).values_at(:key, :width, :fmt, :sort, :compensate)
      results = results.sort_by {|r| r.__send__(key) } if sort
      width -= "[00] ".length
      sb = ""
      sb << ("# %-#{width}s    %9s" % ['Matrix', key.to_s])
      (1..results.length).each {|n| sb << "   [%02d]" % n }
      sb << "\n"
      values = results.collect {|r| r.__send__(key) }
      results.each_with_index do |r, i|
        val = r.__send__(key)
        sb << ("[%02d] %-#{width}s#{fmt}" % [i+1, r.label[0, width], val])
        values.each_with_index do |other, j|
          ratio = block_given? ? yield(val, other) : 100.0 * other / val
          sb << (" %6.1f" % (ratio + compensate))
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


    def initialize(options={})
      opts = DEFAULTS.merge(options)
      @loop = opts[:loop]
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


    def _reset(header_title)
      @header_title = header_title
      @_dummy_result = nil
      @results = []
    end
    private :_reset


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
      label_fmt = "%-#{@reporter.width}s"
      if extra > 0
        @reporter << (label_fmt % "# Remove min & max") \
                  << (" %9s %9s" % ['min', 'max']) << "\n"
      end
      @results = @results_matrix.collect do |results|
        results = results.dup
        if extra > 0
          label = results.first.label
          fmt = @reporter.fmt
          extra.times do
            min_r, max_r = results.minmax_by {|r| r.__send__(key) }
            results.delete(min_r); min = min_r.__send__(key)
            results.delete(max_r); max = max_r.__send__(key)
            @reporter << (label_fmt % label) << (fmt % min) << (fmt % max) << "\n"
          end
        end
        RESULT.average(results)
      end
      @reporter << "\n" if extra > 0
      @reporter.stop_verbose_region
      @reporter.print_header("Average (#{n + 2*extra}-2*#{extra})")
      @results.each do |r|
        @reporter.print_label(r.label)
        @reporter.print_times(r.user, r.sys, r.real)
      end
    end


    def print(arg)
      @reporter << arg
    end


    def stats(opts={})
      sb = ""
      sb << "\n" << ranking(opts)
      sb << "\n" << matrix(opts)
      return sb
    end


    def ranking(opts={})
      opts[:width] ||= @reporter.width
      return @statistics.ranking(@results, opts)
    end


    def matrix(opts={})
      opts[:width] ||= @reporter.width
      return @statistics.matrix(@results, opts)
    end


    def platform
      sb = ""
      sb << "# RUBY_PLATFORM:      #{RUBY_PLATFORM}\n"
      sb << "# RUBY_VERSION:       #{RUBY_VERSION}\n"
      sb << "# RUBY_PATCHLEVEL:    #{RUBY_PATCHLEVEL}\n"
      sb << "# RUBY_RELEASE_DATE:  #{RUBY_RELEASE_DATE}\n"
      return sb
    end


  end



  RESULT     = Result
  REPORTER   = Reporter
  STATISTICS = Statistics
  RUNNER     = Runner

  #--
  #s =''
  #constants().grep(/^[A-Z0-9_]+$/).each do |cname|
  #  s << "def self.#{cname}=(klass)
  #          remove_const :#{cname}; const_set :#{cname}, klass
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
  ##   :fmt=>' %9.4f' : format of benchmark time
  ##
  def self.new(opts={})
    runner = RUNNER.new(opts)
    runner.reporter = REPORTER.new(opts)
    runner.statistics = STATISTICS.new(opts)
    return runner
  end



end
