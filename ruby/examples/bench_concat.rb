##
## benchmark to concatenate strings
##

require 'benchmarker'

s1, s2, s3, s4, s5 = "Haruhi", "Mikuru", "Yuki", "Itsuki", "Kyon"
strlist = [s1, s2, s3, s4, s5]

title = "string concat"
Benchmarker.scope(title, width: 26, loop: 1000_000, iter: 5, extra: 1) do

  #task nil do
  #  nil
  #end

  task "String#+", <<-'END'
    s1 + s2 + s3 + s4 + s5
  END

  task "String#<<", <<-'END'
    #String.new << s1 << s2 << s3 << s4 << s5
    "" << s1 << s2 << s3 << s4 << s5
  END

  task "String#% & Array.new", <<-'END'
    "%s%s%s%s%s" % [s1, s2, s3, s4, s5]
  END

  task "String#%", <<-'END'
    "%s%s%s%s%s" % strlist
  END

  task "Array#join & Array.new", <<-'END'
    [s1, s2, s3, s4, s5].join()
  END

  task "Array#join", <<-'END'
    strlist.join()
  END

  task "Interpolation", <<-'END'
    "#{s1}#{s2}#{s3}#{s4}#{s5}"
  END

  validate do |sos|
    expected = "HaruhiMikuruYukiItsukiKyon"
    assert_eq sos, expected
  end

end
