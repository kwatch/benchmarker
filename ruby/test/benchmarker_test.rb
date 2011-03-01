###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

$:.unshift File.class_eval { expand_path(dirname(__FILE__)) }
$:.unshift File.class_eval { expand_path(join(dirname(__FILE__), '../lib')) }

require 'oktest'
require 'benchmarker'


class Benchmarker_TC
  include Oktest::TestCase

  def test_SELF_new
    spec "creates runner object and returns it." do
      ret = Benchmarker.new
      ok {ret}.is_a?(Benchmarker::RUNNER)
    end
  end

  def test_SELF_platform
    spec "returns platform information." do
      s = Benchmarker.platform()
      ok {s} =~ /^benchmarker\.rb:\s+release \d+\.\d+\.\d+/
      rexp = /^RUBY_VERSION:\s+(.*)/
      ok {s} =~ rexp
      ok {s =~ rexp and $1} == RUBY_VERSION
      rexp = /^RUBY_PATCHLEVEL:\s+(.*)/
      ok {s} =~ rexp
      ok {s =~ rexp and $1} == RUBY_PATCHLEVEL.to_s
      rexp = /^RUBY_PLATFORM:\s+(.*)/
      ok {s} =~ rexp
      ok {s =~ rexp and $1} == RUBY_PLATFORM
      i = 0
      s.each_line {|line| i += 1 }
      ok {i} == 4
    end
  end

end


