# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2010-2021 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###


module Benchmarker


  VERSION = "$Release: 0.0.0 $".split()[1]


  OPTIONS = {}    # ex: {loop: 1000, iter: 10, extra: 2, inverse: true}

  def self.new(title=nil, **kwargs, &b)
    if block_given?()    # for backward compatibility
      return self.scope(title, **kwargs, &b)
    end
    #; [!s7y6x] overwrites existing options by command-line options.
    d = OPTIONS
    kwargs.update(OPTIONS)
    #; [!2zh7w] creates new Benchmark object wit options.
    bm = Benchmark.new(title: title, **kwargs)
    return bm
  end

  def self.scope(title=nil, **kwargs, &block)
    #; [!4f695] creates Benchmark object, define tasks, and run them.
    bm = self.new(title, **kwargs)
    bm.scope(&block)
    bm.run()
    return bm
  end


  class Benchmark

    def initialize(title: nil, width: 30, loop: 1, iter: 1, extra: 0, inverse: false, outfile: nil, quiet: false, sleep: nil, filter: nil)
      @title   = title
      @width   = width   || 30
      @loop    = loop    || 1
      @iter    = iter    || 1
      @extra   = extra   || 0
      @inverse = inverse || false
      @outfile = outfile
      @quiet   = quiet   || false
      @sleep   = sleep
      @filter  = filter
      if filter
        #; [!0mz0f] error when filter string is invalid format.
        filter =~ /^(task|tag)(!?=+)(.*)/  or
          raise ArgumentError.new("#{filter}: invalid filter.")
        #; [!xo7bq] error when filter operator is invalid.
        $2 == '=' || $2 == '!='  or
          raise ArgumentError.new("#{filter}: expected operator is '=' or '!='.")
      end
      @entries = []    # [[Task, Resutl]]
      @jdata   = {}
      @hooks   = {}    # {before: Proc, after: Proc, ...}
      @empty_task = nil
    end

    attr_reader :title, :width, :loop, :iter, :extra, :inverse, :outfile, :quiet, :sleep, :filter

    def clear()
      #; [!phqdn] clears benchmark result and JSON data.
      @entries.each {|_, result| result.clear() }
      @jdata = {}
      self
    end

    def scope(&block)
      #; [!wrjy0] creates wrapper object and yields block with it as self.
      #; [!6h24d] passes benchmark object as argument of block.
      scope = Scope.new(self)
      scope.instance_exec(self, &block)
      #; [!y0uwr] returns self.
      self
    end

    def define_empty_task(code=nil, &block)   # :nodoc:
      #; [!qzr1s] error when called more than once.
      @empty_task.nil?  or
        raise "cannot define empty task more than once."
      #; [!w66xp] creates empty task.
      @empty_task = TASK.new("(Empty)", code, &block)
      return @empty_task
    end

    def define_task(name, code=nil, tag: nil, &block)   # :nodoc:
      #; [!re6b8] creates new task.
      #; [!r8o0p] can take a tag.
      task = TASK.new(name, code, tag: tag, &block)
      @entries << [task, Result.new]
      return task
    end

    def define_hook(key, &block)
      #; [!2u53t] register proc object with symbol key.
      @hooks[key] = block
      self
    end

    def call_hook(key, *args)
      #; [!0to2s] calls hook with arguments.
      fn = @hooks[key]
      fn.call(*args) if fn
    end
    private :call_hook

    def run(warmup: false)
      #; [!0fo0l] runs benchmark tasks and reports result.
      report_environment()
      filter_tasks()
      #; [!2j4ks] calls 'before_all' hook.
      call_hook(:before_all)
      begin
        if warmup
          #; [!6h26u] runs preriminary round when `warmup: true` provided.
          _ignore_output { invoke_tasks() }
          clear()
        end
        invoke_tasks()
      #; [!w1rq7] calls 'after_all' hook even if error raised.
      ensure
        call_hook(:after_all)
      end
      ignore_skipped_tasks()
      report_minmax()
      report_average()
      report_stats()
      write_outfile()
      nil
    end

    private

    def _ignore_output(&b)
      #; [!wazs7] ignores output in block argument.
      require 'stringio'
      bkup, $stdout = $stdout, StringIO.new
      begin
        yield
      ensure
        $stdout = bkup
      end
    end

    def filter_tasks()
      #; [!g207d] do nothing when filter string is not provided.
      if @filter
        #; [!f1n1v] filters tasks by task name when filer string is 'task=...'.
        #; [!m79cf] filters tasks by tag value when filer string is 'tag=...'.
        @filter =~ /^(task|tag)(=|!=)(.*)/  or raise "** internal error"
        key = $1; op = $2; pattern = $3
        @entries = @entries.select {|task, _|
          val = key == 'tag' ? task.tag : task.name
          if val
            bool = [val].flatten.any? {|v| File.fnmatch(pattern, v, File::FNM_EXTGLOB) }
          else
            bool = false
          end
          #; [!0in0q] supports negative filter by '!=' operator.
          op == '!=' ? !bool : bool
        }
      end
      nil
    end

    def invoke_tasks()
      @jdata[:Results] = []
      #; [!c8yak] invokes tasks once if 'iter' option not specified.
      #; [!unond] invokes tasks multiple times if 'iter' option specified.
      #; [!wzvdb] invokes tasks 16 times if 'iter' is 10 and 'extra' is 3.
      n = @iter + 2 * @extra
      (1..n).each do |i|
        @jdata[:Results] << (rows = [])
        #; [!5axhl] prints result even on quiet mode if no 'iter' nor 'extra'.
        quiet = @quiet && n != 1
        #; [!yg9i7] prints result unless quiet mode.
        #; [!94916] suppresses result if quiet mode.
        heading = n == 1 ? "##" : "## (##{i})"
        puts "" unless quiet
        puts "%-#{@width}s %9s %9s %9s %9s" % [heading, 'user', 'sys', 'total', 'real'] unless quiet
        #; [!3hgos] invokes empty task at first if defined.
        if @empty_task
          print "%-#{@width}s " % @empty_task.name unless quiet
          $stdin.flush()                           unless quiet
          #call_hook(:before, nil, tag: nil)
          #begin
            empty_timeset = @empty_task.invoke(@loop)
          #ensure
          #  call_hook(:after, nil, tag: nil)
          #end
          t = empty_timeset
          s = "%9.4f %9.4f %9.4f %9.4f" % [t.user, t.sys, t.total, t.real]
          puts s unless quiet
          #; [!knjls] records result of empty loop into JSON data.
          rows << [@empty_task.name] + s.split().collect(&:to_f)
          Kernel.sleep @sleep if @sleep
        else
          empty_timeset = nil
        end
        #; [!xf84h] invokes all tasks.
        @entries.each do |task, result|
          print "%-#{@width}s " % task.name unless quiet
          $stdin.flush()                    unless quiet
          #; [!hbass] calls 'before' hook with task name and tag.
          call_hook(:before, task.name, tag: task.tag)
          #; [!6g36c] invokes task with validator if validator defined.
          begin
            timeset = task.invoke(@loop, &@hooks[:validate])
          #; [!fv4cv] skips task invocation if `skip_when()` called.
          rescue SkipTask => exc
            puts "   # Skipped (reason: #{exc.message})" unless quiet
            result.skipped = exc.message
            next
          #; [!7960c] calls 'after' hook with task name and tag even if error raised.
          ensure
            call_hook(:after, task.name, tag: task.tag)
          end
          #; [!513ok] subtract timeset of empty loop from timeset of each task.
          if empty_timeset
            timeset -= empty_timeset      unless task.has_code?
            timeset -= empty_timeset.div(100) if task.has_code?
          end
          t = timeset
          s = "%9.4f %9.4f %9.4f %9.4f" % [t.user, t.sys, t.total, t.real]
          puts s unless quiet
          result.add(timeset)
          #; [!ejxif] records result of each task into JSON data.
          rows << [task.name] + s.split().collect(&:to_f)
          #; [!vbhvz] sleeps N seconds after each task if `sleep` option specified.
          Kernel.sleep @sleep if @sleep
        end
      end
      nil
    end

    def ignore_skipped_tasks()
      #; [!5gpo7] removes skipped tasks and leaves other tasks.
      @entries = @entries.reject {|_, result| result.skipped? }
      nil
    end

    def report_environment()
      #; [!rx7nn] prints ruby version, platform, several options, and so on.
      s = "loop=#{@loop.inspect}, iter=#{@iter.inspect}, extra=#{@extra.inspect}"
      s += ", inverse=#{@inverse}" if @inverse
      kvs = [["title", @title], ["options", s]] + Misc.environment_info()
      puts kvs.collect {|k, v| "## %-16s %s\n" % ["#{k}:", v] }.join()
      @jdata[:Environment] = Hash.new(kvs)
      nil
    end

    def report_minmax()
      if @extra > 0
        rows = _remove_minmax()
        puts _render_minmax(rows)
      end
    end

    def _remove_minmax()
      #; [!uxe7e] removes best and worst results if 'extra' option specified.
      tuples = []
      @entries.each do |task, result|
        removed_list = result.remove_minmax(@extra)
        tuples << [task.name, removed_list]
      end
      #; [!is6ll] returns removed min and max data.
      rows = []
      tuples.each do |task_name, removed_list|
        removed_list.each_with_index do |(min_t, min_idx, max_t, max_idx), i|
          task_name = nil if i > 0
          min_t2 = ("%9.4f" % min_t).to_f
          max_t2 = ("%9.4f" % max_t).to_f
          rows << [task_name, min_t2, "(##{min_idx})", max_t2, "(##{max_idx})"]
        end
      end
      #; [!xwddz] sets removed best and worst results into JSON data.
      @jdata[:RemovedMinMax] = rows
      return rows
    end

    def _render_minmax(rows)
      #; [!p71ax] returns rendered string.
      buf = ["\n"]
      heading = "## Removed Min & Max"
      buf << "%-#{@width+4}s %5s %9s %9s %9s\n" % [heading, 'min', 'iter', 'max', 'iter']
      rows.each do |row|
        buf << "%-#{@width}s %9.4f %9s %9.4f %9s\n" % row
      end
      return buf.join()
    end

    def report_average()
      if @iter > 1 || @extra > 0
        rows = _calc_average()
        puts _render_average(rows)
      end
    end

    def _calc_average()
      #; [!qu29s] calculates average of real times for each task.
      rows = @entries.collect {|task, result|
        avg_timeset = result.calc_average()
        [task.name] + avg_timeset.to_a.collect {|x| ("%9.4f" % x).to_f }
      }
      #; [!jxf28] sets average results into JSON data.
      @jdata[:Average] = rows
      return rows
    end

    def _render_average(rows)
      #; [!j9wlv] returns rendered string.
      buf = ["\n"]
      heading = "## Average of #{@iter}"
      heading += " (=#{@iter + 2 * @extra}-2*#{@extra})" if @extra > 0
      buf << "%-#{@width+4}s %5s %9s %9s %9s\n" % [heading, 'user', 'sys', 'total', 'real']
      rows.each do |row|
        buf << "%-#{@width}s %9.4f %9.4f %9.4f %9.4f\n" % row
      end
      return buf.join()
    end

    def report_stats()
      #; [!0jn7d] sorts results by real sec.
      pairs = @entries.collect {|task, result|
        #real = @iter > 1 || @extra > 0 ? result.calc_average().real : result[0].real
        real = result.calc_average().real
        [task.name, real]
      }
      pairs = pairs.sort_by {|_, real| real }
      print _render_ranking(pairs)
      print _render_matrix(pairs)
    end

    def _render_ranking(pairs)
      #; [!2lu55] calculates ranking data and sets it into JSON data.
      rows = []
      base = nil
      pairs.each do |task_name, sec|
        base ||= sec
        percent = 100.0 * base / sec
        barchart = '*' * (percent / 5.0).round()   # max 20 chars (=100%)
        loop = @inverse == true ? (@loop || 1) : (@inverse || @loop || 1)
        rows << [task_name, ("%.4f" % sec).to_f, "%.1f%%" % percent,
                 "%.2f times/sec" % (loop / sec), barchart]
      end
      @jdata[:Ranking] = rows
      #; [!55x8r] returns rendered string of ranking.
      buf = ["\n"]
      heading = "## Ranking"
      if @inverse
        buf << "%-#{@width}s %9s%30s\n" % [heading, 'real', 'times/sec']
      else
        buf << "%-#{@width}s %9s\n"     % [heading, 'real']
      end
      rows.each do |task_name, sec, percent, inverse, barchart|
        s = @inverse ? "%20s" % inverse.split()[0] : barchart
        buf << "%-#{@width}s %9.4f (%6s) %s\n" % [task_name, sec, percent, s]
      end
      return buf.join()
    end

    def _render_matrix(pairs)
      #; [!2lu55] calculates ranking data and sets it into JSON data.
      rows = []
      pairs.each_with_index do |(task_name, sec), i|
        base = pairs[i][1]
        row = ["[#{i+1}] #{task_name}", ("%9.4f" % sec).to_f]
        pairs.each {|_, r| row << "%.1f%%" % (100.0 * r / base) }
        rows << row
      end
      @jdata[:Matrix] = rows
      #; [!rwfxu] returns rendered string of matrix.
      buf = ["\n"]
      heading = "## Matrix"
      s = "%-#{@width}s %9s" % [heading, 'real']
      (1..pairs.length).each {|i| s += " %8s" % "[#{i}]" }
      buf << "#{s}\n"
      rows.each do |task_name, real, *percents|
        s = "%-#{@width}s %9.4f" % [task_name, real]
        percents.each {|p| s += " %8s" % p }
        buf << "#{s}\n"
      end
      return buf.join()
    end

    def write_outfile()
      #; [!o8ah6] writes result data into JSON file if 'outfile' option specified.
      if @outfile
        filename = @outfile
        require 'json'
        jstr = JSON.pretty_generate(@jdata, indent: '  ', space: ' ')
        if filename == '-'
          $stdout.puts(jstr)
        else
          File.write(filename, jstr)
        end
        jstr
      end
    end

  end


  class Scope

    def initialize(bm=nil)
      @__bm = bm
    end

    def task(name, code=nil, binding=nil, tag: nil, &block)
      #; [!843ju] when code argument provided...
      if code
        #; [!bwfak] code argument and block argument are exclusive.
        ! block_given?()  or
          raise TaskError, "task(#{name.inspect}): cannot accept #{code.class} argument when block argument given."
        #; [!4dm9q] generates block argument if code argument passed.
        location = caller_locations(1, 1).first
        defcode  = "proc do #{(code+';') * 100} end"   # repeat code 100 times
        binding ||= ::TOPLEVEL_BINDING
        block = eval defcode, binding, location.path, location.lineno+1
      end
      #; [!kh7r9] define empty-loop task if name is nil.
      return @__bm.define_empty_task(code, &block) if name.nil?
      #; [!j6pmr] creates new task object.
      return @__bm.define_task(name, code, tag: tag, &block)
    end
    alias report task          # for compatibility with 'benchamrk.rb'

    def empty_task(code=nil, binding=nil, &block)
      #; [!ycoch] creates new empty-loop task object.
      return task(nil, code, binding, &block)
    end

    def skip_when(cond, reason)
      #; [!dva3z] raises SkipTask exception if cond is truthy.
      #; [!srlnu] do nothing if cond is falthy.
      raise SkipTask, reason if cond
    end

    def validate(&block)
      #; [!q2aev] defines validator.
      return @__bm.define_hook(:validate, &block)
    end

    def assert(expr, errmsg)
      #; [!a0c7e] do nothing if assertion succeeded.
      #; [!5vmbc] raises error if assertion failed.
      #; [!7vt5l] puts newline if assertion failed.
      return if expr
      puts ""
      raise ValidationFailed, errmsg
    rescue => exc
      #; [!mhw59] makes error backtrace compact.
      exc.backtrace.reject! {|x| x =~ /[\/\\:]benchmarker\.rb.*:/ }
      raise
    end

    def assert_eq(actual, expected, errmsg=nil)
      #; [!8m6bh] do nothing if ectual == expected.
      #; [!f9ey6] raises error unless actual == expected.
      return if actual == expected
      errmsg ||= "#{actual.inspect} == #{expected.inspect}: failed."
      assert false, errmsg
    end

    def before(&block)
      #; [!2ir4q] defines 'before' hook.
      @__bm.define_hook(:before, &block)
    end

    def after(&block)
      #; [!05up6] defines 'after' hook.
      @__bm.define_hook(:after, &block)
    end

    def before_all(&block)
      #; [!1oier] defines 'before_all' hook.
      @__bm.define_hook(:before_all, &block)
    end

    def after_all(&block)
      #; [!z7xop] defines 'after_all' hook.
      @__bm.define_hook(:after_all, &block)
    end

  end


  class SkipTask < StandardError
  end


  class ValidationFailed < StandardError
  end


  class TaskError < StandardError
  end


  class Task

    def initialize(name, code=nil, tag: nil, &block)
      @name  = name
      @code  = code
      @tag   = tag
      @block = block
    end

    attr_reader :name, :tag, :block

    def has_code?
      return !!@code
    end

    def invoke(loop=1)
      #; [!s2f6v] when task block is build from repeated code...
      if @code
        #; [!i2r8o] error when number of loop is less than 100.
        loop >= 100  or
          raise TaskError, "task(#{@name.inspect}): number of loop (=#{loop}) should be >= 100, but not."
        #; [!kzno6] error when number of loop is not a multiple of 100.
        loop % 100 == 0  or
          raise TaskError, "task(#{@name.inspect}): number of loop (=#{loop}) should be a multiple of 100, but not."
        #; [!gbukv] changes number of loop to 1/100.
        loop = loop / 100
      end
      #; [!frq25] kicks GC before calling task block.
      GC.start()
      #; [!tgql6] invokes block N times.
      block = @block
      t1 = Process.times
      start_t = Time.now
      while (loop -= 1) >= 0
        ret = block.call()
      end
      end_t = Time.now
      t2 = Process.times
      #; [!zw4kt] yields validator with returned value of block.
      yield ret, @name if block_given?()
      #; [!9e5pr] returns TimeSet object.
      user  = t2.utime - t1.utime
      sys   = t2.stime - t1.stime
      total = user + sys
      real  = end_t - start_t
      return TimeSet.new(user, sys, total, real)
    end

  end

  TASK = Task


  TimeSet = Struct.new('TimeSet', :user, :sys, :total, :real) do

    def -(t)
     #; [!cpwgf] returns new TimeSet object.
      user  = self.user  - t.user
      sys   = self.sys   - t.sys
      total = self.total - t.total
      real  = self.real  - t.real
      return TimeSet.new(user, sys, total, real)
    end

    def div(n)
      #; [!4o9ns] returns new TimeSet object which values are divided by n.
      user  = self.user  / n
      sys   = self.sys   / n
      total = self.total / n
      real  = self.real  / n
      return TimeSet.new(user, sys, total, real)
    end

  end


  class Result

    def initialize()
      @iterations = []
    end

    def [](idx)
      return @iterations[idx]
    end

    def length()
      return @iterations.length
    end

    def each(&b)
      @iterations.each(&b)
    end

    def add(timeset)
      #; [!thyms] adds timeset and returns self.
      @iterations << timeset
      self
    end

    def clear()
      #; [!fxrn6] clears timeset array.
      @iterations.clear()
      self
    end

    def skipped=(reason)
      @reason = reason
    end

    def skipped?
      #; [!bvzk9] returns true if reason has set, or returns false.
      return !!@reason
    end

    def remove_minmax(extra, key=:real)
      #; [!b55zh] removes best and worst timeset and returns them.
      i = 0
      pairs = @iterations.collect {|t| [t, i+=1] }
      pairs = pairs.sort_by {|pair| pair[0].__send__(key) }
      removed = []
      extra.times do
        min_timeset, min_idx = pairs.shift()
        max_timeset, max_idx = pairs.pop()
        min_t = min_timeset.__send__(key)
        max_t = max_timeset.__send__(key)
        removed << [min_t, min_idx, max_t, max_idx]
      end
      remained = pairs.sort_by {|_, i| i }.collect {|t, _| t }
      @iterations = remained
      return removed
    end

    def calc_average()
      #; [!b91w3] returns average of timeddata.
      user = sys = total = real = 0.0
      @iterations.each do |t|
        user  += t.user
        sys   += t.sys
        total += t.total
        real  += t.real
      end
      n = @iterations.length
      return TimeSet.new(user/n, sys/n, total/n, real/n)
    end

  end


  module Misc

    module_function

    def environment_info()
      #; [!w1xfa] returns environment info in key-value list.
      ruby_engine_version = (RUBY_ENGINE_VERSION rescue nil)
      cc_version_msg = RbConfig::CONFIG['CC_VERSION_MESSAGE']
      return [
        ["benchmarker"   , "release #{VERSION}"],
        ["ruby engine"   , "#{RUBY_ENGINE} (engine version #{ruby_engine_version})"],
        ["ruby version"  , "#{RUBY_VERSION} (patch level #{RUBY_PATCHLEVEL})"],
        ["ruby platform" , RUBY_PLATFORM],
        ["ruby path"     , RbConfig.ruby],
        ["compiler"      , cc_version_msg ? cc_version_msg.split(/\r?\n/)[0] : nil],
        ["cpu model"     , cpu_model()],
      ]
    end

    def cpu_model()
      #; [!6ncgq] returns string representing cpu model.
      if File.exist?("/usr/sbin/sysctl")        # macOS
        output = `/usr/sbin/sysctl machdep.cpu.brand_string`
        output =~ /^machdep\.cpu\.brand_string: (.*)/
        return $1
      elsif File.exist?("/proc/cpuinfo")        # Linux
        output = `cat /proc/cpuinfo`
        output =~ /^model name\s*: (.*)/
        return $1
      elsif File.exist?("/var/run/dmesg.boot")  # FreeBSD
        output = `grep ^CPU: /var/run/dmesg.boot`
        output =~ /^CPU: (.*)/
        return $1
      elsif RUBY_PLATFORM =~ /win/              # Windows
        output = `systeminfo`
        output =~ /^\s+\[01\]: (.*)/    # TODO: not tested yet
        return $1
      else
        return nil
      end
    end

  end


  class OptionParser

    def initialize(opts_noparam, opts_hasparam, opts_mayparam="")
      @opts_noparam  = opts_noparam
      @opts_hasparam = opts_hasparam
      @opts_mayparam = opts_mayparam
    end

    def parse(argv)
      #; [!2gq7g] returns options and keyvals.
      options = {}; keyvals = {}
      while !argv.empty? && argv[0] =~ /^-/
        argstr = argv.shift
        case argstr
        #; [!ulfpu] stops parsing when '--' found.
        when '--'
          break
        #; [!8f085] regards '--long=option' as key-value.
        when /^--/
          argstr =~ /^--(\w[-\w]*)(?:=(.*))?$/  or
            yield "#{argstr}: invalid option."
          key = $1; val = $2
          keyvals[key] = val || true
        #; [!dkq1u] parses short options.
        when /^-/
          i = 1
          while i < argstr.length
            c = argstr[i]
            if @opts_noparam.include?(c)
              options[c] = true
              i += 1
            elsif @opts_hasparam.include?(c)
              #; [!8xqla] error when required argument is not provided.
              options[c] = i+1 < argstr.length ? argstr[(i+1)..-1] : argv.shift()  or
                yield "-#{c}: argument required."
              break
            elsif @opts_mayparam.include?(c)
              options[c] = i+1 < argstr.length ? argstr[(i+1)..-1] : true
              break
            #; [!tmx6o] error when option is unknown.
            else
              yield "-#{c}: unknown option."
              i += 1
            end
          end
        else
          raise "** internall error"
        end
      end
      return options, keyvals
    end

    def self.parse_options(argv=ARGV, &b)
      parser = self.new("hvq", "wnixosF", "I")
      options, keyvals = parser.parse(argv, &b)
      #; [!v19y5] converts option argument into integer if necessary.
      "wnixI".each_char do |c|
        next if !options.key?(c)
        next if options[c] == true
        #; [!frfz2] yields error message when argument of '-n/i/x/I' is not an integer.
        options[c] =~ /\A\d+\z/  or
          yield "-#{c}#{c == 'I' ? '' : ' '}#{options[c]}: integer expected."
        options[c] = options[c].to_i
      end
      #; [!nz15w] convers '-s' option value into number (integer or float).
      "s".each_char do |c|
        next unless options.key?(c)
        case options[c]
        when /\A\d+\z/      ; options[c] = options[c].to_i
        when /\A\d+\.\d+\z/ ; options[c] = options[c].to_f
        else
          #; [!3x1m7] yields error message when argument of '-s' is not a number.
          yield "-#{c} #{options[c]}: number expected."
        end
      end
      #
      if options['F']
        #; [!emavm] yields error message when argumetn of '-F' option is invalid.
        if options['F'] !~ /^(\w+)(=|!=)[^=]/
          yield "-F #{options['F']}: invalid filter (expected operator is '=' or '!=')."
        elsif ! ($1 == 'task' || $1 == 'tag')
          yield "-F #{options['F']}: expected 'task=...' or 'tag=...'."
        end
      end
      return options, keyvals
    end

    def self.help_message(command=nil)
      #; [!jnm2w] returns help message.
      command ||= File.basename($0)
      return <<"END"
