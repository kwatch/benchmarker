# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

$LOAD_PATH.unshift File.class_eval { join(dirname(dirname(__FILE__)), 'lib') }

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

  + topic('#clear()') do
    - spec("[!phqdn] clears benchmark result and JSON data.") do |bm|
        bm.scope do
          task "foo" do nil end
          task "bar" do nil end
        end
        capture_sio { bm.run() }
        result_foo = bm.instance_eval{@entries[0][1]}
        result_bar = bm.instance_eval{@entries[1][1]}
        ok {result_foo.length} == 1
        ok {result_bar.length} == 1
        #
        bm.clear()
        ok {result_foo.length} == 0
        ok {result_bar.length} == 0
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
        ok {bm.instance_eval{@empty_task}} == nil
        ret = bm.define_empty_task() do nil end
        ok {bm.instance_eval{@empty_task}} != nil
        ok {bm.instance_eval{@empty_task}}.is_a?(Benchmarker::Task)
        ok {bm.instance_eval{@empty_task}.name} == nil
        ok {ret}.is_a?(Benchmarker::Task)
        ok {ret.name} == nil
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
        ok {ret.name} == "foobar"
      end
    - spec("[!r8o0p] can take a tag.") do |bm|
        ret = bm.define_task("balbla", tag: 'curr') do nil end
        ok {ret.tag} == "curr"
      end
    end

  + topic('#define_hook()') do |bm|
    - spec("[!2u53t] register proc object with symbol key.") do |bm|
        called = false
        bm.define_hook(:hook1) do called = true end
        ok {called} == false
        bm.__send__(:call_hook, :hook1)
        ok {called} == true
      end
    end

  + topic('#call_hook()') do |bm|
    - spec("[!0to2s] calls hook with arguments.") do |bm|
        args = nil
        bm.define_hook(:hook2) do |*a| args = a end
        ok {args} == nil
        bm.__send__(:call_hook, :hook2, "abc", tag: "xyz")
        ok {args} == ["abc", {tag: "xyz"}]
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
    - spec("[!6h26u] runs preriminary round when `warmup: true` provided.") do |bm|
        called = 0
        bm.define_task("foo") do called += 1 end
        sout, serr = capture_sio do
          bm.run(warmup: true)
        end
        ok {called} == 2
        n = 0
        sout.scan(/^##  +.*\nfoo +/) { n += 1 }
        ok {n} == 1
      end
    - spec("[!2j4ks] calls 'before_all' hook.") do |bm|
        called = 0
        bm.define_hook(:before_all) do called += 1 end
        ok {called} == 0
        capture_sio { bm.run() }
        ok {called} == 1
      end
    - spec("[!w1rq7] calls 'after_all' hook even if error raised.") do |bm|
        called = 0
        bm.define_hook(:after_all) do called += 1 end
        bm.define_task("foo") do 1/0 end   # raises ZeroDivisionError
        ok {called} == 0
        capture_sio do
          pr = proc { bm.run() }
          ok {pr}.raise?(ZeroDivisionError)
        end
        ok {called} == 1
      end
    end

  + topic('#_ignore_output()') do
    - spec("[!wazs7] ignores output in block argument.") do |bm|
        called = false
        sout, serr = capture_sio do
          puts "aaa"
          bm.__send__(:_ignore_output) do
            puts "bbb"
            called = true
          end
          puts "ccc"
        end
        ok {called} == true
        ok {sout} == "aaa\nccc\n"
        ok {serr} == ""
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
      def task_names(bm)
        bm.instance_eval {@entries}.collect {|t,_| t.name}
      end
    - spec("[!f1n1v] filters tasks by task name when filer string is 'task=...'.") do
        bm = new_bm('task=bar')
        ok {task_names(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["bar"]
        #
        bm = new_bm('task=ba*')
        ok {task_names(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["bar", "baz"]
        #
        bm = new_bm('task=*z')
        ok {task_names(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["baz"]
        #
        bm = new_bm('task=*xx*')
        ok {task_names(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == []
      end
    - spec("[!m79cf] filters tasks by tag value when filer string is 'tag=...'.") do
        bm = new_bm('tag=xx')
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["bar", "baz"]
        #
        bm = new_bm('tag=yy')
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["baz"]
        #
        bm = new_bm('tag=*x')
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["bar", "baz"]
        #
        bm = new_bm('tag=zz')
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == []
      end
    - spec("[!0in0q] supports negative filter by '!=' operator.") do
        bm = new_bm('task!=bar')
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["foo", "baz"]
        #
        bm = new_bm('task!=ba*')
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["foo"]
        #
        bm = new_bm('tag!=xx')
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["foo"]
        #
        bm = new_bm('tag!=yy')
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["foo", "bar"]
      end
    - spec("[!g207d] do nothing when filter string is not provided.") do
        bm = new_bm(nil)
        bm.__send__(:filter_tasks)
        ok {task_names(bm)} == ["foo", "bar", "baz"]
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
          case @name
          when nil      ; a = [0.002, 0.001, 0.003, 0.0031]
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
    - spec("[!hbass] calls 'before' hook with task name and tag.") do
        called = 0
        argslist = []
        bm = Benchmarker::Benchmark.new().scope do
          before do |*a| called += 1; argslist << a end
          task "foo" do nil end
          task "bar", tag: 'yy' do nil end
        end
        ok {called} == 0
        ok {argslist} == []
        capture_sio { bm.__send__(:invoke_tasks) }
        ok {called} == 2
        ok {argslist} == [["foo", nil], ["bar", 'yy']]
      end
    - spec("[!7960c] calls 'after' hook with task name and tag even if error raised.") do
        called = 0
        argslist = []
        bm = Benchmarker::Benchmark.new().scope do
          after do |*a| called += 1; argslist << a end
          task "foo"            do nil end
          task "bar", tag: 'yy' do 1/0 end     # raises ZeroDivisionError
          task "baz", tag: 'zz' do nil end
        end
        ok {called} == 0
        ok {argslist} == []
        capture_sio do
          pr = proc { bm.__send__(:invoke_tasks) }
          ok {pr}.raise?(ZeroDivisionError)
        end
        ok {called} == 2
        ok {argslist} == [["foo", nil], ["bar", 'yy']]
      end
    - spec("[!fv4cv] skips task invocation if skip reason is specified.") do
        called = []
        bm = Benchmarker::Benchmark.new().scope do
          empty_task do called << :empty end
          task "foo" do called << :foo end
          task "bar", skip: "not installed" do called << :bar end
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
    - spec("[!vbhvz] sleeps N seconds after each task if `sleep` option specified.") do
        new_bm = proc {|kwargs|
          Benchmarker::Benchmark.new(**kwargs).scope do
            empty_task do nil end
            task "foo" do nil end
            task "bar" do nil end
          end
        }
        #
        bm = new_bm.call({})
        start = Time.now
        capture_sio { bm.__send__(:invoke_tasks) }
        ok {Time.now - start} < 0.1
        #
        bm = new_bm.call({sleep: 1})
        start = Time.now
        capture_sio { bm.__send__(:invoke_tasks) }
        ok {Time.now - start} > 3.0
      end
    end

  + topic('#ignore_skipped_tasks()') do
      def task_names(bm)
        bm.instance_eval {@entries}.collect {|t,_| t.name}
      end
    - spec("[!5gpo7] removes skipped tasks and leaves other tasks.") do
        bm = Benchmarker::Benchmark.new().scope do
          empty_task do nil end
          task "foo", skip: "not installed" do nil end
          task "bar", skip: "not installed" do nil end
          task "baz" do nil end
        end
        capture_sio { bm.__send__(:invoke_tasks) }
        ok {task_names(bm)} == ["foo", "bar", "baz"]
        bm.__send__(:ignore_skipped_tasks)
        ok {task_names(bm)} == ["baz"]
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
          [task.name, real_list]
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
        ok {str} == <<"END"

## Removed Min & Max                 min      iter       max      iter
foo                            \e[0;36m   4.1000\e[0m \e[0;35m     (#2)\e[0m \e[0;36m   4.9000\e[0m \e[0;35m     (#5)\e[0m
                               \e[0;36m   4.2000\e[0m \e[0;35m     (#6)\e[0m \e[0;36m   4.8000\e[0m \e[0;35m     (#8)\e[0m
bar                            \e[0;36m   4.1000\e[0m \e[0;35m     (#2)\e[0m \e[0;36m   4.9000\e[0m \e[0;35m     (#5)\e[0m
                               \e[0;36m   4.2000\e[0m \e[0;35m     (#6)\e[0m \e[0;36m   4.8000\e[0m \e[0;35m     (#8)\e[0m
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
        ok {str} == <<"END"

## Average of 5 (=9-2*2)            user       sys     total      real
foo                               1.5000    2.5000    3.5000 \e[0;36m   4.5000\e[0m
bar                               1.5000    2.5000    3.5000 \e[0;36m   4.5000\e[0m
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
        ok {str} == <<"END"

## Ranking                          real
foo                            \e[0;36m   1.1100\e[0m (100.0%) ********************
bar                            \e[0;36m   2.2200\e[0m ( 50.0%) **********
baz                            \e[0;36m   3.3300\e[0m ( 33.3%) *******
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
        ok {str} == <<"END"

## Matrix                           real      [1]      [2]      [3]
[1] foo                        \e[0;36m   1.1100\e[0m   100.0%   200.0%   300.0%
[2] bar                        \e[0;36m   2.2200\e[0m    50.0%   100.0%   150.0%
[3] baz                        \e[0;36m   3.3300\e[0m    33.3%    66.7%   100.0%
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

  + topic('#colorize?') do
    - spec("[!cy10n] returns true if '-c' option specified.") do
        bm = Benchmarker.new(colorize: true)
        ok {bm.__send__(:colorize?)} == true
        capture_sio do
          ok {bm.__send__(:colorize?)} == true
        end
      end
    - spec("[!e0gcz] returns false if '-C' option specified.") do
        bm = Benchmarker.new(colorize: false)
        ok {bm.__send__(:colorize?)} == false
        capture_sio do
          ok {bm.__send__(:colorize?)} == false
        end
      end
    - spec("[!6v90d] returns result of `Color.colorize?` if neither '-c' nor '-C' specified.") do
        bm = Benchmarker.new()
        ok {bm.__send__(:colorize?)} == true
        capture_sio do
          ok {bm.__send__(:colorize?)} == false
        end
      end
    end

  end


+ topic(Benchmarker::Scope) do

    fixture :bm do
      Benchmarker::Benchmark.new()
    end

    fixture :scope do |bm|
      Benchmarker::Scope.new(bm)
    end

  + topic('#task()') do
    - spec("[!j6pmr] creates new task object.") do |scope|
        task = scope.task "name1", tag: "abc" do end
        ok {task}.is_a?(Benchmarker::Task)
        ok {task.name} == "name1"
        ok {task.tag} == "abc"
      end
    - spec("[!kh7r9] define empty-loop task if name is nil.") do |scope|
        task = scope.task nil do end
        ok {task}.is_a?(Benchmarker::Task)
        ok {task.name} == nil
      end
    + case_when("[!843ju] when code argument provided...") do
      - spec("[!bwfak] code argument and block argument are exclusive.") do |scope|
          pr = proc { scope.task "foo", "x = 1+1" do nil end }
          ok {pr}.raise?(Benchmarker::TaskError, "task(\"foo\"): cannot accept String argument when block argument given.")
        end
      - spec("[!4dm9q] generates block argument if code argument passed.") do |scope|
          x = 0
          task = scope.task "foo", "x += 1", binding()
          ok {task.instance_eval{@block}}.is_a?(Proc)
          task.instance_eval{@block}.call()
          ok {x} == 100
        end
      end
    end

  + topic('#empty_task()') do
    - spec("[!ycoch] creates new empty-loop task object.") do |scope|
        task = scope.empty_task do end
        ok {task}.is_a?(Benchmarker::Task)
        ok {task.name} == nil
      end
    end

  + topic('#before()') do
    - spec("[!2ir4q] defines 'before' hook.") do |scope, bm|
        called = false
        scope.before do called = true end
        ok {called} == false
        bm.__send__(:call_hook, :before)
        ok {called} == true
      end
    end

  + topic('#after()') do
    - spec("[!05up6] defines 'after' hook.") do |scope, bm|
        called = false
        scope.after do called = true end
        ok {called} == false
        bm.__send__(:call_hook, :after)
        ok {called} == true
      end
    end

  + topic('#before_all()') do
    - spec("[!1oier] defines 'before_all' hook.") do |scope, bm|
        called = false
        scope.before_all do called = true end
        ok {called} == false
        bm.__send__(:call_hook, :before_all)
        ok {called} == true
      end
    end

  + topic('#after_all()') do
    - spec("[!z7xop] defines 'after_all' hook.") do |scope, bm|
        called = false
        scope.after_all do called = true end
        ok {called} == false
        bm.__send__(:call_hook, :after_all)
        ok {called} == true
      end
    end

  + topic('#validate()') do
    - spec("[!q2aev] defines validator.") do
        bm = Benchmarker::Benchmark.new()
        scope = Benchmarker::Scope.new(bm)
        ok {bm.instance_eval{@hooks[:validate]}} == nil
        scope.validate do |ret| end
        ok {bm.instance_eval{@hooks[:validate]}} != nil
        ok {bm.instance_eval{@hooks[:validate]}}.is_a?(Proc)
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
    + case_when("[!s2f6v] when task block is build from repeated code...") do
      - spec("[!i2r8o] error when number of loop is less than 100.") do
          capture_sio do
            pr = proc do
              Benchmarker.scope(loop: 100) do
                task "foo", "x = 1+1"
              end
            end
            ok {pr}.NOT.raise?
            #
            pr = proc do
              Benchmarker.scope(loop: 99) do
                task "foo", "x = 1+1"
              end
            end
            ok {pr}.raise?(Benchmarker::TaskError, 'task("foo"): number of loop (=99) should be >= 100, but not.')
          end
        end
      - spec("[!kzno6] error when number of loop is not a multiple of 100.") do
          capture_sio do
            pr = proc do
              Benchmarker.scope(loop: 200) do
                task "foo", "x = 1+1"
              end
            end
            ok {pr}.NOT.raise?
            #
            pr = proc do
              Benchmarker.scope(loop: 250) do
                task "foo", "x = 1+1"
              end
            end
            ok {pr}.raise?(Benchmarker::TaskError, 'task("foo"): number of loop (=250) should be a multiple of 100, but not.')
          end
        end
      - spec("[!gbukv] changes number of loop to 1/100.") do
          capture_sio do
            called = 0
            Benchmarker.scope(loop: 200) do
              task "foo", "called +=1", binding()
            end
            ok {called} == 200
          end
        end
      end
    - spec("[!frq25] kicks GC before calling task block.") do
        capture_sio do
          rec = recorder()
          rec.record_method(GC, :start)
          called = false
          Benchmarker.scope() do
            task "foo" do called = true end
          end
          ok {called} == true
          ok {rec[0].obj}  == GC
          ok {rec[0].name} == :start
        end
      end
    - spec("[!tgql6] invokes block N times.") do
        cnt = 0
        task = Benchmarker::Task.new("name1") do cnt += 1 end
        task.invoke(3)
        ok {cnt} == 3
      end
    - spec("[!9e5pr] returns TimeSet object.") do
        task = Benchmarker::Task.new("name1") do nil end
        ret = task.invoke()
        ok {ret}.is_a?(Benchmarker::TimeSet)
      end
    - spec("[!zw4kt] yields validator with result value of block.") do
        task = Benchmarker::Task.new("name1", tag: "curr") do 234 end
        args = nil
        task.invoke() do |*a| args = a end
        ok {args} == [234, "name1", "curr"]
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

  + topic('#div()') do
    - spec("[!4o9ns] returns new TimeSet object which values are divided by n.") do
        t1 = Benchmarker::TimeSet.new(2.5, 3.5, 5.0, 5.25)
        t2 = t1.div(100)
        ok {t2.user } == 0.025
        ok {t2.sys  } == 0.035
        ok {t2.total} == 0.050
        ok {t2.real } == 0.0525
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

  + topic('#clear()') do
    - spec("[!fxrn6] clears timeset array.") do |r|
        ok {r.length} == 0
        r.add(Benchmarker::TimeSet.new(1.0, 2.0, 3.0, 4.0))
        r.add(Benchmarker::TimeSet.new(0.0, 0.0, 0.0, 0.0))
        ok {r.length} == 2
        r.clear()
        ok {r.length} == 0
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


+ topic(Benchmarker::Color) do

  + topic('.colorize?()') do
    - spec("[!fc741] returns true if stdout is a tty, else returns false.") do
        ok {Benchmarker::Color.colorize?} == true
        capture_sio do
          ok {Benchmarker::Color.colorize?} == false
        end
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
        ok {arr[6][0]} == "os name"
        ok {arr[7][0]} == "cpu model"
        ok {arr[8]} == nil
      end
    end

  + topic('.os_name()') do
    - spec("[!83vww] returns string representing os name.") do
        str = Benchmarker::Misc.os_name()
        ok {str}.is_a?(String)
      end
    end

  + topic('.cpu_model()') do
    - spec("[!6ncgq] returns string representing cpu model.") do
        str = Benchmarker::Misc.cpu_model()
        ok {str}.is_a?(String)
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
    - spec("[!nz15w] convers '-s' option value into number (integer or float).") do
        options, _ = Benchmarker::OptionParser.parse_options(['-s', '123'])
        ok {options} == {"s"=>123}
        options, _ = Benchmarker::OptionParser.parse_options(['-s', '0.5'])
        ok {options} == {"s"=>0.5}
      end
    - spec("[!3x1m7] yields error message when argument of '-s' is not a number.") do
        err = nil
        Benchmarker::OptionParser.parse_options(['-s', 'aa']) do |s| err = s end
        ok {err} == "-s aa: number expected."
      end
    - spec("[!emavm] yields error message when argumetn of '-F' option is invalid.") do
        err = nil
        Benchmarker::OptionParser.parse_options(['-F', 'xyz']) do |s| err = s end
        ok {err} == "-F xyz: invalid filter (expected operator is '=' or '!=')."
        #
        err = nil
        Benchmarker::OptionParser.parse_options(['-F', 'name=xyz']) do |s| err = s end
        ok {err} == "-F name=xyz: expected 'task=...' or 'tag=...'."
      end
    end

  + topic('.help_message()') do
    - spec("[!jnm2w] returns help message.") do
        msg = Benchmarker::OptionParser.help_message("bench.rb")
        ok {msg} == <<'END'
Usage: bench.rb [<options>]
  -h, --help     : help message
  -v             : print Benchmarker version
  -w <N>         : width of task name (default: 30)
  -n <N>         : loop N times in each benchmark (default: 1)
  -i <N>         : iterates all benchmark tasks N times (default: 1)
  -x <N>         : ignore worst N results and best N results (default: 0)
  -I[<N>]        : print inverse number (= N/sec) (default: same as '-n')
  -o <file>      : output file in JSON format
  -q             : quiet a little (suppress output of each iteration)
  -c             : enable colorized output
  -C             : disable colorized output
  -s <N>         : sleep N seconds after each benchmark task
  -S             : print sample code
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
    - spec("[!nrxsb] prints sample code if '-S' option specified.") do
        argv = ["-S"]
        sout, serr = capture_sio do
          pr = proc { Benchmarker.parse_cmdopts(argv) }
          ok {pr}.raise?(SystemExit) do |exc|
            ok {exc.status} == 0
          end
        end
        ok {serr} == ""
        ok {sout} == Benchmarker::Misc.sample_code()
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
    - spec("[!nexi8] option '-w' specifies task name width.") do
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-w', '10'])
        ok {Benchmarker::OPTIONS} == {width: 10}
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do nil end
          end
        end
        ok {sout} =~ /^foo           0.0000/
      end
    - spec("[!raki9] option '-n' specifies count of loop.") do
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-n', '17'])
        ok {Benchmarker::OPTIONS} == {loop: 17}
        count = 0
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do count += 1 end
          end
        end
        ok {count} == 17
      end
    - spec("[!mt7lw] option '-i' specifies number of iteration.") do
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-i', '5'])
        ok {Benchmarker::OPTIONS} == {iter: 5}
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
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-i', '5', '-x', '1'])
        ok {Benchmarker::OPTIONS} == {iter: 5, extra: 1}
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
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-I'])
        ok {Benchmarker::OPTIONS} == {inverse: true}
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
        ok {Benchmarker::OPTIONS} == {}
        outfile = "tmp99.json"
        Benchmarker.parse_cmdopts(['-o', outfile])
        ok {Benchmarker::OPTIONS} == {outfile: outfile}
        at_exit { File.unlink outfile if File.exist?(outfile) }
        ok {outfile}.not_exist?
        sout, serr = capture_sio do
          Benchmarker.scope(width: 20) do
            task "foo" do nil end
          end
        end
        ok {outfile}.file_exist?
      end
    - spec("[!02ml5] option '-q' specifies quiet mode.") do
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-q', '-i10', '-x1'])
        ok {Benchmarker::OPTIONS} == {quiet: true, iter: 10, extra: 1}
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
    - spec("[!e5hv0] option '-c' specifies colorize enabled.") do
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-c'])
        ok {Benchmarker::OPTIONS} == {colorize: true}
        sout, serr = capture_sio(tty: false) do
          Benchmarker.scope() do
            task "foo" do nil end
          end
        end
        ok {sout} =~ /\e\[0;36m.*?\e\[0m/
      end
    - spec("[!e5hv0] option '-c' specifies colorize enabled.") do
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-C'])
        ok {Benchmarker::OPTIONS} == {colorize: false}
        sout, serr = capture_sio(tty: true) do
          Benchmarker.scope() do
            task "foo" do nil end
          end
        end
        ok {sout} !~ /\e\[0;36m.*?\e\[0m/
      end
    - spec("[!muica] option '-F' specifies filter.") do
        ok {Benchmarker::OPTIONS} == {}
        Benchmarker.parse_cmdopts(['-F', 'task=ba*'])
        ok {Benchmarker::OPTIONS} == {filter: 'task=ba*'}
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
        ok {Benchmarker::OPTIONS} == {}
        ok {$blabla} == nil
        Benchmarker.parse_cmdopts(['--blabla=123'])
        ok {Benchmarker::OPTIONS} == {}
        ok {$blabla} == "123"
      end
    end
  end


+ topic(Benchmark) do

  + topic('.bm()') do
    - spec("[!2nf07] defines and runs benchmark.") do
        called = {foo: 0, bar: 0}
        sout, serr = capture_sio do
          Benchmark.bm do |x|
            x.report("foo") do called[:foo] += 1 end
            x.report("bar") do called[:bar] += 1 end
          end
        end
        ok {called} == {foo: 1, bar: 1}
        n = 0
        sout.scan(/^##  +.*\nfoo +.*\nbar +.*/) { n+= 1 }
        ok {n} == 1
        ok {serr} == ""
      end
    end

  + topic('.bm()') do
    - spec("[!ezbb8] defines and runs benchmark twice, reports only 2nd result.") do
        called = {foo: 0, bar: 0}
        sout, serr = capture_sio do
          Benchmark.bmbm do |x|
            x.report("foo") do called[:foo] += 1 end
            x.report("bar") do called[:bar] += 1 end
          end
        end
        ok {called} == {foo: 2, bar: 2}
        n = 0
        sout.scan(/^##  +.*\nfoo +.*\nbar +.*/) { n+= 1 }
        ok {n} == 1
        ok {serr} == ""
      end
    end

  end


end
