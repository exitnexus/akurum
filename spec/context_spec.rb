require File.join(File.dirname(__FILE__), "spec_helper")
require 'akurum/context'
require 'akurum/backends/base'
require 'akurum/memcache'

module Akurum
  class TestContext < Context
    def start(old)
      @started = true
      @old = old
    end
    def finish()
      @finished = true
    end
    def log(li, i=Log::DEBUG)
      @q = li
    end
    attr_reader :q, :started, :finished, :old
  end
  
  shared_examples_for Context do |context_class, *init_args|
    before(:each) do
      @context = context_class.new(*init_args)
    end
    it "should let you pass a valid loggable object into log()" do
      @context.log("blah")
    end
    it "should let you pass a valid loggable object into log() with a numeric importance designator" do
      @context.log("blah", Context::Log::DEBUG)
    end
    it "should let you set and then retrieve an entry from the cache" do
      @context[:a] = :b
      @context[:a].should == :b
    end
  end
    
  describe Context do
    it_behaves_like Context, Context
    
    it "should return nil from current if there is no context" do
      Context.current.should be_nil
    end
    
    it "should let you set a current context and then return that object from within the block" do
      ctx = Context.new
      Context.current.should be_nil
      Context.use(ctx) do
        Context.current.should == ctx
      end
      Context.current.should be_nil
    end
    
    it "should call start and finish before and after yielding" do
      ctx = TestContext.new
      Context.use(ctx) do
      end
      ctx.started.should == true
      ctx.finished.should == true
      ctx.old.should == nil
    end
    
    it "should give start() the previous context when there is one" do
      ctx1 = Context.new
      ctx2 = TestContext.new
      Context.use(ctx1) do
        Context.use(ctx2) do
        end
      end
      ctx2.started.should == true
      ctx2.old.should == ctx1
    end
    
    it "should yield the current context object if there is one from Context.current if passed a block" do
      Context.use(ctx = Context.new) do
        happened = false
        Context.current do
          happened = true
        end
        happened.should be_true
      end
    end
    
    it "should not yield if there is no context from Context.current if passed a block" do
      happened = false
      Context.current do
        happened = true
      end
      happened.should be_false
    end
    
    it "should raise an error if you try to use Context.current! when there is no context" do
      lambda { Context.current! }.should raise_error(Akurum::Error)
    end
    
    it "should return the current context object if there is one from Context.current!" do
      Context.use(ctx = Context.new) do
        Context.current!.should == ctx
      end
    end
    
    it "should let you set a current context within another and have the original restored after" do
      ctx1 = Context.new
      ctx2 = Context.new
      
      Context.current.should be_nil
      Context.use(ctx1) do
        Context.current.should == ctx1
        
        Context.use(ctx2) do
          Context.current.should == ctx2
          Context.current.should_not == ctx1
        end
        
        Context.current.should == ctx1
        Context.current.should_not == ctx2
      end
      Context.current.should be_nil
    end
    
    it "should let you call log() through the class method and have it go through to the current context if there is one" do
      ctx = TestContext.new
      Context.use(ctx) do
        Context.log(1)
        ctx.q.should == 1
      end
    end
    
    it "should let you call log!() through the class method and have it go through to the current context if there is one" do
      ctx = TestContext.new
      Context.use(ctx) do
        Context.log!(1)
        ctx.q.should == 1
      end
    end

    it "should let you call log() through the class and have it be ignored if there is no current context" do
      Context.log(1)
    end
    
    it "should raise an ArgumentError if you try to call log! while there is no current context" do
      lambda { Context.log!(1) }.should raise_error(ArgumentError)
    end
    
    it "should let you set cache entries through the class method and have it go through to the current context if there is one" do
      ctx = TestContext.new
      Context.use(ctx) do
        Context[:a] = :b
        Context[:a].should == :b
      end
    end
    
    it "should raise an error if you try to set or retrieve a cache entry through the class methods if there is no current context" do
      lambda { Context[:a] }.should raise_error(ArgumentError)
      lambda { Context[:a] = :b }.should raise_error(ArgumentError)
    end
  end
  describe SimpleContext do
    it_behaves_like Context, SimpleContext
    
    before(:each) do
      @context = SimpleContext.new(Context::Log::DEBUG)
    end
    
    it "should let you store and retrieve log information" do
      @context.log("blah")
      @context.log("blorp")
      
      @context.log_items[0].should == "blah"
      @context.log_items[1].should == "blorp"
    end
    
    it "should ignore log entries below the log threshold set at initialization" do
      @context.log("blah", Context::Log::DEBUG)
      @context.log("blorp", Context::Log::SPAM)
      
      @context.log_items[0].should == "blah"
      @context.log_items[1].should be_nil
    end
  end
end