###
### $Release: $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: Public Domain $
###


module Benchmarker

  VERSION = "$Release: 0.0.0 $".split(/ /)[1]


  class OptionParser

    def initialize(opts_noparam, opts_hasparam)
      @opts_noparam = opts_noparam
      @opts_hasparam = opts_hasparam
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
              if i + 1 == argstr.length
                val = argv.shift()  or
                  yield "-#{c}: argument required."
              else
                val = argstr[(i+1)..-1]
              end
              options[c] = val
              break
            end
          end
        else
          raise "** internall error"
        end
      end
      return options, keyvals
    end

    def self.parse_options(argv=ARGV, &b)
      parser = self.new("hv", "ncxF")
      options, keyvals = parser.parse(argv, &b)
      "ncx".each_char do |c|
        next unless options[c]
        #; [!frfz2] yields error message when argument of '-n/c/x' is not an integer.
        options[c] =~ /\A\d+\z/  or
          yield "-#{c} #{options[c]}: integer expected."
        options[c] = options[c].to_i
      end
      if options['F']
        #; [!emavm] yields error message when argumetn of '-F' option is invalid.
        options['F'] =~ /^\w+(=|!=)[^=]/  or
          yield "-F #{options['F']}: expected operator is '=' or '!='."
      end
      return options, keyvals
    end

    def self.help_message(command=nil)
      #; [!jnm2w] returns help message.
      command ||= File.basename($0)
      return <<"END"
Usage: #{command} [<options>]
  -h           : help message
  -v           : print Benchmarker version
  -n <N>       : loop N times in each benchmark (default: 1)
  -c <N>       : cycle benchmarks N times (default: 1)
  -x <N>       : ignore worst N results and best N results (default: 0)
  -o <file>    : output file in JSON format
  -F name=<...>: filter benchmark by name (operator: '=' or '!=')
  -F tag=<...> : filter benchmark by tag (operator: '=' or '!=')
END
    end

  end


  def self.new(**opts, &block)
    #; [!348ip] parses command-line options.
    options, keyvals = OptionParser.parse_options() do |errmsg|
      $stderr.puts errmsg
      exit 1
    end
    #; [!p3b93] prints help message if '-h' option specified.
    if options['h']
      puts OptionParser.help_message()
      return
    end
    #; [!iaryj] prints version number if '-v' option specified.
    if options['v']
      puts VERSION
      return
    end
    #; [!3khc4] sets global variables if long option specified.
    keyvals.each {|k, v| eval "$#{k} = #{v.inspect}" }
    #; [!s7y6x] overwrites existing values by command-line options.
    opts[:loop]   = options['n'] if options['n']
    opts[:cycle]  = options['c'] if options['c']
    opts[:extra]  = options['x'] if options['x']
    opts[:filter] = options['F'] if options['F']
    #; [!uo4qd] creates runner object and returns it.
    runner = RUNNER.new(**opts)
    if block
      runner._before_all()
      runner._run(&block)
      runner._after_all()
    end
    runner
  end

  def self.bm(width=30, &block)    # for compatibility with benchmark.rb
    return self.new(:width=>30, &block)
  end

  def self.platform()
    #; [!ils8t] returns platform information.
    return <<END
