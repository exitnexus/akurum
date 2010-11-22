require File.join(File.dirname(__FILE__), "spec_helper")
require 'akurum/backends'

module Akurum
  describe Backends do
    before(:each) do
      @path = File.join(File.dirname(__FILE__), "test_data")
      $LOAD_PATH.push @path
    end
    
    after(:each) do
      $LOAD_PATH.delete @path
    end
    
    it "should autoload a backend based on its class name" do
      Backends::TestBackend.should be_kind_of(Class)
    end
    
    it "should raise a NameError trying to load a non-existent class" do
      lambda { Backends::FailBackend }.should raise_error(NameError)
    end
    
    it "should raise a NameError if loading the file doesn't result in the correct class being created" do
      lambda { Backends::NoClassBackend }.should raise_error(NameError)
      Object.const_defined?(:BackendTestNonExistent).should be_true
    end
  end
end