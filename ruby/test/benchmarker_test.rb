# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require 'oktest'
require 'benchmarker'



class Benchmarker::ResultTest
  include Oktest::TestCase


  def test_initialize

    spec "take labe, user, sys, and real vaues." do
      r = Benchmarker::Result.new("AAA", 1.1, 2.2, 3.5, 4.9)
      ok_(r.label) == 'AAA'
      ok_(r.user)  == 1.1
      ok_(r.sys)   == 2.2
      ok_(r.total) == 3.5
      ok_(r.real)  == 4.9
    end

  end


  def test_SELF_average

    klass = Benchmarker::Result
    results = [
      klass.new("A", 1.1, 0.1, 1.4, 2.1),
      klass.new("A", 1.2, 0.2, 1.6, 2.2),
      klass.new("A", 1.3, 0.3, 1.8, 2.3),
      klass.new("A", 1.4, 0.4, 2.0, 2.4),
      klass.new("A", 1.5, 0.5, 2.2, 2.5),
    ]

    spec "return new Result object." do
      ret = klass.average(results)
      ok_(ret).is_a?(Benchmarker::Result)
    end

    spec "calculate average values of results." do
      r = klass.average(results)
      ok_(r.label) == "A"
      ok_(r.user).in_delta?( (1.1+1.2+1.3+1.4+1.5)/5, 0.0000001)
      ok_(r.sys).in_delta?(  (0.1+0.2+0.3+0.4+0.5)/5, 0.0000001)
      ok_(r.total).in_delta?((1.4+1.6+1.8+2.0+2.2)/5, 0.0000001)
      ok_(r.real).in_delta?( (2.1+2.2+2.3+2.4+2.5)/5, 0.0000001)
    end

  end


end



class Benchmarker::ReporterTest
  include Oktest::TestCase


  def before
    @klass = Benchmarker::Reporter
  end


  def test_initialize

    spec "take options." do
      r = @klass.new(:out=>"OUT", :width=>"WIDTH", :fmt=>"FMT", :header=>"HEADER",
                    :verbose=>"VERBOSE", :verbose_out=>"VOUT")
      ok_(r.out) == "OUT"
      ok_(r.width) == "WIDTH"
      ok_(r.fmt) == "FMT"
      ok_(r.header) == "HEADER"
      ok_(r.verbose) == "VERBOSE"
      ok_(r.verbose_out) == "VOUT"
    end

    spec "if :verbose is false then set @verbose_out to dummy string." do
      r = @klass.new(:verbose=>false, :verbose_out=>$stderr)
      ok_(r.verbose_out) == ""
    end

  end


  def test_start_verbose_region

    spec "switch @out to verbose output." do
      vout = ""
      r = @klass.new(:verbose_out=>vout)
      out = r.out
      r.start_verbose_region
      ok_(r.out).same?(vout)
      r << "foobar"
      ok_(vout) == "foobar"
    end

  end


  def test_stop_verbose_region

    spec "switch back @out to original object." do
      out = "(out)"
      vout = "(vout)"
      r = @klass.new(:out=>out, :verbose_out=>vout)
      r.start_verbose_region
      r << "foo"
      ok_(out) == "(out)"
      ok_(vout) == "(vout)foo"
      r.stop_verbose_region
      r << "bar"
      ok_(out) == "(out)bar"
      ok_(vout) == "(vout)foo"
    end

  end


  def test_ltlt

    spec "write arg into @out." do
      out = ""
      r = @klass.new(:out=>out)
      r << "foobar"
      ok_(out) == "foobar"
    end

  end


  def test_flush

    spec "call flush() if @out is IO object." do
      s = ""
      r = @klass.new(:out=>s)
      not_ok_(proc {r.flush()}).raise?(Exception)
      def s.flush
        self << "flushed!"
      end
      ok_(s) == ""
      s.flush()
      ok_(s) == "flushed!"
    end

  end


  def test_print_header

    spec "write header string into @out." do
      s = ""
      r = @klass.new(:out=>s, :width=>10, :header=>"<header>")
      r.print_header("TITLE")
      ok_(s) == "## TITLE  <header>\n"
    end

  end


  def test_print_label

    s = ""
    r = @klass.new(:out=>s, :width=>10, :header=>"<header>")
    def s.flush
      @flush_called = true
    end

    spec "write label string ito @out." do
      r.print_label('AAA')
      ok_(s) == "AAA       "
    end

    spec "call flush()." do
      #falldown
      ok_(s.instance_variable_get('@flush_called')) == true
    end

    spec "label can be trimmed if too long." do
      r.out = ""
      r.print_label('123456789012345')
      ok_(r.out) == '1234567890'
    end

  end


  def test_print_times

    spec "write user, sys, total, and real time into @out." do
      s = ""
      r = @klass.new(:out=>s)
      r.print_times(1.1, 0.5, 1.8, 2.0)
      ok_(s) == "    1.1000    0.5000    1.8000    2.0000\n"
    end

  end