## benchmarker.rb:   release #{VERSION}
## ruby version:     #{RUBY_VERSION} (patch level: #{RUBY_PATCHLEVEL})
## ruby engine:      #{RUBY_ENGINE} (engine version: #{RUBY_ENGINE_VERSION})
## ruby platform:    #{RUBY_PLATFORM}
## ruby path:        #{RbConfig.ruby}
## cpu model:        #{cpu_model()}
END
  end

  def self.cpu_model()
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


  class Runner

    def initialize(**opts)
      #; [!asupa] takes :loop, :cycle, and :extra options.
      @loop  = opts[:loop]
      @cycle = opts[:cycle]
      @extra = opts[:extra]
      if opts[:filter]
        opts[:filter] =~ /^(\w+)(=|!=)(.*)$/  or
          raise "** internal error: opts[:filter]=#{opts[:filter]}"
        @filter = [$1, $2, $3]
      end
      #:
      @tasks = []
      @report = REPORTER.new(**opts)
      @stats  = STATS.new(@report, **opts)
      @_section_title = ""
      @_section_started = false
    end

    attr_accessor :tasks, :report, :stats

    def task(label, **opts, &block)
      #; [!r0v4d] returns immediately if task not matched to filter.
      #; [!um9pe] supports negative filter.
      if @filter
        return nil unless _filter_matched?(@filter, label, opts)
      end
      #; [!xwgpx] prints section title if not printed yet.
      #; [!a41a9] creates task objet and returns it.
      #; [!53zit] runs task when :skip option is not specified.
      #; [!5xvgt] skip block and prints message when :skip option is specified.
      #; [!dhdrp] subtracts times of empty task if exists.
      skip_message = opts[:skip]
      t = _new_task(label, skip_message, &block)
      #; [!kq3sv] saves created task object unless :skip optin is not specified.
      @tasks << t unless skip_message
      t
    end

    alias report task      # for compatibility with benchmark.rb

    def empty_task(label="(Empty)", &block)
      #; [!x5pfs] clear @_empty_task.
      @_empty_task = nil
      #; [!lt9od] prints section title if not printed yet.
      #; [!68v26] creates empty task object and returns it.
      t = _new_task(label, &block)
      #; [!65p26] saves empty task object.
      #; [!xqmzu]  don't add empty task to @tasks.
      @_empty_task = t
      t
    end

    def _filter_matched?(filter, label, opts)   #:nodoc:
      key, op, pat = filter
      val = (key == 'name' ? label : \
             key == 'tag'  ? opts[:tag] : opts[key.intern])
      matched = false
      case val
      when String; matched = File.fnmatch(pat, val, File::FNM_EXTGLOB)
      when Array ; matched = val.any? {|s| File.fnmatch(pat, s, File::FNM_EXTGLOB) }
      end
      return matched if op == '='
      return !matched if op == '!='
      raise "** internal error"
    end
    private :_filter_matched?

    #--
    #def skip_task(label, message="   ** skipped **")
    #  #; [!8b03l] prints headers if they are not printed.
    #  t = _new_task(label)
    #  #; [!cigi9] prints task label and message instead of times.
    #  @report.write(message + "\n")
    #  #; [!yxep1] don't change @tasks.
    #end
    #++

    def _before_all   # :nodoc:
      #; [!wt867] prints Benchmarker.platform().
      print Benchmarker.platform()
    end

    def _after_all    # :nodoc:
      #; [!wt867] prints statistics out benchmarks.
      @stats.all(@tasks)
    end

    def _run   # :nodoc:
      #; [!rvcl5] when @cycle > 1...
      if @cycle && @cycle > 1
        @all_tasks = []
        #; [!zcg2x] prints output of cycle into stderr.
        @report._switch_out_to_err do
          #; [!2ysx9] yields block @cycle times when @extra is not specified.
          #; [!q1l7k] yields block @cycle + 2*@extra times when @extra is specified.
          i = 0
          cycle = @cycle
          cycle += 2 * @extra if @extra
          cycle.times do
            _reset_section("(##{i+=1})")
            @all_tasks << (@tasks = [])
            #; [!af3yf] yields block with self as block paramter.
            yield self
          end
        end
        #; [!gkgmb] reports average of results.
        @tasks = _calc_averages(@all_tasks, @extra)
        _report_average_section(@tasks)
      #; [!lo2qc] when @cycle == 0 or not specified...
      else
        #; [!wmixt] yields block only once.
        _reset_section("")
        #; [!8737l] yields block with self as block paramter.
        yield self
      end
    end

    private

    def _reset_section(section_title)
      @_section_started = false
      @_section_title = section_title
    end

    def _new_task(label, skip_message=nil, &block)
      #: prints section title if not printed yet.
      _report_section_title_if_not_printed_yet()
      #: creates task objet and returns it.
      t = TASK.new(label, @loop)
      @report.task_label(label)
      #: skip block and prints message when :skip option is specified.
      if skip_message
        @report.write(skip_message + "\n")
      #: runs task when :skip option is not specified.
      elsif block
        t.run(&block)
        #: subtracts times of empty task if exists.
        t.sub(@_empty_task) if @_empty_task
        @report.task_times(t.user, t.sys, t.total, t.real)
      end
      t
    end

    def _report_section_title_if_not_printed_yet
      if ! @_section_started
        @_section_started = true
        @report.section_title(@_section_title)\
               .section_headers("user", "sys", "total", "real")
      end
    end

    def _calc_averages(all_tasks, extra)
      #; [!hbb4u] calculates average times of tasks.
      tasks_list = _transform_all_tasks(all_tasks)
      if extra
        @report.section_title("Remove Min & Max").section_headers("min", "cycle", "max", "cycle")
        tasks_list = tasks_list.collect {|tasks| _remove_min_max(tasks, extra) }
      end
      avg_tasks = tasks_list.collect {|tasks| Task.average(tasks) }
      avg_tasks
    end

    def _transform_all_tasks(all_tasks)
      tasks_list = []
      all_tasks.each do |tasks|
        tasks.each_with_index do |task, i|
          (tasks_list[i] ||= []) << task
        end
      end
      tasks_list
    end

    def _remove_min_max(tasks, extra)
      #: reports min and max tasks.
      idx = -1
      pairs = tasks.collect {|task| [task, idx+=1] }
      pairs = pairs.sort_by {|task, idx| task.real }   # 1.8 doesn't support sort_by!
      j = -1
      while (j += 1) < extra
        @report.task_label(j == 0 ? pairs[j].first.label : '')
        task, idx = pairs[j]      # min
        @report.task_time(task.real).task_index(idx+1)
        task, idx = pairs[-j-1]   # max
        @report.task_time(task.real).task_index(idx+1)
        @report.text("\n")
      end
      #: removes min and max tasks, and returns remained tasks.
      remained_tasks = pairs[extra...-extra].collect {|task, idx| task }
      remained_tasks
    end

    def _report_average_section(tasks)
      title = _get_average_section_title()
      @report.section_title(title).section_headers("user", "sys", "total", "real")
      tasks.each do |t|
        @report.task_label(t.label).task_times(t.user, t.sys, t.total, t.real)
      end
    end

    def _get_average_section_title()
      #; [!6efqb] returns 'Average of N (=x-2*y)' string if label width is enough wide.
      #; [!a6tqp] returns 'Average of N' string if label width is not enough wide.
      title = "Average of #{@cycle}"
      if @extra
        s = " (=#{@cycle+2*@extra}-2*#{@extra})"
        title << s if "## #{title}#{s}".length <= @report.label_width
      end
      title
    end

  end

  RUNNER = Runner


  class Task

    def initialize(label, loop=1, &block)
      #; [!7c1i9] takes label and loop.
      @label = label
      @loop  = loop
      #; [!t556m] sets all times to zero.
      @user = @sys = @total = @real = 0.0
    end

    attr_accessor :label, :loop, :user, :sys, :total, :real

    def run
      #: starts GC before running benchmark.
      GC.start
      #; [!y50r1] yields block for @loop times.
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
      #; [!bl209] measures times.
      @user  = pt2.utime - pt1.utime
      @sys   = pt2.stime - pt1.stime
      @total = @user + @sys
      @real  = t2 - t1
      return self
    end

    def add(other)
      #; [!v11p8] adds other's times into self.
      @user  += other.user
      @sys   += other.sys
      @total += other.total
      @real  += other.real
      #; [!bz1wk] returns self.
      return self
    end

    def sub(other)
      #; [!neebc] substracts other's times from self.
      @user  -= other.user
      @sys   -= other.sys
      @total -= other.total
      @real  -= other.real
      #; [!6ru0l] returns self.
      return self
    end

    def mul(n)
      #; [!yoxsn] multiplies times with n.
      @user  *= n
      @sys   *= n
      @total *= n
      @real  *= n
      #; [!jyyyv] returns self.
      return self
    end

    def div(n)
      #; [!lu7js] divides times by n.
      @user  /= n
      @sys   /= n
      @total /= n
      @real  /= n
      #; [!ibgia] returns self.
      return self
    end

    def self.average(tasks)
      #; [!liw73] returns empty task when argument is empty.
      n = tasks.length
      return self.new(nil) if n == 0
      #; [!vdm4j] create new task with label.
      task = self.new(tasks.first.label)
      #; [!ppo1s] returns averaged task.
      tasks.each {|t| task.add(t) }
      task.div(n)
      return task
    end

  end

  TASK = Task


  class Reporter

    def initialize(**opts)
      #; [!jlnlm] takes :out, :err, :width, and :format options.
      @out = opts[:out] || $stdout
      @err = opts[:err] || $stderr
      self.label_width = opts[:width] || 30
      self.format_time = opts[:format] || "%9.4f"
    end

    attr_accessor :out, :err
    attr_reader :label_width, :format_time

    def _switch_out_to_err()   # :nodoc:
      #; [!6o2v7] switches @out to @err temporarily.
      begin
        out = @out
        @out = @err
        yield
      ensure
        @out = out
      end
    end

    def label_width=(width)
      #; [!asqgk] sets @label_width.
      @label_width = width
      #; [!e7hwb] sets @format_label, too.
      @format_label = "%-#{width}s"
    end

    def format_time=(format)
      #; [!5pir3] sets @format_time.
      @format_time = format
      #; [!726he] sets @format_header, too.
      m = /%-?(\d+)\.\d+/.match(format)
      @format_header = "%#{$1.to_i}s" if m
    end

    def write(*args)
      #; [!aktow] writes arguments to @out with '<<' operator.
      args.each {|x| @out << x.to_s }
      #; [!gf5rd] saves the last argument.
      @_prev = args[-1]
      #; [!r2wzc] returns self.
      return self
    end
    alias text write

    def report_section_title(title)
      #; [!mpne7] prints newline at first.
      write "\n"
      #; [!ikes2] prints section title with @format_label.
      write @format_label % "## #{title}"
      #; [!1q0yj] returns self.
      return self
    end
    alias section_title report_section_title

    def report_section_headers(*headers)
      #; [!61qm7] prints headers.
      headers.each do |header|
        report_section_header(header)
      end
      #; [!t5ye0] prints newline at end.
      write "\n"
      #; [!kbshe] returns self.
      return self
    end
    alias section_headers report_section_headers

    def report_section_header(header)
      #; [!88zjk] prints header with @format_header.
      write " ", @format_header % header
      #; [!v01al] returns self.
      return self
    end
    alias section_header report_section_header

    def report_task_label(label)
      #; [!ajtkj] prints task label with @format_label.
      write @format_label % label
      #; [!slxrv] returns self.
      return self
    end
    alias task_label report_task_label

    def report_task_times(user, sys, total, real)
      #; [!q36l4] prints task times with @format_time.
      fmt = @format_time
      write " ", fmt % user, " ", fmt % sys, " ", fmt % total, " ", fmt % real, "\n"
      #; [!tt8h0] returns self.
      return self
    end
    alias task_times report_task_times

    def report_task_time(time)
      #; [!lrcds] prints task time with @format_titme.
      write " ", @format_time % time
      #; [!emwdl] returns self.
      return self
    end
    alias task_time report_task_time

    def report_task_index(index)
      #: prints task time with @format_titme.
      write " ", @format_header % "(##{index})"
      #: returns self.
      return self
    end
    alias task_index report_task_index

  end

  REPORTER = Reporter


  class Stats

    def initialize(reporter, **opts)
      #; [!pky6r] takes reporter object.
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
      #; [!16hg8] prints ranking.
      key = @key
      @report.section_title("Ranking").section_headers(key.to_s)
      #base = tasks.min_by {|t| t.__send__(key) }.__send__(key)  # min_by() is available since 1.8.7
      base = tasks.collect {|t| t.__send__(key) }.min
      tasks.each do |task|
        sec = task.__send__(key).to_f
        val = 100.0 * base / sec
        @report.task_label(task.label).task_time(sec).text(" (%5.1f%%) " % val)
        #; [!dhnaa] prints barchart if @numerator is not specified.
        if ! @numerator
          bar = '*' * (val / 5.0).round
          @report.text(bar).text("\n")
        #; [!amvhe] prints inverse number if @numerator specified.
        else
          @report.text("%12.2f per sec" % (@numerator/ sec)).text("\n")
        end
      end
    end

    def ratio_matrix(tasks)
      tasks = tasks.sort_by {|t| t.__send__(@sort_key) } if @sort_key
      #; [!71nfp] prints matrix.
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
