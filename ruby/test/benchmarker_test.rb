# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

$LOAD_PATH.unshift File.class_eval { expand_path(dirname(__FILE__)) }
$LOAD_PATH.unshift File.class_eval { expand_path(join(dirname(__FILE__), '../lib')) }

require 'oktest'

BENCHMARKER_IGNORE_CMDOPTS = true
require 'benchmarker'


Oktest.scope do


+ topic(Benchmarker) do

  + topic('.new()') do
    - spec("[!2zh7w] creates new Benchmark object wit options..") do
        bm = Benchmarker.new()
        ok {bm}.is_a?(Benchmarker::Benchmark)
        ok {bm.width}   == 30
        ok {bm.loop}    == 1
        ok {bm.iter}    == 1
        ok {bm.extra}   == 0
        ok {bm.inverse} == false
        ok {bm.outfile} == nil
        #
        bm = Benchmarker.new(width: 25, loop: 100, iter: 3, extra: 2, inverse: true, outfile: "tmp.js")
        ok {bm}.is_a?(Benchmarker::Benchmark)
        ok {bm.width}   == 25
        ok {bm.loop}    == 100
        ok {bm.iter}    == 3
        ok {bm.extra}   == 2
        ok {bm.inverse} == true
        ok {bm.outfile} == "tmp.js"
      end
    - spec("[!s7y6x] overwrites existing options by command-line options.") do
        kws = {width: 15, loop: 1000, iter: 20, extra: 3, inverse: true, outfile: "tmp2.js"}
        bm = dummy_values(Benchmarker::OPTIONS, **kws) {
          Benchmarker.new()
        }
        ok {bm}.is_a?(Benchmarker::Benchmark)
        ok {bm.width}   == 15
        ok {bm.loop}    == 1000
        ok {bm.iter}    == 20
        ok {bm.extra}   == 3
        ok {bm.inverse} == true
        ok {bm.outfile} == "tmp2.js"
      end
    end

  + topic('.scope()') do
    - spec("[!4f695] creates Benchmark object, define tasks, and run them.") do
        this = self
        sout, serr = capture_sio do
          Benchmarker.scope() do
            this.ok {self}.is_a?(Benchmarker::Scope)
            task "1+1" do
              1+1
            end
            task "1-1" do
              1-1
            end
          end
        end
        ok {serr} == ""
        ok {sout} =~ /^## benchmarker: *release \d+.\d+.\d+$/
        ok {sout} =~ /^## Ranking/
        ok {sout} =~ /^1\+1 +0\./
        ok {sout} =~ /^1\-1 +0\./
        ok {sout} =~ /^## Matrix/
      end
    end

  end