end



class Benchmarker::StatisticsTest
  include Oktest::TestCase


  def before
    @klass = Benchmarker::Statistics
  end


  def test_initialize
    spec "save opts." do
      st = @klass.new(:compensate=>-100)
      ok_(st.instance_variable_get('@opts')).is_a?(Hash)
      ok_(st.instance_variable_get('@opts')[:compensate]) == -100
    end
  end


  @@_results1 = [
    Benchmarker::Result.new("AAA", 1.5, 0.5, 2.5, 2.5),
    Benchmarker::Result.new("BBB", 1.2, 0.2, 2.1, 2.2),
    Benchmarker::Result.new("CCC", 1.1, 0.1, 2.0, 2.1),
    Benchmarker::Result.new("DDD", 1.4, 0.4, 2.6, 2.4),
    Benchmarker::Result.new("EEE", 1.3, 0.3, 2.4, 2.3),
  ]


  def test_ranking

    spec "sort results and return ranking output." do
      st = @klass.new()
      output = st.ranking(@@_results1)
      expected = <<'END'
## Ranking                          real  ratio
CCC                               2.1000 (100.0) ********************
BBB                               2.2000 ( 95.5) *******************
EEE                               2.3000 ( 91.3) ******************
DDD                               2.4000 ( 87.5) *****************
AAA                               2.5000 ( 84.0) ****************
END
      ok_(output) == expected
    end

  end


  def test_matrix

    spec "calculate each ratios and return it." do
      st = @klass.new()
      output = st.matrix(@@_results1)
      expected = <<'END'
## Matrix                           real   [01]   [02]   [03]   [04]   [05]
[01] CCC                          2.1000  100.0  104.8  109.5  114.3  119.0
[02] BBB                          2.2000   95.5  100.0  104.5  109.1  113.6
[03] EEE                          2.3000   91.3   95.7  100.0  104.3  108.7
[04] DDD                          2.4000   87.5   91.7   95.8  100.0  104.2
[05] AAA                          2.5000   84.0   88.0   92.0   96.0  100.0
END
      ok_(output) == expected
    end

  end


end



