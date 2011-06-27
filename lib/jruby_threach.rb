require 'java'
java_import java.util.concurrent.ArrayBlockingQueue
java_import java.util.concurrent.TimeUnit
java_import org.jruby.exceptions.JumpException::BreakJump

module Threach
  
  DEBUG = false
  
  class ThreachBreak < RuntimeError; end
  class ThreachNotMyError < RuntimeError; end
  class ThreachEndOfRun < RuntimeError; end
  
  class Queue < ArrayBlockingQueue
    MS = TimeUnit::MILLISECONDS
     
    def initialize (size=2, timeout_in_ms = 5)
      super(size)
      @timeout = timeout_in_ms
    end
    
    # push will return false if it times out; true otherwise
    def push obj
      self.offer obj, @timeout, MS
    end
    
    # Pop will return nil if it times out; the popped object otherwise
    def pop
      self.poll @timeout, MS
    end
  end
end

module Enumerable
  
  def threach(threads = 0, iterator = :each, &blk)
    
    # With no extra threads, just spin up the passed iterator
    if threads == 0
      self.send(iterator, &blk)
    else
      # Get a java BlockingQueue for the producer to dump stuff into
      bq = Threach::Queue.new(threads * 2) # capacity is twice the number of threads
      
      # And another to store errors
      errorq = Threach::Queue.new(threads + 1)
      
      # A boolean to let us know if things are going wonky
      bail = false
      outofdata = false
      
      # Build up a set of consumers
      
      consumers = []
      threads.times do |i|
        consumers << Thread.new(i) do |i|
          Thread.current[:threach_num] = i
          begin
            while true
              obj = bq.pop

              # Should we be bailing?
              if bail
                print "Thread #{Thread.current[:threach_num]}: BAIL!\n" if Threach::DEBUG
                Thread.current[:threach_bail] = true
                raise Threach::ThreachNotMyError.new, "bailing", nil
              end
              
            
              # If the return value is nil, it timed out. See if there's
              # anything wrong, or if we've run out of work
              if obj.nil?
                if outofdata
                  Thread.current[:threach_outofdata] = true
                  raise Threach::ThreachEndOfRun.new, "out of work", nil
                end
                # otherwise, try to pop again
                next 
              end
              
              # Otherwise, do the work
              blk.call(*obj)
            end
          
          rescue Threach::ThreachNotMyError => e
            print "Thread #{Thread.current[:threach_num]}: Not my error\n" if Threach::DEBUG
            Thread.current[:threach_bail] = true            
            # do nothing; wasn't my error, so I just bailed
          
          rescue Threach::ThreachEndOfRun => e
            print "Thread #{Thread.current[:threach_num]}: End of run\n" if Threach::DEBUG
            Thread.current[:threach_bail] = true            
            # do nothing; everything exited normally 
            
          rescue Exception => e
            print "Thread #{Thread.current[:threach_num]}: Exception #{e.inspect}: #{e.message}\n" if Threach::DEBUG
            # Some other error; let everyone else know
            bail = true
            Thread.current[:threach_bail]
            errorq.push e
          ensure
            # OK, I don't understand this, but I'm unable to catch org.jruby.exceptions.JumpException$BreakJump
            # But if I get here and nothing else is set, that means I broke and need to deal with
            # it accordingly
            unless Thread.current[:threach_bail] or Thread.current[:threach_outofdata]
              print "Thread #{Thread.current[:threach_num]}: broke out of loop\n" if Threach::DEBUG
              bail = true
            end
          end
        end
      end
      
      
      # Now, our producer
      
      # Start running the given iterator and try to push stuff
      
      begin
        self.send(iterator) do |*x|
          until successful_push = bq.push(x)
            # if we're in here, we got a timeout. Check for errors
            raise Threach::ThreachNotMyError.new, "bailing", nil if bail if bail
          end
          print "Queued #{x}\n" if Threach::DEBUG
        end

        # We're all done. Let 'em know
        print "Setting outofdata to true\n" if Threach::DEBUG
        outofdata = true
      
      rescue NativeException => e
        print "Producer rescuing native exception #{e.inspect}" if Threach::DEBUG
      
      rescue Threach::ThreachNotMyError => e
        print "Producer: not my error\n" if Threach::DEBUG
        # do nothing. Not my error
        
      rescue Exception => e
        print "Producer: exception\n" if Threach::DEBUG
        bail = true
        errorq.push e
      end
      
      # Finally, #join the consumers
      
      consumers.each {|t| t.join}
      
      # Everything's done. If there's an error on the stack, raise it
       if e = errorq.peek
         print "Producer: raising #{e.inspect}\n" if Threach::DEBUG
         raise e, e.message, nil
       end
      

    end
  end
end
      
  
  