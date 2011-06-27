load 'lib/jruby_threach.rb'

# Simple: just do it
puts "\n\nProblem-free execution\n"
(1..10).threach(3) do |i|
  print "#{Thread.current[:threach_num]}: #{i}\n"
  (Thread.current[:threach_num] % 3) == 1 ? sleep(0.1): sleep(0.3)
end

# Break out of it. If any one thread breaks, they all grind 
# to a half

puts "\n\nBreak out of the block\n"
(1..10).threach(3) do |i|
  print "#{Thread.current[:threach_num]}: #{i}\n"
  break if i == 5
  (Thread.current[:threach_num] % 3) == 1 ? sleep(0.1): sleep(0.3)
end

# We also capture errors that aren't handled in the block, stop
# everything, and then re-raise the error to the calling code

puts "\n\nStop execution on error and pass error to calling code\n"
begin
  (1..10).threach(3) do |i|
    print "#{Thread.current[:threach_num]}: #{i}\n"
    raise RuntimeError.new, "oops", nil if i == 5
    (Thread.current[:threach_num] % 3) == 1 ? sleep(0.1): sleep(0.3)
  end
rescue RuntimeError => e
  print "Caught an error that stopped execution\n"
end

# Of course, if you deal with the error within the block,
# there's no problem.

puts "\n\nRescue error within passed block\n"
begin
  (1..10).threach(3) do |i|
    begin
      print "#{Thread.current[:threach_num]}: #{i}\n"
      raise RuntimeError.new, "oops", nil if i == 5
      (Thread.current[:threach_num] % 3) == 1 ? sleep(0.1): sleep(0.3)
    rescue RuntimeError => e
      print "Caught error inside block; just ignore it and move on\n"
    end
  end
rescue RuntimeError => e
  print "Caught an error that stopped execution\n" # won't ever run
end

# Nesting example 
files = ['Rakefile', 'README.rdoc', 'LICENSE.txt']
files.threach(3) do |f|
  File.open(f).threach(2, :each_line) do |line|
    print "#{f}: #{line.chomp[0..20]}\n"
  end
end


