###
### benchmark to compare loop methods
###

require 'benchmarker'

nums = (1..10000).to_a #.shuffle

Benchmarker.new(:width=>24, :loop=>1000, :cycle=>5, :extra=>1) do |bm|

  bm.empty_task do
    nil
  end

  bm.task("each() & '+='") do
    total = 0
    nums.each {|n| total += n }
    total
  end

  bm.task("inject()") do
    total = nums.inject(0) {|t, n| t += n }
    total
  end

  msg = "    # skip because Symbol#to_proc() is not defined."
  msg = nil if :+.respond_to?(:to_proc)
  bm.task("inject(&:+)", :skip=>msg) do
    total = nums.inject(0, &:+)
    total
  end

  bm.task("for statement") do
    total = 0
    for n in nums
      total += n
    end
    total
  end

  bm.task("while statement") do
    i, len = 0, nums.length
    total = 0
    while i < len
      total += nums[i]
      i += 1
    end
    total
  end

end
