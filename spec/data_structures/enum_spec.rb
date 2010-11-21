require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'akurum/data_structures/enum'

module Akurum
  describe Enum do
    it "should let you create an enumeration object with a set of valid options" do
      e = Enum.new(:blah, [:blah, :blorp])
    end
    it "should raise an error if the option you give it is not valid in the set given" do
      lambda {
        e = Enum.new(:blah, [:blorp, :bloop])
      }.should raise_error(ArgumentError)
    end
    it "should give a string version of the enum value from to_s" do
      Enum.new(:blah, [:blah]).to_s.should == "blah"
    end
    it "should give a symbol version of the enum value from to_sym" do
      Enum.new(:blah, [:blah]).to_sym.should == :blah
    end
    
    it "should let you compare two enums with the same set of possible values with ==" do
      (Enum.new(:blah, [:blah, :blorp]) == Enum.new(:blah, [:blah, :blorp])).should be_true
      (Enum.new(:blah, [:blah, :blorp]) == Enum.new(:blorp, [:blah, :blorp])).should be_false
    end
    it "should let you compare two enums with a different set of possible values with ==, and it shouldn't affect comparison" do
      (Enum.new(:blah, [:blah, :blorp]) == Enum.new(:blah, [:blah, :woop])).should be_true
      (Enum.new(:blah, [:blah, :blorp]) == Enum.new(:woop, [:blah, :woop])).should be_false
    end
    
    it "should let you compare two enums with the same set of possible values with eql?" do
      Enum.new(:blah, [:blah, :blorp]).eql?(Enum.new(:blah, [:blah, :blorp])).should be_true
      Enum.new(:blah, [:blah, :blorp]).eql?(Enum.new(:blorp, [:blah, :blorp])).should be_false
    end
    it "should let you compare two enums with a different set of possible values with eql?, and it should affect comparison" do
      Enum.new(:blah, [:blah, :blorp]).eql?(Enum.new(:blah, [:blah, :woop])).should be_false
      Enum.new(:blah, [:blah, :blorp]).eql?(Enum.new(:woop, [:blah, :woop])).should be_false
    end
    
    it "should let you compare an enum with a symbol using ==" do
      e = Enum.new(:blah, [:blah, :blorp])
      (e == :blah).should be_true
      (e == :blorp).should be_false
    end
    it "should let you compare an enum with a string using ==" do
      e = Enum.new(:blah, [:blah, :blorp])
      (e == "blah").should be_true
      (e == "blorp").should be_false
    end
    
    it "should let you compare two enums with ===" do
      (Enum.new(:blah, [:blah, :blorp]) === Enum.new(:blah, [:blah, :blorp])).should be_true
      (Enum.new(:blah, [:blah, :blorp]) === Enum.new(:blorp, [:blah, :blorp])).should be_false
    end
    
    it "should return false if you compare an enum with any other object type with ===" do
      e = Enum.new(:blah, [:blah, :blorp])
      (e === "blah").should be_false
      (e === :blah).should be_false
      (e === :blorp).should be_false
      (e === "blorp").should be_false
    end

    it "should let you change the enum to another valid option, but throw ArgumentError for an invalid one" do
      e = Enum.new(:blah, [:blah, :blorp, :bloop, :woop])
      e.symbol = :blorp
      e.should == :blorp
      e.symbol = :bloop
      e.should == :bloop
      e.symbol = :woop
      e.should == :woop
      e.symbol = :blah
      e.should == :blah
      lambda {
        e.symbol = :wompledoodle
      }.should raise_error(ArgumentError)
    end
    
    it "parse_type should return an Enum object from an SQL enum() column type string" do
      Enum.parse_type("enum('a','b','c')").should == ["a","b","c"]
    end
  end
end