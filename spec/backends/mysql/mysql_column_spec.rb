require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require 'akurum/backends/mysql/column'

module Akurum::Backends
  describe Mysql::Column do
    #id INT(10) NOT NULL AUTO_INCREMENT,
    #num INT(10) NOT NULL,
    #str TEXT NOT NULL,
    #PRIMARY KEY (id)
    
    COLUMN_SIMPLE_TYPES = {
      "varchar(50)" => {:sym_type => :varchar, :sample => "blah", :result => "blah"},
      "tinyint(2)" => {:sym_type => :tinyint, :sample => "1024", :result => 1024},
      "text(10)" => {:sym_type => :text, :sample => "blah", :result => "blah"},
      "date" => {:sym_type => :date, :sample => "2009-01-22", :result => Date.civil(2009, 1, 22)},
      "smallint(5)" => {:sym_type => :smallint, :sample => "5", :result => 5},
      "mediumint(5)" => {:sym_type => :mediumint, :sample => "50", :result => 50},
      "int(10)" => {:sym_type => :int, :sample => "1002", :result => 1002},
      "bigint(10)" => {:sym_type => :bigint, :sample => "3423423423", :result => 3423423423},
      "float" => {:sym_type => :float, :sample => "3.14", :result => 3.14},
      "double" => {:sym_type => :double, :sample => "3.15", :result => 3.15},
      "decimal" => {:sym_type => :decimal, :sample => "45345.23", :result => 45345.23},
      "datetime" => {:sym_type => :datetime, :sample => "2009-01-22 01:11:11 GMT", :result => Time.gm(2009, 1, 22, 1, 11, 11)},
      "timestamp" => {:sym_type => :timestamp, :sample => "2009-01-22 01:11:11 GMT", :result => Time.gm(2009, 1, 22, 1, 11, 11)},
      "char(10)" => {:sym_type => :char, :sample => "blah", :result => "blah"},
      "tinyblob" => {:sym_type => :tinyblob, :sample => "blah", :result => "blah"},
      "tinytext" => {:sym_type => :tinytext, :sample => "blah", :result => "blah"},
      "blob" => {:sym_type => :blob, :sample => "blah", :result => "blah"},
      "mediumblob" => {:sym_type => :mediumblob, :sample => "blah", :result => "blah"},
      "mediumtext" => {:sym_type => :mediumtext, :sample => "blah", :result => "blah"},
      "longblob" => {:sym_type => :longblob, :sample => "blah", :result => "blah"},
      "longtext" => {:sym_type => :longtext, :sample => "blah", :result => "blah"},
    }
    
    COLUMN_SIMPLE_TYPES.each {|str, info|
      it "should handle a simple #{str} column" do
        x = Mysql::Column.new({'Field' => 'blah', 'Type' => str})
        x.name.should == 'blah'
        x.primary?.should be_false
        x.unique?.should be_false
        x.key?.should be_false
        x.default.should be_nil
        x.default_value.should be_nil
        x.nullable?.should be_true
        x.extra.should be_nil
        x.enum_symbols.should be_nil
        x.sym_type.should == info[:sym_type]
      end
    
      it "should be able to parse what the server gives it for a simple #{str} column" do
        x = Mysql::Column.new({'Field' => 'blah', 'Type' => str})
        x.parse_string(info[:sample]).should == info[:result]
      end
      
      it "should be able to handle a default value for a #{str} column by exposing the original as #default and the parsed value as #default_value" do
        x = Mysql::Column.new({'Field' => 'blah', 'Type' => str, 'Default' => info[:sample]})
        x.default.should == info[:sample]
        x.default_value.should == info[:result]
      end
    }
    
    it "should handle an enumerated column" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => "enum('a','b','c')"})
      x.name.should == 'blah'
      x.primary?.should be_false
      x.unique?.should be_false
      x.key?.should be_false
      x.default.should be_nil
      x.default_value.should be_nil
      x.nullable?.should be_true
      x.extra.should be_nil
      x.enum_symbols.should == ['a','b','c']
      x.sym_type.should == :enum
      
      x.parse_string('a').should == 'a'
      lambda { x.parse_string('d') }.should raise_error(ArgumentError)
    end
    
    it "should handle a boolean column with enum values of 'y' and 'n'" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => "enum('n','y')"})
      x.name.should == 'blah'
      x.primary?.should be_false
      x.unique?.should be_false
      x.key?.should be_false
      x.default.should be_nil
      x.default_value.should be_nil
      x.nullable?.should be_true
      x.extra.should be_nil
      x.sym_type.should == :boolean
      
      x.parse_string('y').should == Akurum::Boolean.new(true)
      x.parse_string('n').should == Akurum::Boolean.new(false)
    end
    
    it "should handle a boolean column with an enum of 'y' and the ability to be null" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => "enum('y')", 'Null' => 'YES'})
      x.name.should == 'blah'
      x.primary?.should be_false
      x.unique?.should be_false
      x.key?.should be_false
      x.default.should be_nil
      x.default_value.should be_nil
      x.nullable?.should be_true
      x.extra.should be_nil
      x.sym_type.should == :boolean
      
      x.parse_string('y').should == Akurum::Boolean.new(true)
      x.parse_string(nil).should == Akurum::Boolean.new(false)
    end      
    
    it "should handle an enum_map column" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => "tinyint(3)"}, {'a' => 0, 'b' => 1, 'c' => 2})
      x.name.should == 'blah'
      x.primary?.should be_false
      x.unique?.should be_false
      x.key?.should be_false
      x.default.should be_nil
      x.default_value.should be_nil
      x.nullable?.should be_true
      x.extra.should be_nil
      x.enum_symbols.sort.should == ['a', 'b', 'c'].sort
      x.sym_type.should == :enum_map
      
      x.parse_string('0').should == Akurum::EnumMap.new('a', {'a' => 0, 'b' => 1, 'c' => 2})
      x.parse_string('b').should == Akurum::EnumMap.new('b', {'a' => 0, 'b' => 1, 'c' => 2})
      lambda { x.parse_string("BOOM") }.should raise_error(ArgumentError)
    end
    
    it "should correctly identify being part of a primary key" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => 'int(10)', 'Key' => "PRI"})
      x.primary?.should be_true
      x.unique?.should be_true
      x.key?.should be_true
    end
    
    it "should correctly identify being part of a unique index" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => 'int(10)', 'Key' => "UNI"})
      x.primary?.should be_false
      x.unique?.should be_true
      x.key?.should be_true
    end
    it "should correctly identify a column as being part of any key" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => 'int(10)', 'Key' => "MUL"})
      x.primary?.should be_false
      x.unique?.should be_false
      x.key?.should be_true
    end
    
    it "should correctly identify a column as being incapable of having a NULL value" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => 'int(10)', 'Null' => 'NO'})
      x.nullable?.should be_false
    end
    
    it "should correctly identify an auto_increment field" do
      x = Mysql::Column.new({'Field' => 'blah', 'Type' => 'int(10)', 'Extra' => 'auto_increment'})
      x.auto_increment?.should be_true
    end
  end
end