+ topic(Benchmarker::Benchmark) do

    fixture :bm do
      Benchmarker::Benchmark.new
    end

  + topic('#initialize()') do
    - spec("[!0mz0f] error when filter string is invalid format.") do
        pr = proc { Benchmarker::Benchmark.new(filter: 'foobar') }
        ok {pr}.raise?(ArgumentError, "foobar: invalid filter.")
      end
    - spec("[!xo7bq] error when filter operator is invalid.") do
        pr = proc { Benchmarker::Benchmark.new(filter: 'task==foobar') }
        ok {pr}.raise?(ArgumentError, "task==foobar: expected operator is '=' or '!='.")
      end
    end

  + topic('#scope()') do
    - spec("[!wrjy0] creates wrapper object and yields block with it as self.") do |bm|
        this = self
        ret = bm.scope() do |*args|
          this.ok {self} != this
          this.ok {self}.is_a?(Benchmarker::Scope)
          this.ok {self}.respond_to?(:task)
          this.ok {self}.respond_to?(:empty_task)
        end
      end
    - spec("[!6h24d] passes benchmark object as argument of block.") do |bm|
        this = self
        bm.scope() do |*args|
          this.ok {args} == [bm]
        end
      end
    - spec("[!y0uwr] returns self.") do |bm|
        ret = bm.scope() do nil end
        ok {ret}.same?(bm)
      end
    end

  + topic('#define_empty_task()') do
    - spec("[!w66xp] creates empty task.") do |bm|
        ret = bm.define_empty_task() do nil end
        ok {ret}.is_a?(Benchmarker::Task)
        ok {ret.label} == "(Empty)"
      end
    - spec("[!qzr1s] error when called more than once.") do |bm|
        pr = proc { bm.define_empty_task() do nil end }
        ok {pr}.NOT.raise?()
        ok {pr}.raise?(RuntimeError, "cannot define empty task more than once.")
      end
    end

  + topic('#define_task()') do
    - spec("[!re6b8] creates new task.") do |bm|
        ret = bm.define_task("foobar") do nil end
        ok {ret}.is_a?(Benchmarker::Task)
        ok {ret.label} == "foobar"
      end
    - spec("[!r8o0p] can take a tag.") do |bm|
        ret = bm.define_task("balbla", tag: 'curr') do nil end
        ok {ret.tag} == "curr"
      end
    end

  + topic('#run()') do
    - spec("[!0fo0l] runs benchmark tasks and reports result.") do |bm|
        foo_called = false; bar_called = false
        bm.define_task("foo") do foo_called = true end
        bm.define_task("bar") do bar_called = true end
        ok {foo_called} == false
        ok {bar_called} == false
        sout, serr = capture_sio do
          bm.run()
        end
        ok {foo_called} == true
        ok {bar_called} == true
        ok {serr} == ""
        ok {sout} =~ /^\#\# benchmarker:/
        ok {sout} =~ /^foo +/
        ok {sout} =~ /^bar +/
      end
    end

  + topic('#filter_tasks()') do
      def new_bm(filter)
        bm = Benchmarker::Benchmark.new(filter: filter).scope do
          task "foo" do nil end
          task "bar", tag: 'xx' do nil end
          task "baz", tag: ['xx', 'yy'] do nil end
        end
        bm
      end
      def task_labels(bm)
        bm.instance_eval {@entries}.collect {|t,_| t.label}
      end
    - spec("[!f1n1v] filters tasks by task name when filer string is 'task=...'.") do
        bm = new_bm('task=bar')
        ok {task_labels(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["bar"]
        #
        bm = new_bm('task=ba*')
        ok {task_labels(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["bar", "baz"]
        #
        bm = new_bm('task=*z')
        ok {task_labels(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["baz"]
        #
        bm = new_bm('task=*xx*')
        ok {task_labels(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == []
      end
    - spec("[!m79cf] filters tasks by tag value when filer string is 'tag=...'.") do
        bm = new_bm('tag=xx')
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["bar", "baz"]
        #
        bm = new_bm('tag=yy')
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["baz"]
        #
        bm = new_bm('tag=*x')
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["bar", "baz"]
        #
        bm = new_bm('tag=zz')
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == []
      end
    - spec("[!0in0q] supports negative filter by '!=' operator.") do
        bm = new_bm('task!=bar')
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["foo", "baz"]
        #
        bm = new_bm('task!=ba*')
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["foo"]
        #
        bm = new_bm('tag!=xx')
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["foo"]
        #
        bm = new_bm('tag!=yy')
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["foo", "bar"]
      end
    - spec("[!g207d] do nothing when filter string is not provided.") do
        bm = new_bm(nil)
        bm.__send__(:filter_tasks)
        ok {task_labels(bm)} == ["foo", "bar", "baz"]
      end
    end

  + topic('#invoke_tasks()') do
      def new_bm(**kwargs)
        called = []
        bm = Benchmarker::Benchmark.new(**kwargs).scope do
          empty_task do called << :empty end
          task "foo" do called << :foo end
          task "bar" do called << :bar end
          task "baz" do called << :baz end
        end
        return bm, called
      end
      class Task2 < Benchmarker::Task
        def invoke(loop=1)
          super
          case @label
          when "(Empty)"; a = [0.002, 0.001, 0.003, 0.0031]
          when "foo"    ; a = [0.005, 0.003, 0.008, 0.0085]
          when "bar"    ; a = [0.007, 0.004, 0.011, 0.0115]
          when "baz"    ; a = [0.009, 0.005, 0.014, 0.0145]
          else          ; raise "** internal error"
          end
          Benchmarker::TimeSet.new(*a)
        end
      end
      def with_dummy_task_class()
        Benchmarker.module_eval { remove_const :TASK; const_set :TASK, Task2 }
        yield
      ensure
        Benchmarker.module_eval { remove_const :TASK; const_set :TASK, Benchmarker::Task }
      end
    - spec("[!3hgos] invokes empty task at first if defined.") do
        bm, called = new_bm()
        sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
        ok {called.first} == :empty
        ok {sout} =~ /^## +.*\n\(Empty\) +/
      end
    - spec("[!xf84h] invokes all tasks.") do
        bm, called = new_bm()
        sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
        ok {called} == [:empty, :foo, :bar, :baz]
        ok {sout} =~ /^\(Empty\) +.*\nfoo +.*\nbar +.*\nbaz +.*\n/
      end
    - spec("[!6g36c] invokes task with validator if validator defined.") do
        bm = Benchmarker::Benchmark.new().scope do
          task "foo" do 100 end
          task "bar" do 123 end
          validate do |actual, name|
            actual == 100  or
              raise "task(#{name.inspect}): #{actual.inspect} == 100: failed."
          end
        end
        pr = proc do
          capture_sio { bm.__send__(:invoke_tasks) }
        end
        ok {pr}.raise?(RuntimeError, "task(\"bar\"): 123 == 100: failed.")
      end
    - spec("[!c8yak] invokes tasks once if 'iter' option not specified.") do
        bm, called = new_bm(iter: nil)
        sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
        ok {called} == [:empty, :foo, :bar, :baz] * 1
        ok {sout} !~ /^## \(#\d\)/
      end
    - spec("[!unond] invokes tasks multiple times if 'iter' option specified.") do
        bm, called = new_bm(iter: 5)
        sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
        ok {called} == [:empty, :foo, :bar, :baz] * 5
        ok {sout} =~ /^## \(#1\)/
        ok {sout} =~ /^## \(#5\)/
      end
    - spec("[!wzvdb] invokes tasks 16 times if 'iter' is 10 and 'extra' is 3.") do
        bm, called = new_bm(iter: 10, extra: 3)
        sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
        ok {called} == [:empty, :foo, :bar, :baz] * 16
        ok {sout} =~ /^## \(#1\)/
        ok {sout} =~ /^## \(#16\)/
      end
    - spec("[!fv4cv] skips task invocation if `skip_when()` called.") do
        called = []
        bm = Benchmarker::Benchmark.new().scope do
          empty_task do called << :empty end
          task "foo" do called << :foo end
          task "bar" do skip_when true, "not installed"; called << :bar end
          task "baz" do called << :baz end
        end
        sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
        ok {called} == [:empty, :foo, :baz]    # :bar is not included
        ok {sout} =~ /^bar +\# Skipped \(reason: not installed\)$/
      end
    - spec("[!513ok] subtract timeset of empty loop from timeset of each task.") do
        with_dummy_task_class do
          bm, called = new_bm()
          sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
          sout =~ /^foo +0\.0030    0\.0020    0\.0050    0\.0054$/
          sout =~ /^bar +0\.0050    0\.0030    0\.0080    0\.0084$/
          sout =~ /^baz +0\.0070    0\.0040    0\.0110    0\.0114$/
        end
      end
    - spec("[!yg9i7] prints result unless quiet mode.") do
        with_dummy_task_class do
          bm, _ = new_bm()
          sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
          ok {sout} =~ /^## .* +user       sys     total      real$/
          ok {sout} =~ /^\(Empty\) +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} =~ /^foo +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} =~ /^bar +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} =~ /^baz +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
        end
      end
    - spec("[!94916] suppresses result if quiet mode.") do
        with_dummy_task_class do
          bm, _ = new_bm(quiet: true, iter: 2)
          sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
          ok {sout} !~ /^## .* +user       sys     total      real$/
          ok {sout} !~ /^\(Empty\) +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} !~ /^foo +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} !~ /^bar +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} !~ /^baz +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
        end
      end
    - spec("[!5axhl] prints result even on quiet mode if no 'iter' nor 'extra'.") do
        with_dummy_task_class do
          bm, _ = new_bm(quiet: true)
          sout, serr = capture_sio { bm.__send__(:invoke_tasks) }
          ok {sout} =~ /^## .* +user       sys     total      real$/
          ok {sout} =~ /^\(Empty\) +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} =~ /^foo +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} =~ /^bar +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
          ok {sout} =~ /^baz +\d+\.\d+ +\d+\.\d+ +\d+\.\d+ +\d+\.\d+$/
        end
      end
    - spec("[!knjls] records result of empty loop into JSON data.") do
        with_dummy_task_class do
          bm, _ = new_bm()
          capture_sio { bm.__send__(:invoke_tasks) }
          jdata = bm.instance_variable_get(:@jdata)
          ok {jdata}.key?(:Results)
          ok {jdata[:Results][0][0]} == ["(Empty)", 0.002, 0.001, 0.003, 0.0031]
        end
      end
    - spec("[!ejxif] records result of each task into JSON data.") do
        with_dummy_task_class do
          bm, _ = new_bm()
          capture_sio { bm.__send__(:invoke_tasks) }
          jdata = bm.instance_variable_get(:@jdata)
          ok {jdata}.key?(:Results)
          ok {jdata[:Results]} == [
            [
              ["(Empty)", 0.002, 0.001, 0.003, 0.0031],
              ["foo"    , 0.003, 0.002, 0.005, 0.0054],
              ["bar"    , 0.005, 0.003, 0.008, 0.0084],
              ["baz"    , 0.007, 0.004, 0.011, 0.0114],
            ],
          ]
          #
          bm, _ = new_bm(iter: 3)
          capture_sio { bm.__send__(:invoke_tasks) }
          jdata = bm.instance_variable_get(:@jdata)
          ok {jdata}.key?(:Results)
          result = [
            ["(Empty)", 0.002, 0.001, 0.003, 0.0031],
            ["foo"    , 0.003, 0.002, 0.005, 0.0054],
            ["bar"    , 0.005, 0.003, 0.008, 0.0084],
            ["baz"    , 0.007, 0.004, 0.011, 0.0114],
          ]
          ok {jdata[:Results]} == [result, result, result]
        end
      end
    end

  + topic('#ignore_skipped_tasks()') do
      def task_labels(bm)
        bm.instance_eval {@entries}.collect {|t,_| t.label}
      end
    - spec("[!5gpo7] removes skipped tasks and leaves other tasks.") do
        bm = Benchmarker::Benchmark.new().scope do
          empty_task do nil end
          task "foo" do skip_when true, "not installed"; nil end
          task "bar" do skip_when true, "not installed"; nil end
          task "baz" do nil end
        end
        capture_sio { bm.__send__(:invoke_tasks) }
        ok {task_labels(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:ignore_skipped_tasks)
        ok {task_labels(bm)} == ["baz"]
      end
    end

  + topic('#report_environment()') do
    - spec("[!rx7nn] prints ruby version, platform, several options, and so on.") do
        bm = Benchmarker::Benchmark.new(title: "string concat", loop: 1000, inverse: true)
        sout, serr = capture_sio { bm.__send__(:report_environment) }
        ok {serr} == ""
        ok {sout} =~ /^## title: +string concat$/
        ok {sout} =~ /^## options: +loop=1000, iter=1, extra=0, inverse=true$/
        ok {sout} =~ /^## benchmarker: +release \d+\.\d+\.\d+$/
        ok {sout} =~ /^## ruby engine: +\w+ \(engine version .*\)$/
        ok {sout} =~ /^## ruby platform: +.+$/
        ok {sout} =~ /^## ruby path: +.+$/
        ok {sout} =~ /^## compiler: +.*$/
        ok {sout} =~ /^## cpu model: +.+$/
      end
    end

    fixture :bm5 do
      bm = Benchmarker::Benchmark.new(iter: 5, extra: 2).scope do
        task "foo" do nil end
        task "bar" do nil end
      end
      entries = bm.instance_eval{@entries}
      #ok {entries[0][1]}.is_a?(Benchmarker::Result)
      #ok {entries[1][1]}.is_a?(Benchmarker::Result)
      #
      entries[0][1].add(Benchmarker::TimeSet.new(1.1, 2.1, 3.1, 4.3))
      entries[0][1].add(Benchmarker::TimeSet.new(1.2, 2.2, 3.2, 4.1))
      entries[0][1].add(Benchmarker::TimeSet.new(1.3, 2.3, 3.3, 4.4))
      entries[0][1].add(Benchmarker::TimeSet.new(1.4, 2.4, 3.4, 4.5))
      entries[0][1].add(Benchmarker::TimeSet.new(1.5, 2.5, 3.5, 4.9))
      entries[0][1].add(Benchmarker::TimeSet.new(1.6, 2.6, 3.6, 4.2))
      entries[0][1].add(Benchmarker::TimeSet.new(1.7, 2.7, 3.7, 4.6))
      entries[0][1].add(Benchmarker::TimeSet.new(1.8, 2.8, 3.8, 4.8))
      entries[0][1].add(Benchmarker::TimeSet.new(1.9, 2.9, 3.9, 4.7))
      #
      entries[1][1].add(Benchmarker::TimeSet.new(1.1, 2.1, 3.1, 4.3))
      entries[1][1].add(Benchmarker::TimeSet.new(1.2, 2.2, 3.2, 4.1))
      entries[1][1].add(Benchmarker::TimeSet.new(1.3, 2.3, 3.3, 4.4))
      entries[1][1].add(Benchmarker::TimeSet.new(1.4, 2.4, 3.4, 4.5))
      entries[1][1].add(Benchmarker::TimeSet.new(1.5, 2.5, 3.5, 4.9))
      entries[1][1].add(Benchmarker::TimeSet.new(1.6, 2.6, 3.6, 4.2))
      entries[1][1].add(Benchmarker::TimeSet.new(1.7, 2.7, 3.7, 4.6))
      entries[1][1].add(Benchmarker::TimeSet.new(1.8, 2.8, 3.8, 4.8))
      entries[1][1].add(Benchmarker::TimeSet.new(1.9, 2.9, 3.9, 4.7))
      #
      bm
    end

  + topic('#_removed_minmax()') do
    - spec("[!uxe7e] removes best and worst results if 'extra' option specified.") do |bm5|
        bm5.__send__(:_remove_minmax)
        arr = bm5.instance_eval{@entries}.collect {|task, r|
          real_list = []
          r.each {|t| real_list << t.real }
          [task.label, real_list]
        }
        ok {arr} == [
          ["foo", [4.30, 4.40, 4.50, 4.60, 4.70]],
          ["bar", [4.30, 4.40, 4.50, 4.60, 4.70]],
        ]
      end
    - spec("[!is6ll] returns removed min and max data.") do |bm5|
        rows = bm5.__send__(:_remove_minmax)
        ok {rows} == [
          ["foo", 4.10, "(#2)", 4.90, "(#5)"],
          [nil  , 4.20, "(#6)", 4.80, "(#8)"],
          ["bar", 4.10, "(#2)", 4.90, "(#5)"],
          [nil  , 4.20, "(#6)", 4.80, "(#8)"],
        ]
      end
    - spec("[!xwddz] sets removed best and worst results into JSON data.") do |bm5|
        bm5.__send__(:_remove_minmax)
        ok {bm5.instance_eval{@jdata}} == {
          :RemovedMinMax => [
            ["foo", 4.10, "(#2)", 4.90, "(#5)"],
            [nil  , 4.20, "(#6)", 4.80, "(#8)"],
            ["bar", 4.10, "(#2)", 4.90, "(#5)"],
            [nil  , 4.20, "(#6)", 4.80, "(#8)"],
          ]
        }
      end
    end

  + topic('#_render_minmax()') do
    - spec("[!p71ax] returns rendered string.") do |bm5|
        rows = bm5.__send__(:_remove_minmax)
        str = bm5.__send__(:_render_minmax, rows)
        ok {str} == <<'END'

## Removed Min & Max                 min      iter       max      iter
foo                               4.1000      (#2)    4.9000      (#5)
                                  4.2000      (#6)    4.8000      (#8)
bar                               4.1000      (#2)    4.9000      (#5)
                                  4.2000      (#6)    4.8000      (#8)
END
      end
    end

  + topic('#_calc_average()') do
    - spec("[!qu29s] calculates average of real times for each task.") do |bm5|
        rows = bm5.__send__(:_calc_average)
        ok {rows} == [
          ["foo", 1.50, 2.50, 3.50, 4.50],
          ["bar", 1.50, 2.50, 3.50, 4.50],
        ]
      end
    - spec("[!jxf28] sets average results into JSON data.") do |bm5|
        bm5.__send__(:_calc_average)
        ok {bm5.instance_eval{@jdata}} == {
          :Average => [
            ["foo", 1.50, 2.50, 3.50, 4.50],
            ["bar", 1.50, 2.50, 3.50, 4.50],
          ]
        }
      end
    end

  + topic('#_render_average()') do
    - spec("[!j9wlv] returns rendered string.") do |bm5|
        rows = bm5.__send__(:_calc_average)
        str = bm5.__send__(:_render_average, rows)
        ok {str} == <<'END'

## Average of 5 (=9-2*2)            user       sys     total      real
foo                               1.5000    2.5000    3.5000    4.5000
bar                               1.5000    2.5000    3.5000    4.5000
END
      end
    end

  + topic('#report_stats()') do
    - spec("[!0jn7d] sorts results by real sec.") do
        bm = Benchmarker::Benchmark.new().scope do
          task "foo" do nil end
          task "bar" do nil end
          task "baz" do nil end
        end
        entries = bm.instance_eval{@entries}
        entries[0][1].add(Benchmarker::TimeSet.new(1.1, 2.1, 3.2, 4.3))
        entries[1][1].add(Benchmarker::TimeSet.new(1.1, 2.1, 3.2, 3.3))
        entries[2][1].add(Benchmarker::TimeSet.new(1.1, 2.1, 3.2, 5.3))
        #
        sout, serr = capture_sio { bm.__send__(:report_stats) }
        ok {sout} == <<'END'

## Ranking                          real
bar                               3.3000 (100.0%) ********************
foo                               4.3000 ( 76.7%) ***************
baz                               5.3000 ( 62.3%) ************

## Matrix                           real      [1]      [2]      [3]
[1] bar                           3.3000   100.0%   130.3%   160.6%
[2] foo                           4.3000    76.7%   100.0%   123.3%
[3] baz                           5.3000    62.3%    81.1%   100.0%
END
      end
    end

    fixture :pairs do
      [
        ["foo", 1.11],
        ["bar", 2.22],
        ["baz", 3.33],
      ]
    end

  + topic('#_render_ranking()') do
    - spec("[!2lu55] calculates ranking data and sets it into JSON data.") do |bm, pairs|
        bm.__send__(:_render_ranking, pairs)
        ok {bm.instance_eval{@jdata}} == {
          :Ranking => [
            ["foo", 1.11, "100.0%", "0.90 times/sec", "********************"],
            ["bar", 2.22,  "50.0%", "0.45 times/sec", "**********"          ],
            ["baz", 3.33,  "33.3%", "0.30 times/sec", "*******"             ],
          ]
        }
      end
    - spec("[!55x8r] returns rendered string of ranking.") do |bm, pairs|
        str = bm.__send__(:_render_ranking, pairs)
        ok {str} == <<'END'

## Ranking                          real
foo                               1.1100 (100.0%) ********************
bar                               2.2200 ( 50.0%) **********
baz                               3.3300 ( 33.3%) *******
END
      end
    end

  + topic('#_render_matrix()') do
    - spec("[!2lu55] calculates ranking data and sets it into JSON data.") do |bm, pairs|
        bm.__send__(:_render_matrix, pairs)
        ok {bm.instance_eval{@jdata}} == {
          :Matrix => [
            ["[1] foo", 1.11, "100.0%", "200.0%", "300.0%"],
            ["[2] bar", 2.22,  "50.0%", "100.0%", "150.0%"],
            ["[3] baz", 3.33,  "33.3%",  "66.7%", "100.0%"],
          ]
        }
      end
    - spec("[!rwfxu] returns rendered string of matrix.") do |bm, pairs|
        str = bm.__send__(:_render_matrix, pairs)
        ok {str} == <<'END'

## Matrix                           real      [1]      [2]      [3]
[1] foo                           1.1100   100.0%   200.0%   300.0%
[2] bar                           2.2200    50.0%   100.0%   150.0%
[3] baz                           3.3300    33.3%    66.7%   100.0%
END
      end
    end

  + topic('#write_outfile()') do
    - spec("[!o8ah6] writes result data into JSON file if 'outfile' option specified.") do
        tmpfile = "tmp#{rand().to_s[2..6]}.json"
        at_end { File.unlink tmpfile if File.exist?(tmpfile) }
        jdata = {
          :Ranking => [
            ["foo", 1.11, "100.0%", "0.90 times/sec", "********************"],
            ["bar", 2.22,  "50.0%", "0.45 times/sec", "**********"          ],
            ["baz", 3.33,  "33.3%", "0.30 times/sec", "*******"             ],
          ],
          :Matrix => [
            ["[1] foo", 1.11, "100.0%", "200.0%", "300.0%"],
            ["[2] bar", 2.22,  "50.0%", "100.0%", "150.0%"],
            ["[3] baz", 3.33,  "33.3%",  "66.7%", "100.0%"],
          ],
        }
        #
        bm1 = Benchmarker::Benchmark.new()
        bm1.instance_eval { @jdata = jdata }
        bm1.__send__(:write_outfile)
        ok {tmpfile}.NOT.file_exist?
        #
        bm2 = Benchmarker::Benchmark.new(outfile: tmpfile)
        bm2.instance_eval { @jdata = jdata }
        bm2.__send__(:write_outfile)
        ok {tmpfile}.file_exist?
        actual = JSON.load(File.read(tmpfile))
        ok {actual} == {"Ranking"=>jdata[:Ranking], "Matrix"=>jdata[:Matrix]}
      end
    end

  end


+ topic(Benchmarker::Scope) do

    fixture :scope do
      bm = Benchmarker::Benchmark.new()
      scope = Benchmarker::Scope.new(bm)
      scope
    end

  + topic('#task()') do
    - spec("[!j6pmr] creates new task object.") do |scope|
        task = scope.task "label1", tag: "abc" do end
        ok {task}.is_a?(Benchmarker::Task)
        ok {task.label} == "label1"
        ok {task.tag} == "abc"
      end
    - spec("[!kh7r9] define empty-loop task if label is nil.") do |scope|
        task = scope.task nil do end
        ok {task}.is_a?(Benchmarker::Task)
        ok {task.label} == "(Empty)"
      end
    end

  + topic('#empty_task()') do
    - spec("[!ycoch] creates new empty-loop task object.") do |scope|
        task = scope.empty_task do end
        ok {task}.is_a?(Benchmarker::Task)
        ok {task.label} == "(Empty)"
      end
    end

  + topic('#skip_when()') do
    - spec("[!dva3z] raises SkipTask exception if cond is truthy.") do |scope|
        pr = proc { scope.skip_when(true, "not installed") }
        ok {pr}.raise?(Benchmarker::SkipTask, "not installed")
      end
    - spec("[!srlnu] do nothing if cond is falthy.") do |scope|
        pr = proc { scope.skip_when(false, "not installed") }
        ok {pr}.NOT.raise?
      end
    end

  + topic('#validate()') do
    - spec("[!q2aev] defines validator.") do
        bm = Benchmarker::Benchmark.new()
        scope = Benchmarker::Scope.new(bm)
        ok {bm.instance_eval{@validator}} == nil
        scope.validate do |ret| end
        ok {bm.instance_eval{@validator}} != nil
        ok {bm.instance_eval{@validator}}.is_a?(Proc)
      end
    end

  + topic('#assert()') do
    - spec("[!a0c7e] do nothing if assertion succeeded.") do |scope|
        capture_sio do
          pr = proc { scope.assert 1+1 == 2, "1+1 is 2" }
          ok {pr}.NOT.raise?
        end
      end
    - spec("[!5vmbc] raises error if assertion failed.") do |scope|
        capture_sio do
          pr = proc { scope.assert 1+1 == 1, "1+1 is not 1" }
          ok {pr}.raise?(Benchmarker::ValidationFailed, "1+1 is not 1")
        end
      end
    - spec("[!7vt5l] puts newline if assertion failed.") do |scope|
        sout, serr = capture_sio do
          pr = proc { scope.assert true, "" }
          ok {pr}.NOT.raise?(Benchmarker::ValidationFailed)
        end
        ok {sout} == ""
        #
        sout, serr = capture_sio do
          pr = proc { scope.assert false, "" }
          ok {pr}.raise?(Benchmarker::ValidationFailed)
        end
        ok {sout} == "\n"
      end
    - spec("[!mhw59] makes error backtrace compact.") do |scope|
        capture_sio do
          pr = proc { scope.assert false, "" }
          ok {pr}.raise?(Benchmarker::ValidationFailed) do |exc|
            ok {exc.backtrace}.all? {|x| x !~ /benchmarker\.rb/ }
          end
        end
      end
    end

  + topic('#assert_eq()') do
    - spec("[!8m6bh] do nothing if ectual == expected.") do |scope|
        capture_sio do
          pr = proc { scope.assert_eq 1+1, 2 }
          ok {pr}.NOT.raise?
        end
      end
    - spec("[!f9ey6] raises error unless actual == expected.") do |scope|
        capture_sio do
          pr = proc { scope.assert_eq 'a'*3, 'aa' }
          ok {pr}.raise?(Benchmarker::ValidationFailed, '"aaa" == "aa": failed.')
        end
      end
    end

  end


+ topic(Benchmarker::Task) do

  + topic('#invoke()') do
    - spec("[!tgql6] invokes block N times.") do
        cnt = 0
        task = Benchmarker::Task.new("label1") do cnt += 1 end
        task.invoke(3)
        ok {cnt} == 3
      end
    - spec("[!9e5pr] returns TimeSet object.") do
        task = Benchmarker::Task.new("label1") do nil end
        ret = task.invoke()
        ok {ret}.is_a?(Benchmarker::TimeSet)
      end
    - spec("[!zw4kt] yields validator with returned value of block.") do
        task = Benchmarker::Task.new("label1") do 234 end
        args = nil
        task.invoke() do |*a| args = a end
        ok {args} == [234, "label1"]
      end
    end

  end


+ topic(Benchmarker::TimeSet) do

  + topic('#-()') do
    - spec("[!cpwgf] returns new TimeSet object.") do
        t1 = Benchmarker::TimeSet.new(2.0, 3.0, 4.0, 5.0)
        t2 = Benchmarker::TimeSet.new(2.5, 3.5, 5.0, 5.25)
        t3 = t2 - t1
        ok {t3} != t1
        ok {t3} != t2
        ok {t3.user}  == 0.5
        ok {t3.sys}   == 0.5
        ok {t3.total} == 1.0
        ok {t3.real}  == 0.25
      end
    end

  end


+ topic(Benchmarker::Result) do

    fixture :r do
      Benchmarker::Result.new
    end

  + topic('#add()') do
    - spec("[!thyms] adds timeset and returns self.") do |r|
        t = Benchmarker::TimeSet.new(1.0, 2.0, 3.0, 4.0)
        r.add(t)
        ok {r[0]} == t
      end
    end

  + topic('#skipped?') do
    - spec("[!bvzk9] returns true if reason has set, or returns false.") do |r|
        ok {r.skipped?} == false
        r.skipped = "why skipped"
        ok {r.skipped?} == true
      end
    end

  + topic('#remove_minmax()') do
    - spec("[!b55zh] removes best and worst timeset and returns them.") do |r|
        klass = Benchmarker::TimeSet
        arr = [
          klass.new(0.1, 0.1, 0.1, 0.3),
          klass.new(0.1, 0.1, 0.1, 0.1),
          klass.new(0.1, 0.1, 0.1, 0.4),
          klass.new(0.1, 0.1, 0.1, 0.5),
          klass.new(0.1, 0.1, 0.1, 0.9),
          klass.new(0.1, 0.1, 0.1, 0.2),
          klass.new(0.1, 0.1, 0.1, 0.6),
          klass.new(0.1, 0.1, 0.1, 0.8),
          klass.new(0.1, 0.1, 0.1, 0.7),
        ]
        #
        r1 = Benchmarker::Result.new
        arr.each {|t| r1.add(t) }
        removed = r1.remove_minmax(1)
        ok {removed} == [
          [0.1, 2, 0.9, 5],
        ]
        vals = []; r1.each {|t| vals << t.real }
        ok {vals} == [0.3, 0.4, 0.5, 0.2, 0.6, 0.8, 0.7]
        #
        r2 = Benchmarker::Result.new
        arr.each {|t| r2.add(t) }
        removed = r2.remove_minmax(2)
        ok {removed} == [
          [0.1, 2, 0.9, 5],
          [0.2, 6, 0.8, 8],
        ]
        vals = []; r2.each {|t| vals << t.real }
        ok {vals} == [0.3, 0.4, 0.5, 0.6, 0.7]
      end
    end

  + topic('#calc_average()') do
    - spec("[!b91w3] returns average of timeddata.") do |r|
        klass = Benchmarker::TimeSet
        arr = [
          klass.new(0.1, 0.1, 0.3, 0.3),
          klass.new(0.2, 0.1, 0.3, 0.1),
          klass.new(0.3, 0.1, 0.3, 0.4),
          klass.new(0.4, 0.1, 0.3, 0.5),
          klass.new(0.5, 0.1, 0.3, 0.9),
          klass.new(0.6, 0.1, 0.3, 0.2),
          klass.new(0.7, 0.1, 0.3, 0.6),
          klass.new(0.8, 0.1, 0.3, 0.8),
          klass.new(0.9, 0.1, 0.3, 0.7),
        ]
        arr.each {|t| r.add(t) }
        t = r.calc_average()
        ok {t}.is_a?(klass)
        ok {t.user }.in_delta?(0.5, 0.000000001)
        ok {t.sys  }.in_delta?(0.1, 0.000000001)
        ok {t.total}.in_delta?(0.3, 0.000000001)
        ok {t.real }.in_delta?(0.5, 0.000000001)
      end

    end

  end


+ topic(Benchmarker::Misc) do

  + topic('.environment_info()') do
    - spec("[!w1xfa] returns environment info in key-value list.") do
        arr = Benchmarker::Misc.environment_info()
        ok {arr}.is_a?(Array)
        ok {arr[0][0]} == "benchmarker"
        ok {arr[1][0]} == "ruby engine"
        ok {arr[2][0]} == "ruby version"
        ok {arr[3][0]} == "ruby platform"
        ok {arr[4][0]} == "ruby path"
        ok {arr[5][0]} == "compiler"
        ok {arr[6][0]} == "cpu model"
      end
    end

  + topic('.cpu_model()') do
    - spec("[!6ncgq] returns string representing cpu model.") do
        str = Benchmarker::Misc.cpu_model()
        ok {str}.is_a?(String)
      end
    - spec("") do
      end
    - spec("") do
      end
    end

  end


+ topic(Benchmarker::OptionParser) do

    fixture :p do
      Benchmarker::OptionParser.new("hvq", "wnixoF", "I")
    end

  + topic('#parse()') do
    - spec("[!2gq7g] returns options and keyvals.")do |p|
        argv = ['-hqn100', '-i', '5', '-I', '--help', '--foo=bar']
        options, keyvals = p.parse(argv)
        ok {options} == {'h'=>true, 'q'=>true, 'n'=>'100', 'i'=>'5', 'I'=>true}
        ok {keyvals} == {'help'=>true, 'foo'=>'bar'}
        ok {argv} == []
      end
    - spec("[!ulfpu] stops parsing when '--' found.") do |p|
        argv = ['-h', '--', '-i', '5']
        options, keyvals = p.parse(argv)
        ok {options} == {'h'=>true}
        ok {keyvals} == {}
        ok {argv} == ['-i', '5']
      end
    - spec("[!8f085] regards '--long=option' as key-value.") do |p|
        argv = ['--foo=bar', '--baz']
        options, keyvals = p.parse(argv)
        ok {options} == {}
        ok {keyvals} == {'foo'=>'bar', 'baz'=>true}
        ok {argv} == []
      end
    - spec("[!dkq1u] parses short options.") do |p|
        argv = ['-h', '-qn100', '-vi', '10', '-x', '2']
        options, keyvals = p.parse(argv)
        ok {options} == {'h'=>true, 'q'=>true, 'n'=>'100', 'v'=>true, 'i'=>'10', 'x'=>'2'}
        ok {keyvals} == {}
        ok {argv} == []
      end
    - spec("[!8xqla] error when required argument is not provided.") do |p|
        argv = ['-qn']
        a_ = nil
        p.parse(argv) do |*a| a_ = a end
        ok {a_} == ["-n: argument required."]
      end
    - spec("[!tmx6o] error when option is unknown.") do |p|
        argv = ['-hz']
        a_ = nil
        p.parse(argv) do |*a| a_ = a end
        ok {a_} == ["-z: unknown option."]
      end
    end

  + topic('.parse_options()') do
    - spec("[!v19y5] converts option argument into integer if necessary.") do
        argv = ['-h', '-n100', '-vi', '10', '-x', '2', '-I5000']
        options, keyvals = Benchmarker::OptionParser.parse_options(argv)
        ok {options} == {"h"=>true, "n"=>100, "v"=>true, "i"=>10, "x"=>2, "I"=>5000}
        ok {keyvals} == {}
      end
    - spec("[!frfz2] yields error message when argument of '-n/i/x/I' is not an integer.") do
        err = nil
        Benchmarker::OptionParser.parse_options(['-nxx']) do |s| err = s end
        ok {err} == "-n xx: integer expected."
        #
        err = nil
        Benchmarker::OptionParser.parse_options(['-iyy']) do |s| err = s end
        ok {err} == "-i yy: integer expected."
        #
        err = nil
        Benchmarker::OptionParser.parse_options(['-xzz']) do |s| err = s end
        ok {err} == "-x zz: integer expected."
        #
        err = nil
        Benchmarker::OptionParser.parse_options(['-Izz']) do |s| err = s end
        ok {err} == "-Izz: integer expected."
      end
    - spec("[!emavm] yields error message when argumetn of '-F' option is invalid.") do
        err = nil
        Benchmarker::OptionParser.parse_options(['-F', 'xyz']) do |s| err = s end
        ok {err} == "-F xyz: invalid filter (expected operator is '=' or '!=')."
        #
        err = nil
        Benchmarker::OptionParser.parse_options(['-F', 'label=xyz']) do |s| err = s end
        ok {err} == "-F label=xyz: expected 'task=...' or 'tag=...'."
      end
    end

  + topic('.help_message()') do
    - spec("[!jnm2w] returns help message.") do
        msg = Benchmarker::OptionParser.help_message("bench.rb")
        ok {msg} == <<'END'
Usage: bench.rb [<options>]
  -h, --help     : help message
  -v             : print Benchmarker version
  -w <N>         : width of task label (default: 30)
  -n <N>         : loop N times in each benchmark (default: 1)
  -i <N>         : iterates all benchmark tasks N times (default: 1)
  -x <N>         : ignore worst N results and best N results (default: 0)
  -I[<N>]        : print inverse number (= N/sec) (default: same as '-n')
  -o <file>      : output file in JSON format
  -q             : quiet a little (suppress output of each iteration)
  -F task=<...>  : filter benchmark task by name (operator: '=' or '!=')
  -F tag=<...>   : filter benchmark task by tag (operator: '=' or '!=')
  --<key>[=<val>]: define global variable `$var = "val"`
END
      end
    end

  end


+ topic(Benchmarker) do

    after do
      Benchmarker::OPTIONS.clear()
    end

  + topic('.parse_cmdopts()') do
    - spec("[!348ip] parses command-line options.") do
        ok {Benchmarker::OPTIONS} == {}
        argv = "-q -n 1000 -i10 -x2 -I -o tmp.json".split()
        options, keyvals = Benchmarker.parse_cmdopts(argv)
        ok {options} == {'q'=>true, 'n'=>1000, 'i'=>10, 'x'=>2, 'I'=>true, 'o'=>"tmp.json"}
        ok {keyvals} == {}
      end
    - spec("[!snqxo] exits with status code 1 if error in command option.") do
        argv = ["-n abc"]
        sout, serr = capture_sio do
          pr = proc { Benchmarker.parse_cmdopts(argv) }
          ok {pr}.raise?(SystemExit) do |exc|
            ok {exc.status} == 1
          end
        end
        ok {serr} == "-n  abc: integer expected.\n"
        ok {sout} == ""
      end
    - spec("[!p3b93] prints help message if '-h' or '--help' option specified.") do
        ["-h", "--help"].each do |arg|
          sout, serr = capture_sio do
            pr = proc { Benchmarker.parse_cmdopts([arg]) }
            ok {pr}.raise?(SystemExit) do |exc|
              ok {exc.status} == 0
            end
          end
          ok {serr} == ""
          ok {sout} =~ /^Usage: \S+ \[<options>\]$/
          ok {sout} =~ /^  -h, --help     : help message$/
        end
      end
    - spec("[!iaryj] prints version number if '-v' option specified.") do
        argv = ["-v"]
        sout, serr = capture_sio do
          pr = proc { Benchmarker.parse_cmdopts(argv) }
          ok {pr}.raise?(SystemExit) do |exc|
            ok {exc.status} == 0
          end
        end
        ok {serr} == ""
        ok {sout} == Benchmarker::VERSION + "\n"
      end
    - spec("[!s7y6x] keeps command-line options in order to overwirte existing options.") do
        ok {Benchmarker::OPTIONS} == {}
        argv = "-q -n 1000 -i10 -x2 -I -o tmp.json".split()
        Benchmarker.parse_cmdopts(argv)
        ok {Benchmarker::OPTIONS} == {
          :quiet=>true, :loop=>1000, :iter=>10, :extra=>2,
          :inverse=>true, :outfile=>"tmp.json",
        }
      end
    - spec("[!nexi8] option '-w' specifies task label width.") do
        Benchmarker.parse_cmdopts(['-w', '10'])
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do nil end
          end
        end
        ok {sout} =~ /^foo           0.0000/
      end
    - spec("[!raki9] option '-n' specifies count of loop.") do
        Benchmarker.parse_cmdopts(['-n', '17'])
        count = 0
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do count += 1 end
          end
        end
        ok {count} == 17
      end
    - spec("[!mt7lw] option '-i' specifies number of iteration.") do
        Benchmarker.parse_cmdopts(['-i', '5'])
        count = 0
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do count += 1 end
          end
        end
        ok {sout} =~ /^## \(#5\)/
        ok {sout} !~ /^## \(#6\)/
        n = 0
        sout.scan(/^## \(#\d+\).*\nfoo +/) do n += 1 end
        ok {n} == 5
        ok {sout} !~ /^## Removed Min & Max/
        ok {sout} =~ /^## Average of 5 +user/
      end
    - spec("[!7f2k3] option '-x' specifies number of best/worst tasks removed.") do
        Benchmarker.parse_cmdopts(['-i', '5', '-x', '1'])
        count = 0
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do count += 1 end
          end
        end
        ok {sout} =~ /^## \(#7\)/
        ok {sout} !~ /^## \(#8\)/
        n = 0
        sout.scan(/^## \(#\d+\).*\nfoo +/) do n += 1 end
        ok {n} == 7
        ok {sout} =~ /^## Removed Min & Max/
        ok {sout} =~ /^## Average of 5 \(=7-2\*1\)/
      end
    - spec("[!r0439] option '-I' specifies inverse switch.") do
        Benchmarker.parse_cmdopts(['-I'])
        sout, serr = capture_sio do
          fib = proc {|n| n <= 1 ? n : fib.call(n-1) + fib.call(n-2) }
          Benchmarker.scope(width: 20) do
            task "foo" do fib.call(15) end
          end
        end
        ok {sout} =~ /^## Ranking                real                     times\/sec$/
        ok {sout} =~ /^foo +\d+\.\d+ \(100\.0%\) +\d+\.\d+$/
      end
    - spec("[!4c73x] option '-o' specifies outout JSON file.") do
        Benchmarker.parse_cmdopts(['-I'])
        sout, serr = capture_sio do
          fib = proc {|n| n <= 1 ? n : fib.call(n-1) + fib.call(n-2) }
          Benchmarker.scope(width: 20) do
            task "foo" do fib.call(15) end
          end
        end
        ok {sout} =~ /^## Ranking                real                     times\/sec$/
        ok {sout} =~ /^foo +\d+\.\d+ \(100\.0%\) +\d+\.\d+$/
      end
    - spec("[!02ml5] option '-q' specifies quiet mode.") do
        Benchmarker.parse_cmdopts(['-q', '-i10', '-x1'])
        count = 0
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do count += 1 end
          end
        end
        ok {count} == 12
        ok {sout} !~ /^## \(#\d\)/
        ok {sout} =~ /^## Removed Min & Max/
        ok {sout} =~ /^## Average of 10 \(=12-2\*1\)/
      end
    - spec("[!muica] option '-F' specifies filter.") do
        Benchmarker.parse_cmdopts(['-F', 'task=ba*'])
        called = []
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do called << "foo" end
            task "bar", tag: 'curr' do called << "bar" end
            task "baz" do called << "baz" end
          end
        end
        ok {called} == ["bar", "baz"]
        #
        Benchmarker.parse_cmdopts(['-F', 'tag!=curr'])
        called = []
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do called << "foo" end
            task "bar", tag: 'curr' do called << "bar" end
            task "baz" do called << "baz" end
          end
        end
        ok {called} == ["foo", "baz"]
      end
    - spec("[!3khc4] sets global variables if long option specified.") do
        ok {$blabla} == nil
        Benchmarker.parse_cmdopts(['--blabla=123'])
        ok {$blabla} == "123"
      end
    end
  end


end