Usage: #{command} [<options>]
  -h, --help     : help message
  -v             : print Benchmarker version
  -w <N>         : width of task name (default: 30)
  -n <N>         : loop N times in each benchmark (default: 1)
  -i <N>         : iterates all benchmark tasks N times (default: 1)
  -x <N>         : ignore worst N results and best N results (default: 0)
  -I[<N>]        : print inverse number (= N/sec) (default: same as '-n')
  -o <file>      : output file in JSON format
  -q             : quiet a little (suppress output of each iteration)
  -s <N>         : sleep N seconds after each benchmark task
  -F task=<...>  : filter benchmark task by name (operator: '=' or '!=')
  -F tag=<...>   : filter benchmark task by tag (operator: '=' or '!=')
  --<key>[=<val>]: define global variable `$var = "val"`
END
    end

  end


  def self.parse_cmdopts(argv=ARGV)
    #; [!348ip] parses command-line options.
    #; [!snqxo] exits with status code 1 if error in command option.
    options, keyvals = OptionParser.parse_options(argv) do |errmsg|
      $stderr.puts errmsg
      exit 1
    end
    #; [!p3b93] prints help message if '-h' or '--help' option specified.
    if options['h'] || keyvals['help']
      puts OptionParser.help_message()
      exit 0
    end
    #; [!iaryj] prints version number if '-v' option specified.
    if options['v']
      puts VERSION
      exit 0
    end
    #; [!s7y6x] keeps command-line options in order to overwirte existing options.
    #; [!nexi8] option '-w' specifies task name width.
    #; [!raki9] option '-n' specifies count of loop.
    #; [!mt7lw] option '-i' specifies number of iteration.
    #; [!7f2k3] option '-x' specifies number of best/worst tasks removed.
    #; [!r0439] option '-I' specifies inverse switch.
    #; [!4c73x] option '-o' specifies outout JSON file.
    #; [!02ml5] option '-q' specifies quiet mode.
    #; [!6nxi8] option '-s' specifies sleep time.
    #; [!muica] option '-F' specifies filter.
    OPTIONS[:width]   = options['w'] if options['w']
    OPTIONS[:loop]    = options['n'] if options['n']
    OPTIONS[:iter]    = options['i'] if options['i']
    OPTIONS[:extra]   = options['x'] if options['x']
    OPTIONS[:inverse] = options['I'] if options['I']
    OPTIONS[:outfile] = options['o'] if options['o']
    OPTIONS[:quiet]   = options['q'] if options['q']
    OPTIONS[:sleep]   = options['s'] if options['s']
    OPTIONS[:filter]  = options['F'] if options['F']
    #; [!3khc4] sets global variables if long option specified.
    keyvals.each {|k, v| eval "$#{k} = #{v.inspect}" }
    #
    return options, keyvals  # for testing
  end

  unless defined?(::BENCHMARKER_IGNORE_CMDOPTS) && ::BENCHMARKER_IGNORE_CMDOPTS
    self.parse_cmdopts(ARGV)
  end


end



## for compatibility with 'benchmark.rb' (standard library)
module Benchmark

  def self.__new_bm(width, &block)   # :nodoc:
    bm = Benchmarker.new(width: width)
    scope = Benchmarker::Scope.new(bm)
    scope.instance_exec(scope, &block)
    return bm
  end

  def self.bm(width=nil, &block)
    #; [!2nf07] defines and runs benchmark.
    __new_bm(width, &block).run()
    nil
  end

  def self.bmbm(width=nil, &block)
    #; [!ezbb8] defines and runs benchmark twice, reports only 2nd result.
    __new_bm(width, &block).run(warmup: true)
    nil
  end

end unless defined?(::Benchmark)
