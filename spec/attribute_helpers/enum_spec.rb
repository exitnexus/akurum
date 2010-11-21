require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'akurum/attribute_helpers/enum'

module Akurum
  describe AttributeHelpers do
    it "should let you define an enum_attr" do
      class Test1
        extend AttributeHelpers
        
        enum_attr :blah, :a, :b, :c
      end
    end
    
    it "should let you set the value of an enum_attr and read it back" do
      class Test2
        extend AttributeHelpers
        
        enum_attr :blah, :a, :b, :c
      end
      x = Test2.new
      x.blah = :a
      x.blah.should == :a
    end

    it "should raise ArgumentError if you try to set it to something invalid" do
      class Test3
        extend AttributeHelpers

        enum_attr :blah, :a, :b, :c
      end
      x = Test3.new
      lambda {
        x.blah = :d
      }.should raise_error(ArgumentError)
    end
  end
end