class Benchmarker::Runner_TC
  include Oktest::TestCase

  def test_initialize
    spec "takes :loop, :cycle, and :extra options." do
      runner = Benchmarker::RUNNER.new(:loop=>10, :cycle=>20, :extra=>30)
      ok {runner.instance_variable_get('@loop')}  == 10
      ok {runner.instance_variable_get('@cycle')} == 20
      ok {runner.instance_variable_get('@extra')} == 30
    end
  end

  def test_task
    runner = nil
    ret    = nil
    called = false
    sout   = nil
    spec "prints section title if not printed yet." do
      sout, serr = dummy_io() do
        runner = Benchmarker::RUNNER.new   # should be inside dummy_io() block!
        ret = runner.task("label1") { called = true }
      end
      ok {sout} =~ /\A\n## {28}      user       sys     total      real\n.*\n/
      ok {serr} == ""
    end
    spec "returns created task object." do
      ok {ret}.is_a?(Benchmarker::TASK)
    end
    spec "creates task objet and saves it." do
      task = ret
      ok {runner.tasks} == [task]
    end
    spec "runs task." do
      ok {called} == true
      ok {sout} =~ /\A\n.*\nlabel1                            0\.\d+    0\.\d+    0\.\d+    0\.\d+\n/
    end
    spec "subtracts times of empty task if exists." do
      empty_task = runner.empty_task { nil }
      empty_task.user  = 10.0
      empty_task.sys   =  5.0
      empty_task.total = 15.0
      empty_task.real  = 20.0
      t = runner.task("label2") { x = 1+1 }
      ok {t.user }.in_delta?(-10.0, 0.1)
      ok {t.sys  }.in_delta?(- 5.0, 0.1)
      ok {t.total}.in_delta?(-15.0, 0.1)
      ok {t.real }.in_delta?(-20.0, 0.1)
    end
    spec "@_empty_task should be cleared when empty task." do
      pr = proc do
        runner.task("(Empty)") { nil }
      end
      ok {pr}.raise?(RuntimeError, "** assertion failed")
      pr = proc do
        runner.empty_task { nil }
      end
      not_ok {pr}.raise?(Exception)
    end
  end

  def test_empty_task
    runner = nil
    task = nil
    spec "returns empty task." do
      sout, serr = dummy_io() do
        runner = Benchmarker::RUNNER.new    # should be inside dummy_io() block!
        task = runner.empty_task { nil }
      end
      ok {task}.is_a?(Benchmarker::TASK)
      ok {task.label} == "(Empty)"
    end
    spec "don't add empty task to @tasks." do
      ok {runner.tasks} == []
    end
    spec "creates empty task and save it." do
      ok {runner.instance_variable_get('@_empty_task')} == task
    end
    spec "clear @_empty_task." do
      # pass
    end
  end

  def test_skip_task
    runner = nil
    sout, serr = dummy_io() do
      runner = Benchmarker::RUNNER.new
      runner.skip_task("bench1", "-- not installed --")
      runner.skip_task("bench2", "** not supported **")
    end
    spec "prints headers if they are not printed." do
      ok {sout} =~ /^## +user +sys +total +real\n/
    end
    spec "prints task label and message instead of times." do
      ok {sout} =~ /^bench1 +\-\- not installed \-\-\n/
      ok {sout} =~ /^bench2 +\*\* not supported \*\*\n/
    end
    spec "don't create a new task object nor add to @tasks." do
      ok {runner.instance_variable_get('@tasks')} == []
    end
  end

  def test__before_all
    spec "prints platform information." do
      sout, serr = dummy_io() do
        runner = Benchmarker::RUNNER.new
        runner._before_all()
      end
      ok {sout} == Benchmarker.platform()
    end
  end

  def test__after_all
    spec "prints statistics of benchmarks." do
      tr = tracer()
      sout, serr = dummy_io() do
        runner = Benchmarker::RUNNER.new
        tr.trace_method(runner.stats, :all)
        runner.task("label1") { nil }
        runner.task("label2") { nil }
        runner._after_all()
      end
      ok {tr[0].name} == :all
      ok {sout} =~ /^## Ranking/
      ok {sout} =~ /^## Matrix/
    end
  end

  def test__run
    spec "when @cycle > 1..." do
      runner = sout = serr = block_param = nil
      spec "yields block @cycle times when @extra is not specified." do
        i = 0
        sout, serr = dummy_io() do
          runner = Benchmarker::RUNNER.new(:cycle=>2)
          runner._run do |r|
            i +=1
            block_param = r
            r.task('taskA') { nil }
            r.task('taskB') { nil }
          end
        end
        ok {i} == 2
      end
      runner2 = sout2 = serr2 = block_param2 = nil
      spec "yields block @cycle + 2*@extra times when @extra is specified." do
        i = 0
        sout2, serr2 = dummy_io() do
          runner2 = Benchmarker::RUNNER.new(:cycle=>5, :extra=>1)
          runner2._run do |r|
            i +=1
            block_param2 = r
            r.task('taskA') { nil }
            r.task('taskB') { nil }
          end
        end
        ok {i} == 7
      end
      spec "prints output of cycle into stderr." do
        not_ok {sout} =~ /^## \(#1\)/
        not_ok {sout} =~ /^## \(#2\)/
        ok {serr} =~ /^## \(#1\)/
        ok {serr} =~ /^## \(#2\)/
        not_ok {sout2} =~ /^## \(#1\)/
        not_ok {sout2} =~ /^## \(#2\)/
        ok {serr2} =~ /^## \(#1\)/
        ok {serr2} =~ /^## \(#2\)/
      end
      spec "yields block with self as block paramter." do
        ok {block_param}.same?(runner)
        ok {block_param2}.same?(runner2)
      end
      spec "reports average of results." do
        ok {sout}  =~ /^## Average of 2/
        ok {sout2} =~ /^## Average of 5 \(=7-2\*1\)/
      end
    end
    spec "when @cycle == 0 or not specified..." do
      runner = sout = block_param = nil
      spec "yields block only once." do
        i = 0
        sout, serr = dummy_io() do
          runner = Benchmarker::RUNNER.new()
          runner._run do |r|
            i +=1
            block_param = r
            r.task('taskA') { nil }
            r.task('taskB') { nil }
          end
        end
        ok {i} == 1
        ok {sout} =~ /^## *user/
      end
      spec "yields block with self as block paramter." do
        ok {block_param}.same?(runner)
      end
    end
  end

  def test__calc_average
    sos = proc do |label, user, sys, total, real|
      t = Benchmarker::TASK.new(label)
      t.user, t.sys, t.total, t.real = user, sys, total, real
      t
    end
    all_tasks = []
    all_tasks << [
      sos.call("Haruhi", 11.1, 0.2, 11.3, 11.3),
      sos.call("Mikuru", 14.1, 0.2, 14.3, 14.1),
      sos.call("Yuki",   10.1, 0.2, 10.3, 10.4),
      sos.call("Itsuki", 12.1, 0.2, 12.3, 12.1),
      sos.call("Kyon",   13.1, 0.2, 13.3, 13.5),
    ]
    all_tasks << [
      sos.call("Haruhi", 11.1, 0.2, 11.3, 11.9),
      sos.call("Mikuru", 14.1, 0.2, 14.3, 14.2),
      sos.call("Yuki",   10.1, 0.2, 10.3, 10.6),
      sos.call("Itsuki", 12.1, 0.2, 12.3, 12.5),
      sos.call("Kyon",   13.1, 0.2, 13.3, 13.3),
    ]
    all_tasks << [
      sos.call("Haruhi", 11.1, 0.2, 11.3, 11.5),
      sos.call("Mikuru", 14.1, 0.2, 14.3, 14.8),
      sos.call("Yuki",   10.1, 0.2, 10.3, 10.9),
      sos.call("Itsuki", 12.1, 0.2, 12.3, 12.7),
      sos.call("Kyon",   13.1, 0.2, 13.3, 13.9),
    ]
    all_tasks << [
      sos.call("Haruhi", 11.1, 0.2, 11.3, 11.3),
      sos.call("Mikuru", 14.1, 0.2, 14.3, 14.2),
      sos.call("Yuki",   10.1, 0.2, 10.3, 10.3),
      sos.call("Itsuki", 12.1, 0.2, 12.3, 12.8),
      sos.call("Kyon",   13.1, 0.2, 13.3, 13.4),
    ]
    all_tasks << [
      sos.call("Haruhi", 11.1, 0.2, 11.3, 11.6),
      sos.call("Mikuru", 14.1, 0.2, 14.3, 14.2),
      sos.call("Yuki",   10.1, 0.2, 10.3, 10.6),
      sos.call("Itsuki", 12.1, 0.2, 12.3, 12.4),
      sos.call("Kyon",   13.1, 0.2, 13.3, 13.3),
    ]
    all_tasks << [
      sos.call("Haruhi", 11.1, 0.2, 11.3, 11.3),
      sos.call("Mikuru", 14.1, 0.2, 14.3, 14.8),
      sos.call("Yuki",   10.1, 0.2, 10.3, 10.3),
      sos.call("Itsuki", 12.1, 0.2, 12.3, 12.2),
      sos.call("Kyon",   13.1, 0.2, 13.3, 13.7),
    ]
    #
    expected = <<'END'

