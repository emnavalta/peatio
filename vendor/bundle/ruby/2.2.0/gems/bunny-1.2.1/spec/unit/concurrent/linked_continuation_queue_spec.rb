require "spec_helper"

if defined?(JRUBY_VERSION)
  require "bunny/concurrent/linked_continuation_queue"

  describe Bunny::Concurrent::LinkedContinuationQueue do
    describe "#poll with a timeout that is never reached" do
      it "blocks until the value is available, then returns it" do
        # force subject evaluation
        cq = subject
        t = Thread.new do
          cq.push(10)
        end
        t.abort_on_exception = true

        v = subject.poll(500)
        v.should == 10
      end
    end

    describe "#poll with a timeout that is reached" do
      it "raises an exception" do
        # force subject evaluation
        cq = subject
        t = Thread.new do
          sleep 1.5
          cq.push(10)
        end
        t.abort_on_exception = true

        lambda { subject.poll(500) }.should raise_error(::Timeout::Error)
      end
    end
  end
end
