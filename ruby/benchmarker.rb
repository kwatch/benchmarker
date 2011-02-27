###
### $Release: $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###


module Benchmarker

  VERSION = "$Release: 0.0.0 $".split(/ /)[1]

  def self.new(opts={}, &block)
    #: creates runner object and returns it.
    runner = RUNNER.new(opts)
    if block
      runner._before_all()
      runner._run(&block)
      runner._after_all()
    end
    runner
  end

  def self.platform()
    #: returns platform information.
    return <<END
benchmarker.rb:   release #{VERSION}
RUBY_VERSION:     #{RUBY_VERSION}
RUBY_PATCHLEVEL:  #{RUBY_PATCHLEVEL}
RUBY_PLATFORM:    #{RUBY_PLATFORM}
END
  end


  class Runner

    def initialize(opts={})
      #: takes :loop, :cycle, and :extra options.
      @loop  = opts[:loop]
      @cycle = opts[:cycle]
      @extra = opts[:extra]
      #:
      @tasks = []
      @report = REPORTER.new(opts)
      @stats  = STATS.new(@report, opts)
      @_section_title = ""
      @_section_started = false
    end

    attr_accessor :tasks, :report, :stats

    def task(label, &block)
      #: prints section title if not printed yet.
      if ! @_section_started
        @_section_started = true
        @report.section_title(@_section_title).
                section_headers("user", "sys", "total", "real")
      end
      #: creates task objet and saves it.
      t = TASK.new(label, @loop)
      @tasks << t
      #: run task.
      @report.task_label(label)
      t.run(&block)
      #: subtracts times of empty task if exists.
      t.sub(@_empty_task) if @_empty_task
      @report.task_times(t.user, t.sys, t.total, t.real)
      #: returns created task object.
      t
    end

    def empty_task
      #: creates empty task and save it.
      @_empty_task = task("(Empty)") { nil }
      #: returns empty task.
      @_empty_task
    end

    def _before_all   # :nodoc:
      #: prints Benchmarker.platform().
      print Benchmarker.platform()
    end

    def _after_all    # :nodoc:
      #: prints statistics out benchmarks.
      print @stats.all(@tasks)
    end

    def _run   # :nodoc:
      #: when @cycle > 1...
      if @cycle && @cycle > 1
        #: yields block @cycle times.
        @all_tasks = []
        i = 0
        @cycle.times do
          _reset_section("(#{i+=1})")
          @all_tasks << (@tasks = [])
          #: yields block with self as block paramter.
          yield self
        end
        #: reports average of results.
        @tasks = _calc_averages(@all_tasks)
        _report_average_section(@tasks)
      #: when @cycle == 0 or not specified...
      else
        #: yields block only once.
        _reset_section("")
        #: yields block with self as block paramter.
        yield self
      end
    end

    private

    def _reset_section(section_title)
      @_section_started = false
      @_section_title = section_title
    end

    def _calc_averages(all_tasks)
      n = all_tasks.first.length
      avg_tasks = (0...n).collect {|i|
        Task.average(all_tasks.collect {|tasks| tasks[i] })
      }
      return avg_tasks
    end

    def _report_average_section(tasks)
      @report.section_title("Average").section_headers("user", "sys", "total", "real")
      tasks.each do |t|
        @report.task_label(t.label).task_times(t.user, t.sys, t.total, t.real)
      end
    end

  end

  RUNNER = Runner


  class Task

    def initialize(label, loop=1, &block)
      #: takes label and loop.
      @label = label
      @loop  = loop
      #: sets all times to zero.
      @user = @sys = @total = @real = 0.0
    end

    attr_accessor :label, :loop, :user, :sys, :total, :real

    def run
      #: yields block for @loop times.
      ntimes = @loop || 1
      pt1 = Process.times
      t1 = Time.now
      if ntimes > 1
        ntimes.times { yield }
      else
        yield
      end
      pt2 = Process.times
      t2 = Time.now
      #: measures times.
      @user  = pt2.utime - pt1.utime
      @sys   = pt2.stime - pt1.stime
      @total = @user + @sys
      @real  = t2 - t1
      return self
    end

    def add(other)
      #: adds other's times into self.
      @user  += other.user
      @sys   += other.sys
      @total += other.total
      @real  += other.real
      #: returns self.
      return self
    end

    def sub(other)
      #: substracts other's times from self.
      @user  -= other.user
      @sys   -= other.sys
      @total -= other.total
      @real  -= other.real
      #: returns self.
      return self
    end

    def mul(n)
      #: multiplies times with n.
      @user  *= n
      @sys   *= n
      @total *= n
      @real  *= n
      #: returns self.
      return self
    end

    def div(n)
      #: divides times by n.
      @user  /= n
      @sys   /= n
      @total /= n
      @real  /= n
      #: returns self.
      return self
    end

    def self.average(tasks)
      #: returns empty task when argument is empty.
      n = tasks.length
      return self.new(nil) if n == 0
      #: create new task with label.
      task = self.new(tasks.first.label)
      #: returns averaged task.
      tasks.each {|t| task.add(t) }
      task.div(n)
      return task
    end

  end

  TASK = Task


  class Reporter

    def initialize(opts={})
      #: takes :out, :width, and :format options.
      @out = opts[:out] || $stdout
      self.label_width = opts[:width] || 30
      self.format_time = opts[:format] || "%9.4f"
    end

    attr_accessor :out
    attr_reader :label_width, :format_time

    def label_width=(width)
      #: sets @label_width.
      @label_width = width
      #: sets @format_label, too.
      @format_label = "%-#{width}s"
    end

    def format_time=(format)
      #: sets @format_time.
      @format_time = format
      #: sets @format_header, too.
      m = /%-?(\d+)\.\d+/.match(format)
      @format_header = "%#{$1.to_i}s" if m
    end

    def write(*args)
      #: writes arguments to @out with '<<' operator.
      args.each {|x| @out << x.to_s }
      #: saves the last argument.
      @_prev = args[-1]
      #: returns self.
      return self
    end
    alias text write

    def report_section_title(title)
      #: prints newline at first.
      write "\n"
      #: prints section title with @format_label.
      write @format_label % "## #{title}"
      #: returns self.
      return self
    end
    alias section_title report_section_title

    def report_section_headers(*headers)
      #: prints headers.
      headers.each do |header|
        report_section_header(header)
      end
      #: prints newline at end.
      write "\n"
      #: returns self.
      return self
    end
    alias section_headers report_section_headers

    def report_section_header(header)
      #: prints header with @format_header.
      write " ", @format_header % header
      #: returns self.
      return self
    end
    alias section_header report_section_header

    def report_task_label(label)
      #: prints task label with @format_label.
      write @format_label % label
      #: returns self.
      return self
    end
    alias task_label report_task_label

    def report_task_times(user, sys, total, real)
      #: prints task times with @format_time.
      fmt = @format_time
      write " ", fmt % user, " ", fmt % sys, " ", fmt % total, " ", fmt % real, "\n"
      #: returns self.
      return self
    end
    alias task_times report_task_times

    def report_task_time(time)
      #: prints task time with @format_titme.
      write " ", @format_time % time
      #: returns self.
      return self
    end
    alias task_time report_task_time

  end

  REPORTER = Reporter


  class Stats

    def initialize(reporter, opts={})
      #: takes reporter object.
      @report   = reporter
      @key      = opts[:key] || 'real'
      @sort_key = opts[:sort_key] || 'real'
      @loop     = opts[:loop]
      @numerator = opts[:numerator]
    end

    def all(tasks)
      ranking(tasks)
      ratio_matrix(tasks)
    end

    def ranking(tasks)
      tasks = tasks.sort_by {|t| t.__send__(@sort_key) } if @sort_key
      #: prints ranking.
      key = @key
      @report.section_title("Ranking").section_headers(key.to_s)
      #base = tasks.min_by {|t| t.__send__(key) }.__send__(key)  # min_by() is available since 1.8.7
      base = tasks.collect {|t| t.__send__(key) }.min
      tasks.each do |task|
        sec = task.__send__(key).to_f
        val = 100.0 * base / sec
        @report.task_label(task.label).task_time(sec).text(" (%5.1f%%) " % val)
        #: prints barchart if @numerator is not specified.
        if ! @numerator
          bar = '*' * (val / 5.0).round
          @report.text(bar).text("\n")
        #: prints inverse number if @numerator specified.
        else
          @report.text("%12.2f per sec" % (@numerator/ sec)).text("\n")
        end
      end
    end

    def ratio_matrix(tasks)
      tasks = tasks.sort_by {|t| t.__send__(@sort_key) } if @sort_key
      #: prints matrix.
      key = @key
      @report.section_title("Matrix").section_header("real")
      tasks.each_with_index do |t, i|
        @report.text(" %8s" % ("[%02d]" % (i+1)))
      end
      @report.text("\n")
      i = 0
      tasks.each do |base_task|
        i += 1
        base = base_task.__send__(key).to_f
        @report.task_label("[%02d] %s" % [i, base_task.label]).task_time(base)
        tasks.each do |t|
          sec = t.__send__(key).to_f
          val = 100.0 * sec / base
          @report.text(" %7.1f%%" % val)
        end
        @report.text("\n")
      end
    end

  end

  STATS = Stats


end