class Benchmarker::RunnerTest
  include Oktest::TestCase


  def before
    @klass = Benchmarker::Runner
    @runner = @klass.new()
    @runner.reporter = Benchmarker::Reporter.new(:out=>'', :verbose=>false)
    @runner.statistics = Benchmarker::Statistics.new()
  end


  def test_intialize

    spec "take opts." do
      r = @klass.new(:loop=>99)
      ok_(r.loop) == 99
    end

  end


  def test_before

    spec "if header is not printed then prit it." do
      r = @runner
      varname = '@header_title'
      r.instance_variable_set(varname, 'TEST1')
      # 1st
      r.reporter.out = ""
      r.__send__(:before)
      ok_(r.reporter.out) == "## TEST1                            user       sys     total      real\n"
      ok_(r.instance_variable_get(varname)) == nil
      # 2nd
      r.reporter.out = ""
      r.__send__(:before)
      ok_(r.reporter.out) == ""
    end

    spec "do empty loop bench if @loop is set." do
      r = @klass.new(:loop=>9)
      r.reporter = Benchmarker::Reporter.new(:out=>"")
      r.__send__(:before)
      dummy = r.instance_variable_get('@_dummy_result')
      ok_(dummy).is_a?(Benchmarker::Result)
      ok_(dummy.label) == '(Empty loop)'
      ok_(r.instance_variable_get('@results').empty?) == true
    end

  end


  def test_after
  end


  def test_bench

    spec "run block and create Result object." do
      r = @runner
      called = 0
      r.bench("AAA") { called += 1 }
      ok_(called) == 1
      ok_(r.results.length) == 1
      ok_(r.results[0]).is_a?(Benchmarker::Result)
      ok_(r.results[0].label) == "AAA"
    end

    spec "run block N-times if @loop is N." do
      r = @klass.new(:loop=>99)
      r.reporter = Benchmarker::Reporter.new(:out=>"")
      called = 0
      r.bench("BBB") { called += 1 }
      ok_(called) == 99
      ok_(r.results.length) == 1
      ok_(r.results[0]).is_a?(Benchmarker::Result)
      ok_(r.results[0].label) == "BBB"
    end

  end


  def test__delete_minmax_from
    key, fmt, label_fmt = :real, '%9.4f', '%-10s'
    _create_results = proc {|label|
      [
        Benchmarker::Result.new(label, 1.2, 0.2, 2.4, 2.2),
        Benchmarker::Result.new(label, 1.4, 0.4, 2.8, 2.4),
        Benchmarker::Result.new(label, 1.5, 0.5, 2.0, 2.5),
        Benchmarker::Result.new(label, 1.1, 0.1, 2.2, 2.1),
        Benchmarker::Result.new(label, 1.3, 0.3, 2.6, 2.3),
      ]
    }
    reported = {}
    proc_obj = proc {|extra, label|
      results = _create_results.call(label)
      runner = @klass.new()
      runner.reporter = Benchmarker::Reporter.new(:out=>'', :verbose_out=>'')
      runner.__send__(:_delete_minmax_from, results, key, extra, fmt, label_fmt)
      reported[extra] = runner.reporter.out
      results
    }

    spec "remove results which have min or max value." do
      # extra = 1
      results = proc_obj.call(1, "AAA")
      ok_(results.length) == 3
      ok_(results.collect {|x| x.__send__(key) }) == [2.2, 2.4, 2.3]
      # extra = 2
      results = proc_obj.call(2, "BBB")
      ok_(results.length) == 1
      ok_(results.collect {|x| x.__send__(key) }) == [2.3]
    end

    spec "report remove min and max results." do
      # falldown
      ok_(reported[1]) == "AAA          2.1000       (4)   2.5000       (3)\n"
      ok_(reported[2]) == "BBB          2.1000       (4)   2.5000       (3)\n" \
                        + "             2.2000       (1)   2.4000       (2)\n"
    end

  end


  def test__average_results
    _create_results = proc {|label|
      [
        Benchmarker::Result.new(label, 1.2, 0.2, 2.4, 2.2),
        Benchmarker::Result.new(label, 1.4, 0.4, 2.8, 2.4+0.3),
        Benchmarker::Result.new(label, 1.5, 0.5, 2.0, 2.5+7-0.3),
        Benchmarker::Result.new(label, 1.1, 0.1, 2.2, 2.1-2),
        Benchmarker::Result.new(label, 1.3, 0.3, 2.6, 2.3),
      ]
    }

    spec "if extra is specified then calculate averages after removing mix/max data." do
      results_matrix = [ _create_results.call("AAA"), _create_results.call("BBB") ]
      extra = 1
      avg_results = @runner.__send__(:_average_results, results_matrix, :real, extra)
      ok_(avg_results[0].label) == 'AAA'
      ok_(avg_results[0].real) == 2.4
      ok_(avg_results[1].label) == 'BBB'
      ok_(avg_results[1].real) == 2.4
      #
      results_matrix = [ _create_results.call("CCC"), _create_results.call("DDD") ]
      extra = 2
      avg_results = @runner.__send__(:_average_results, results_matrix, :real, extra)
      ok_(avg_results[0].label) == 'CCC'
      ok_(avg_results[0].real) == 2.3
      ok_(avg_results[1].label) == 'DDD'
      ok_(avg_results[1].real) == 2.3
    end

    spec "if extra is less than or equal to 0 then just calculate averages." do
      results_matrix = [ _create_results.call("AAA"), _create_results.call("BBB") ]
      runner = @klass.new
      runner.reporter = Benchmarker::Reporter.new(:out=>"", :verbose_out=>"")
      key, extra = :real, 0
      avg_results = runner.__send__(:_average_results, results_matrix, key, extra)
      ok_(avg_results[0].label) == 'AAA'
      ok_(avg_results[0].real) == 3.3
      ok_(avg_results[1].label) == 'BBB'
      ok_(avg_results[1].real) == 3.3
    end

  end


  def test__print_results
    results = [
      Benchmarker::Result.new('AAA', 1.1, 0.1, 1.2, 2.1),
      Benchmarker::Result.new('BBB', 1.2, 0.2, 1.4, 2.2),
    ]
    @runner.__send__(:_print_results, results, 'Example')
    expected = <<'END'
## Example                          user       sys     total      real
AAA                               1.1000    0.1000    1.2000    2.1000
BBB                               1.2000    0.2000    1.4000    2.2000
END
    ok_(@runner.reporter.out) == expected
  end


  def test_repeat

    spec "repeat blocks n times." do
      r = @runner
      ctr = 0
      r.repeat(10) do
        ctr += 1
      end
      ok_(ctr) == 10
    end

    spec "repeat blocks n + 2*extra times if :extra specified." do
      r = @runner
      ctr = 0
      r.repeat(10, :extra=>3) do
        ctr += 1
      end
      ok_(ctr) == 10 + 2*3
    end

    spec "repeated result is printed into separated outout." do
      r = @klass.new(:loop=>7)
      r.reporter = Benchmarker::Reporter.new(:out=>"", :verbose_out=>"")
      r.repeat(3, :extra=>1) do
        r.bench("AAA") { a = 1 }
        r.bench("BBBB") { b = 1 }
        r.bench("CC") { c = 1 }
      end
      expected = <<'END'
