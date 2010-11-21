require File.join(File.dirname(__FILE__), "spec_helper")
require 'akurum/lazy'

module Akurum
  describe Akurum::Lazy do
    it "should not evaluate a promise until evaluated normally" do
      evaled = false
      p = promise { evaled = true }
      evaluated?(p).should be_false
      evaled.should be_false
    
      (p == true).should == true
      evaluated?(p).should be_true
      evaled.should be_true
    end
  
    it "should let you force evaluation of a promised object with demand" do
      evaled = false
      p = promise { evaled = true }
    
      demand(p).should == true
      evaluated?(p).should be_true
      evaled.should be_true
    end
  
    it "should consider a normal object to be evaluated" do
      evaluated?(1).should be_true
      evaluated?("boom").should be_true
      class Blah; end
      evaluated?(Blah.new).should be_true
    end
    
    it "should demand any object into itself" do
      demand(1).should == 1
      demand("boom").should == "boom"
      x = class Blah; end
      demand(x).should == x
    end
  end
end