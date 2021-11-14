###
### benchmark to calculate sum of integers
###

require 'benchmarker'

nums = (1..1000_000).to_a #.shuffle

title = "calculate sum of integers"
Benchmarker.scope title, width: 24, loop: 100, iter: 5, extra: 1 do

  task nil do
    nil
  end

  task "each() & '+='" do
    total = 0
    nums.each {|n| total += n }
    total
  end

  task "inject()" do
    total = nums.inject(0) {|t, n| t += n }
    total
  end

  task "inject(:+)" do
    total = nums.inject(0, :+)
    total
  end

  reason = nums.respond_to?(:sum) ? nil : "Array#sum() not defined"
  task "sum()", skip: reason do
    total = nums.sum()
    total
  end

  task "for statement" do
    total = 0
    for n in nums
      total += n
    end
    total
  end

  task "while statement" do
    total = 0; i = -1; len = nums.length
    while (i += 1) < len
      total += nums[i]
    end
    total
  end

  validate do |total|
    n = nums.length
    expected = n * (n+1) / 2
    assert_eq total, expected
  end

end
