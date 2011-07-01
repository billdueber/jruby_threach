# JRuby_threach

`jruby_threach` adds a method to Enumerable called `#threach` that takes a block and distributes the objects produced by a call to `#each` (or the enumerator of your choice) automatically to a set of consumers.

`jruby_threach` is roughly seven zillion times better than it's vanilla MRI counterpart (`threach`) in that it can handle non-local exits out of the block (`break` or `raise`) without incident. This is possible due to the more powerful queue class available in Java.

## What it does

`jruby_threach` effectively creates a classic producer/consumer setup with a size-restricted queue between them. A single producer (running in the main thread) runs the given iterator (`#each` by default) and stuffs values into the queue. The consumers then grab these values and process them.

A few things can be gleaned from this:

* If your consumer code is faster than your producer code, your consumers are going to be starved
* You should allocate no more consumers than the speed multiplier between producer and consumer code (e.g., if your producer code -- the call to #each -- is only twice as fast as the block you're passing, don't bother to allocate more than two consumer threads).

## Installation

`jruby_threach` is on rubygems.org, so you should just be able to do

    gem install jruby_threach
    # or JRuby --1.9 -S gem install JRuby_threach for 1.9

## Use

`jruby_threach` works under JRuby with and without the --1.9 switch. 

    require 'jruby_threach'
    
    # Process an array of data with two threads (default is to call #each)    
    ary.threach(2) {|i| process_data(i)}
    
    # Specify the iterator at will
    ary.threach(2, :each_with_index) {|val, i| process_index_value(i, val)}
    
    # #threach doesn't care what the arity of your enumerator is, so long
    # as the block you pass matches it
    hash.threach(3) {|k,v| process_key_value(k,v)}
    
    # Anything that mixes in enumerable is game. e.g., process lines of a file
    File.open('myfile.txt').threach(3, :each_line) {|line| process_line(line)}
    
    # Pass in a thread count of 0 to just call the underlying method
    ary.threach(0)


## mthreach -- thread the producers as well

There are a couple obvious use cases (e.g., work on a whole list of files) where it might be useful to thread the producer as well. `mthreach` operates on an array of enumerables, using multiple threads to use them to fill a queue simultaneously, and then uses the normal `threach` logic to have multiple consumers pulling from that queue to do work.

    # Use 2 producer threads and 3 consumer threads to process lines
    Dir.glob('*.txt').map{|f| File.open(f)}.mthreach(2,3,:each_line) {|l|...}

This starts to make more sense if your producer objects aren't super-speedy (e.g., an object that's crawling a list of URLs off the web, hitting a database or set of databases, etc.) or if you have the exemplar case of multiple files (e.g., a set of CSV files where you're going to process each line and stick it into a database). 


## Threach::MultiEnum 

You can also use Threach::MultiEnum, the class behind `#mthreach`, by itself, for whenever you have a set of iterators and want to deal with them as if they were a single thing.

    me = Threach::MultiEnum.new(
       [1..10, 'a'..'z', File.open('myfile.txt')], # array of enumerables
       3,     # number of threads. nil => one per enum
       :each, # enumerator method to use
       10     # size of the internal queue
      )
    me.each {|item| process_item(item)}


# Things to know

**You're using threads!** Your code needs to be thread-safe (esp. make sure your database connections can cope), and of course we can't guarantee what order the data will be processed in. 

**Spurious warning**  As of this writing, breaking out of a `threach` loop (by calling `break` in the passed block) causes JRuby to print a warning of the form, 'Exception in thread "RubyThread-44: samples.rb:1"org.JRuby.exceptions.JumpException$BreakJump'. Hopefully this can be tracked down and eliminated by the JRuby team.


## Contributing to JRuby_threach
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 BillDueber. See LICENSE.txt for
further details.

