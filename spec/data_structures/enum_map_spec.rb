require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'akurum/data_structures/enum_map'

module Akurum
  describe EnumMap do
    # This assumes that most functionality of Enum is still intact.
    
    before(:each) do
      @e = EnumMap.new(:a, {:a => 1, :b => 2})
    end
    
    it "should create from a choice of symbol and a map of id to value pairs" do
      @e.symbol.should == :a
    end
    it "should create from a choice of numeric id and a map of id to value pairs" do
      EnumMap.new(1, {:a => 1, :b => 2}).symbol.should == :a
    end
    
    it "should throw an ArgumentError if you try to create it with an invalid name or id" do
      lambda { EnumMap.new(:c, {:a => 1, :b => 2}) }.should raise_error(ArgumentError)
      lambda { EnumMap.new(3, {:a => 1, :b => 2}) }.should raise_error(ArgumentError)
    end
    
    it "should let you set it to a new symbol" do
      @e.symbol = :b
      @e.symbol.should == :b
    end
    
    it "should let you set it to a new id, and that should change the value to the matching symbol" do
      @e.symbol = 2
      @e.symbol.should == :b
    end
    
    it "should let you get the actual id value out after setting" do
      @e.value.should == 1
      @e.symbol = :b
      @e.value.should == 2
    end
    
    it "should let you read the list of mappings" do
      @e.map.should == {:a => 1, :b => 2}
    end
  end
end