## Remove Min & Max                  min     cycle       max     cycle
Haruhi                           11.3000      (#1)   11.9000      (#2)
                                 11.3000      (#6)   11.6000      (#5)
Mikuru                           14.1000      (#1)   14.8000      (#6)
                                 14.2000      (#2)   14.8000      (#3)
Yuki                             10.3000      (#6)   10.9000      (#3)
                                 10.3000      (#4)   10.6000      (#5)
Itsuki                           12.1000      (#1)   12.8000      (#4)
                                 12.2000      (#6)   12.7000      (#3)
Kyon                             13.3000      (#5)   13.9000      (#3)
                                 13.3000      (#2)   13.7000      (#6)

## Average of 2                     user       sys     total      real
Haruhi                           11.1000    0.2000   11.3000   11.4000
Mikuru                           14.1000    0.2000   14.3000   14.2000
Yuki                             10.1000    0.2000   10.3000   10.5000
Itsuki                           12.1000    0.2000   12.3000   12.4500
Kyon                             13.1000    0.2000   13.3000   13.4500
END
    #
    spec "calculates average times of tasks." do
      avg_tasks = nil
      sout, serr = dummy_io() do
        runner = Benchmarker::RUNNER.new(:cycle=>2)
        avg_tasks = runner.__send__(:_calc_averages, all_tasks, 2)
        runner.__send__(:_report_average_section, avg_tasks)
      end
      ok {sout} == expected
    end
  end

  def test__get_average_section_title
    spec "returns 'Average of N (=x-2*y)' string if label width is enough wide." do
      runner = Benchmarker::RUNNER.new(:width=>24, :cycle=>5, :extra=>1)
      title = runner.__send__(:_get_average_section_title)
      ok {title} == "Average of 5 (=7-2*1)"
    end
    spec "returns 'Average of N' string if label width is not enough wide." do
      runner = Benchmarker::RUNNER.new(:width=>23, :cycle=>5, :extra=>1)
      title = runner.__send__(:_get_average_section_title)
      ok {title} == "Average of 5"
    end
  end

end


class Benchmarker::Task_TC
  include Oktest::TestCase

  def before
    @task1 = Benchmarker::TASK.new("label1")
    @task1.user  = 1.5
    @task1.sys   = 0.5
    @task1.total = 2.0
    @task1.real  = 2.25
    @task2 = Benchmarker::TASK.new("label1")
    @task2.user  = 1.125
    @task2.sys   = 0.25
    @task2.total = 1.375
    @task2.real  = 1.5
  end

  def test_initialize
    t = nil
    spec "takes label and loop." do
      t = Benchmarker::TASK.new("label1", 123)
      ok {t.label} == "label1"
      ok {t.loop}  == 123
    end
    spec "sets all times to zero." do
      ok {t.user}  == 0.0
      ok {t.sys}   == 0.0
      ok {t.total} == 0.0
      ok {t.real}  == 0.0
    end
  end

  def test_run
    spec "yields block for @loop times." do
      task = Benchmarker::TASK.new("label2")
      i = 0
      task.run { i += 1 }
      ok {i} == i
      task.loop = 3
      i = 0
      task.run { i += 1 }
      ok {i} == 3
    end
    spec "measures times." do
      task = Benchmarker::TASK.new("label2")
      task.user = task.sys = task.total = task.real = -1.0
      task.run { nil }
      delta = 0.001
      ok {task.user }.in_delta?(0.0, delta)
      ok {task.sys  }.in_delta?(0.0, delta)
      ok {task.total}.in_delta?(0.0, delta)
      ok {task.real }.in_delta?(0.0, delta)
    end
  end

  def test_add
    spec "returns self." do
      ok {@task1.add(@task2)}.same?(@task1)
    end
    spec "adds other's times into self." do
      ok {@task1.user } == 2.625
      ok {@task1.sys  } == 0.75
      ok {@task1.total} == 3.375
      ok {@task1.real } == 3.75
    end
  end

  def test_sub
    spec "returns self." do
      ok {@task1.sub(@task2)}.same?(@task1)
    end
    spec "substracts other's times from self." do
      ok {@task1.user } == 0.375
      ok {@task1.sys  } == 0.25
      ok {@task1.total} == 0.625
      ok {@task1.real } == 0.75
    end
  end

  def test_mul
    spec "returns self." do
      ok {@task1.mul(2)}.same?(@task1)
    end
    spec "multiplies times with n." do
      ok {@task1.user } == 3.0
      ok {@task1.sys  } == 1.0
      ok {@task1.total} == 4.0
      ok {@task1.real } == 4.5
    end
  end

  def test_div
    spec "returns self." do
      ok {@task1.div(2)}.same?(@task1)
    end
    spec "divides times by n." do
      ok {@task1.user } == 0.75
      ok {@task1.sys  } == 0.25
      ok {@task1.total} == 1.0
      ok {@task1.real } == 1.125
    end
  end

  def test_SELF_average
    klass = Benchmarker::TASK
    spec "returns empty task when argument is empty." do
      t = klass.average([])
      ok {t.label} == nil
      ok {t.user} == 0.0
    end
    spec "create new task with label." do
      t = klass.average([@task1, @task2])
      ok {t.label} == @task1.label
      not_ok {t.label}.same?(@task1)
    end
    spec "returns averaged task." do
      t = klass.average([@task1, @task2, @task1, @task2])
      ok {t.user } == (@task1.user  + @task2.user ) / 2
      ok {t.sys  } == (@task1.sys   + @task2.sys  ) / 2
      ok {t.total} == (@task1.total + @task2.total) / 2
      ok {t.real } == (@task1.real  + @task2.real ) / 2
    end
  end

end


class Benchmarker::Reporter_TC
  include Oktest::TestCase

  def before
    @buf = ""
    @r = Benchmarker::Reporter.new(:out=>@buf)
  end

  def test_initialize
    spec "takes :out, :err, :width, and :format options." do
      r = Benchmarker::Reporter.new(:out=>$stderr, :err=>$stdout, :width=>123, :format=>"%10.1f")
      ok {r.out}.same?($stderr)
      ok {r.err}.same?($stdout)
      ok {r.label_width} == 123
      ok {r.format_time} == "%10.1f"
    end
  end

  def test__switch_out_to_err
    spec "switches @out to @err temporarily." do
      sout, serr = dummy_io() do
        r = Benchmarker::Reporter.new()
        r.write("Haruhi\n")
        r._switch_out_to_err() do
          r.write("Sasaki\n")
        end
        r.write("Kyon\n")
      end
      ok {sout} == "Haruhi\nKyon\n"
      ok {serr} == "Sasaki\n"
    end
  end

  def test_label_width=()
    spec "sets @label_width." do
      @r.label_width = 123
      ok {@r.label_width} == 123
    end
    spec "sets @format_label, too." do
      ok {@r.instance_variable_get('@format_label')} == "%-123s"
    end
  end

  def test_format_time=()
    spec "sets @format_time." do
      @r.format_time = "%10.2f"
      ok {@r.format_time} == "%10.2f"
    end
    spec "sets @format_header, too." do
      ok {@r.instance_variable_get('@format_header')} == "%10s"
    end
  end

  def test_write
    spec "writes arguments to @out with '<<' operator." do
      @r.write("Haruhi", nil, 32)
      ok {@buf} == "Haruhi32"
    end
    spec "saves the last argument." do
      ok {@r.instance_variable_get('@_prev')} == 32
    end
    spec "returns self." do
      ok {@r.write()}.same?(@r)
    end
  end

  def test_report_section_title
    ret = @r.report_section_title("SOS")
    spec "prints newline at first." do
      ok {@buf} =~ /\A\n/
    end
    spec "prints section title with @format_label." do
      ok {@buf} =~ /\A\n## SOS {24}/
    end
    spec "returns self." do
      ok {ret}.same?(@r)
    end
  end

  def test_report_section_headers
    args = ["user", "sys", "total", "real"]
    ret = @r.report_section_headers(*args)
    spec "prints headers." do
      ok {@buf} == "      user       sys     total      real\n"
    end
    spec "prints newline at end." do
      ok {@buf} =~ /\n\z/
    end
    spec "returns self." do
      ok {ret}.same?(@r)
    end
  end

  def test_report_section_header
    ret = @r.report_section_header("Haruhi")
    spec "prints header with @format_header." do
      ok {@buf} == "    Haruhi"
      @buf[0..-1] = ""
      @r.format_time = "%5.2f"
      @r.report_section_header("SOS")
      ok {@buf} == "   SOS"
    end
    spec "returns self." do
      ok {ret}.same?(@r)
    end
  end

  def test_report_task_label
    ret = @r.report_task_label("Sasaki")
    spec "prints task label with @format_label." do
      ok {@buf} == "Sasaki                        "
      @buf[0..-1] = ""
      @r.instance_variable_set('@format_label', "%-12s")
      @r.report_task_label("Sasakisan")
      ok {@buf} == "Sasakisan   "
    end
    spec "returns self." do
      ok {ret}.same?(@r)
    end
  end

  def test_report_task_times
    ret = @r.report_task_times(1.1, 1.2, 1.3, 1.4)
    spec "prints task times with @format_time." do
      ok {@buf} == "    1.1000    1.2000    1.3000    1.4000\n"
    end
    spec "returns self." do
      ok {ret}.same?(@r)
    end
  end

  def test_report_task_time
    ret = @r.report_task_time(12.3)
    spec "prints task time with @format_time." do
      ok {@buf} == "   12.3000"
    end
    spec "returns self." do
      ok {ret}.same?(@r)
    end
  end

end


class Benchmarker::Stats_TC
  include Oktest::TestCase

  def before
    @out = ""
    @r = Benchmarker::Reporter.new(:out=>@out)
    @stats = Benchmarker::Stats.new(@r)
    #
    @tasks = []
    sos = proc do |label, user, sys, total, real|
      t = Benchmarker::TASK.new(label)
      t.user, t.sys, t.total, t.real = user, sys, total, real
      @tasks << t
    end
    sos.call("Haruhi", 11.1, 0.2, 11.3, 11.5)
    sos.call("Mikuru", 14.1, 0.2, 14.3, 14.5)
    sos.call("Yuki",   10.1, 0.2, 10.3, 10.5)
    sos.call("Itsuki", 12.1, 0.2, 12.3, 12.5)
    sos.call("Kyon",   13.1, 0.2, 13.3, 13.5)
  end

  def test_initialize
    r = Benchmarker::Reporter.new
    stats = Benchmarker::Stats.new(r)
    spec "takes reporter object." do
      ok {stats.instance_variable_get('@report')} == r
    end
    #spec "takes :real, :barchar, and :loop options." do
    #end
  end

  def test_ranking
    expected1 = <<'END'

## Ranking                          real
Yuki                             10.5000 (100.0%) ********************
Haruhi                           11.5000 ( 91.3%) ******************
Itsuki                           12.5000 ( 84.0%) *****************
Kyon                             13.5000 ( 77.8%) ****************
Mikuru                           14.5000 ( 72.4%) **************
END
    expected2 = <<'END'

## Ranking                          real
Yuki                             10.5000 (100.0%)     95238.10 per sec
Haruhi                           11.5000 ( 91.3%)     86956.52 per sec
Itsuki                           12.5000 ( 84.0%)     80000.00 per sec
Kyon                             13.5000 ( 77.8%)     74074.07 per sec
Mikuru                           14.5000 ( 72.4%)     68965.52 per sec
END
    spec "prints ranking." do
      spec "prints barchart if @numerator is not specified." do
        @stats.ranking(@tasks)
        ok {@out} == expected1
      end
      spec "prints inverse number if @numerator specified." do
        @out = ""
        @r = Benchmarker::Reporter.new(:out=>@out)
        @stats = Benchmarker::Stats.new(@r, :numerator=>1000*1000)
        @stats.ranking(@tasks)
        ok {@out} == expected2
      end
    end
  end

  def test_ratio_matrix
    expected = <<'END'

## Matrix                           real     [01]     [02]     [03]     [04]     [05]
[01] Yuki                        10.5000   100.0%   109.5%   119.0%   128.6%   138.1%
[02] Haruhi                      11.5000    91.3%   100.0%   108.7%   117.4%   126.1%
[03] Itsuki                      12.5000    84.0%    92.0%   100.0%   108.0%   116.0%
[04] Kyon                        13.5000    77.8%    85.2%    92.6%   100.0%   107.4%
[05] Mikuru                      14.5000    72.4%    79.3%    86.2%    93.1%   100.0%
END
    spec "prints matrix." do
      @stats.ratio_matrix(@tasks)
      ok {@out} == expected
    end
  end

end


if __FILE__ == $0
  Oktest::run_all()
end
