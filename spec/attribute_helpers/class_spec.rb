require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'akurum/attribute_helpers/class'

module Akurum
  describe AttributeHelpers do
    it "should let you define readers and writers separately through class_attr_reader and class_attr_writer" do
      class Test1
        extend AttributeHelpers
      
        class_attr_reader :woop
        class_attr_writer :woop
      end
    
      Test1.woop = "blah"
      Test1.woop.should == "blah"
    end
    
    it "should let you define multiple readers and writers through class_attr_reader and class_attr_writer" do
      class Test2
        extend AttributeHelpers
        
        class_attr_reader :woop, :bloop
        class_attr_writer :woop, :bloop
      end
      
      Test2.woop = "woop"
      Test2.woop.should == "woop"
      Test2.bloop = "bloop"
      Test2.bloop.should == "bloop"
    end
    
    it "should let you define readers and writers through class_attr_accessor" do
      class Test3
        extend AttributeHelpers
        
        class_attr_accessor :woop
      end
      Test3.woop = "woop"
      Test3.woop.should == "woop"
    end
    
    it "should let you define multiple readers and writers through class_attr_accessor" do
      class Test4
        extend AttributeHelpers
        
        class_attr_accessor :woop, :bloop
      end
      
      Test4.woop = "woop"
      Test4.woop.should == "woop"
      Test4.bloop = "bloop"
      Test4.bloop.should == "bloop"
    end
    
    it "should let you define a single accessor through class_attr" do 
      class Test5
        extend AttributeHelpers
        
        class_attr :woop
      end
      
      Test5.woop = "woop"
      Test5.woop.should == "woop"
    end
    
    it "should let you define only a reader through class_attr" do
      class Test6
        extend AttributeHelpers
        
        class_attr :woop, false
      end
      
      Test6.woop.should == nil
    end
    
    it "should let you read/write a parent class' attribute from a child class" do
      class Test7
        extend AttributeHelpers
        
        class_attr :woop
      end
      class Test8 < Test7; end
      
      Test7.woop = "woop"
      Test7.woop.should == "woop"
      Test8.woop.should == "woop"
      Test8.woop = "bloop"
      Test7.woop.should == "bloop"
    end
    
    it "should override a parent class' attribute if you re-declare it in a child" do
      class Test9
        extend AttributeHelpers
        
        class_attr :woop
      end
      class Test10 < Test9
        class_attr :woop
      end
      
      Test9.woop = "woop"
      Test10.woop.should == nil
      Test10.woop = "bloop"
      Test9.woop.should == "woop"
    end
    
    it "should let you use the class attribute from right in the class" do
      class Test11
        extend AttributeHelpers
        
        class_attr :woop

        self.woop = "blah" # in a perfect world, this wouldn't need the self. part
        self.woop.should == "blah"
      end
      Test11.woop.should == "blah"
    end
  end
end