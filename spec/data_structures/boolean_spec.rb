require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'akurum/data_structures/boolean'

module Akurum
  describe Boolean do
    it "should let you create a boolean object with either true or false." do
      Boolean.new(true).symbol.should == true
      Boolean.new(false).symbol.should == false
    end
    
    it "should let you create a boolean object with either 0 or 1 rather than false/true" do
      Boolean.new(1).symbol.should == true
      Boolean.new(0).symbol.should == false
    end
    
    it "should error if you try to initialize it to something other than true or false" do
      lambda { Boolean.new(2) }.should raise_error(ArgumentError)
      lambda { Boolean.new("boom") }.should raise_error(ArgumentError)
    end
    
    it "should compare correctly against another boolean" do
      Boolean.new(true).should == Boolean.new(true)
      Boolean.new(false).should == Boolean.new(false)
      Boolean.new(true).should_not == Boolean.new(false)
      Boolean.new(false).should_not == Boolean.new(true)
    end
  end
end