## Average of 3 (=5-2*1)            user       sys     total      real
AAA                               0.0000    0.0000    0.0000    0.0000
BBBB                              0.0000    0.0000    0.0000    0.0000
CC                                0.0000    0.0000    0.0000    0.0000
END
      ok_(r.reporter.out.gsub(/-0\.0/, ' 0.0')) == expected
      expected = <<'END'
## Repeat (1)                       user       sys     total      real
(Empty loop)                      0.0000    0.0000    0.0000    0.0000
AAA                               0.0000    0.0000    0.0000    0.0000
BBBB                              0.0000    0.0000    0.0000    0.0000
CC                                0.0000    0.0000    0.0000    0.0000

## Repeat (2)                       user       sys     total      real
(Empty loop)                      0.0000    0.0000    0.0000    0.0000
AAA                               0.0000    0.0000    0.0000    0.0000
BBBB                              0.0000    0.0000    0.0000    0.0000
CC                                0.0000    0.0000    0.0000    0.0000

## Repeat (3)                       user       sys     total      real
(Empty loop)                      0.0000    0.0000    0.0000    0.0000
AAA                               0.0000    0.0000    0.0000    0.0000
BBBB                              0.0000    0.0000    0.0000    0.0000
CC                                0.0000    0.0000    0.0000    0.0000

## Repeat (4)                       user       sys     total      real
(Empty loop)                      0.0000    0.0000    0.0000    0.0000
AAA                               0.0000    0.0000    0.0000    0.0000
BBBB                              0.0000    0.0000    0.0000    0.0000
CC                                0.0000    0.0000    0.0000    0.0000

## Repeat (5)                       user       sys     total      real
(Empty loop)                      0.0000    0.0000    0.0000    0.0000
AAA                               0.0000    0.0000    0.0000    0.0000
BBBB                              0.0000    0.0000    0.0000    0.0000
CC                                0.0000    0.0000    0.0000    0.0000

## Remove min & max                  min    repeat       max    repeat
AAA                               0.0000       (?)    0.0000       (?)
BBBB                              0.0000       (?)    0.0000       (?)
CC                                0.0000       (?)    0.0000       (?)

END
      actual = r.reporter.verbose_out.gsub(/-0\.0/, ' 0.0') \
                                     .gsub(/   \(\d\)/, '   (?)') \
                                     .gsub(/0\.000\d/, '0.0000')
      ok_(actual) == expected
    end

  end


  def test_print

    spec "print arg into reporter's output." do
      r = @runner
      r.print("hoge")
      ok_(r.reporter.out) == "hoge"
    end

  end


  def test_ranking

    spec "call @statistics.ranking()." do
      r = @runner
      r.bench("AAA") { x = 1 }
      tr = tracer()
      tr.trace_method(r.statistics, :ranking)
      ret = r.ranking()
      ok_(tr[0].name) == :ranking
      ok_(ret) == <<'END'
## Ranking                          real  ratio
AAA                               0.0000 (100.0) ********************
END
    end

  end


  def test_matrix

    spec "call @statistics.matrix()." do
      r = @runner
      r.bench("AAA") { x = 1 }
      tr = tracer()
      tr.trace_method(r.statistics, :matrix)
      ret = r.matrix()
      ok_(tr[0].name) == :matrix
      ok_(ret) == <<'END'
## Matrix                           real   [01]
[01] AAA                          0.0000  100.0
END
    end

  end


  def test_platform

    spec "return string containing platform information." do
      r = @runner
      s = r.platform
      ok_(s) =~ /RUBY_PLATFORM/
      ok_(s) =~ /RUBY_ENGINE/
      ok_(s) =~ /RUBY_VERSION/
      ok_(s) =~ /RUBY_PATCHLEVEL/
      ok_(s) =~ /RUBY_RELEASE_DATE/
    end

  end



end



class BenchmarkerTest
  include Oktest::TestCase


  %w[RESULT REPORTER STATISTICS RUNNER].each do |name|
    eval <<-END
      def test_SELF__#{name}
        orig = Benchmarker::#{name}
        begin
          Benchmarker.#{name} = 'foobar'
          ok_(Benchmarker::#{name}) == 'foobar'
        ensure
          Benchmarker.class_eval { remove_const :#{name}; const_set :#{name}, orig }
        end
      end
    END
  end


end
