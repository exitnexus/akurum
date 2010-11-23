require File.join(File.dirname(__FILE__), "spec_helper")
require 'akurum/backends/mysql'
require 'akurum/table'
require 'akurum/spec_context'

module Akurum
  describe Table do
    include Akurum::SpecHelpers
    
    SERVER_CONFIG = Backends::Mysql::Config.new(:options => {
      :host => 'localhost',
      :login => 'akurum_test',
      :passwd => 'akurum_test',
      :db => 'akurum_test_dev'
    })
    
    around(:each) do |block|
      @server = Backends::Mysql.new(:single, 1, SERVER_CONFIG)
      @context = SimpleContext.new()
      Context.use(@context) do
        block.call
      end
      @server.close
    end

    def create_table(*colinfo)
      @server.query("CREATE TEMPORARY TABLE tmp (#{colinfo.join(',')})")
      ret = Class.new(Table)
      server = @server
      ret.class_eval do
        init_table(server, :tmp)
      end
      return ret
    end
    
    describe "simple table" do
      before(:each) do
        @tmp = create_table("id INT(10) NOT NULL AUTO_INCREMENT", "text VARCHAR(50) NOT NULL", "PRIMARY KEY(id)")
      end
      
      it "should let you create a Table subclass for a table" do
        @tmp.should be_kind_of(Class)
      end

      it "should be able to insert an item without specifying the auto_increment id" do
        i = @tmp.new
        i.text = "boom"
        i.store
      end
    
      it "should raise an error if you try to fetch all results from a table without :scan" do
        lambda { @tmp.find() }.should raise_error(Table::UnconstrainedQuery)
      end

      it "should let you insert an item into a table" do
        i = @tmp.new
        i.id = 100
        i.text = "boom"
        i.store
      end
    
      describe "with lots of items" do
        include SpecHelpers
        before(:each) do
          (0...100).each do |i|
            item = @tmp.new
            item.id = i + 1
            item.text = i.to_s
            item.store
          end
        end
        
        it "should let you get items out of a table through a table scan with :scan" do
          res = @tmp.find(:scan)
          (0...100).each do |i|
            res[i].id.should == i + 1
            res[i].text.should == i.to_s
          end
        end
        
        it "should let you get any individual item that was inserted by id with :first" do
          res = @tmp.find(:first, 50)
          res.id.should == 50
          res.text.should == "49"
        end
        
        it "should let you update an item fetched from the table" do
          res = @tmp.find(:first, 50)
          res.id.should == 50
          res.text = "boom"
          res.store
        end
        
        it "should let you delete an item fetched from the table" do
          res = @tmp.find(:first, 50)
          res.id.should == 50
          res.delete
        end
        
        it "should let you get an individual item as part of a set without :first" do
          res = @tmp.find(50)
          res.length.should == 1
          res[0].id.should == 50
          res[0].text.should == "49"
        end
        
        it "should let you get several items as part of a set at once" do
          res = @tmp.find(1, 2, 3)
          [1, 2, 3].each do |i|
            res[i-1].id.should == i
            res[i-1].text.should == (i-1).to_s
          end
        end
        
        it "should let you define a WHERE clause directly" do
          res = @tmp.find(:conditions => "id = 50")
          res.first.should be_kind_of(@tmp)
          res.first.id.should == 50
        end
        
        it "should let you define a WHERE clause with placeholders directly" do
          res = @tmp.find(:conditions => ["id = ?", 50])
          res.first.should be_kind_of(@tmp)
          res.first.id.should == 50
        end
        
        it "should let you stream results with a block" do
          idx = 0
          @tmp.find(:scan) do |row|
            row.text.should == idx.to_s
            row.id.should == (idx += 1)
          end
        end
        
        it "should let you fetch a subset of items with :limit and :offset" do
          res = @tmp.find(:scan, :limit => 20, :offset => 20)
          res.length.should == 20
          (20...40).each do |i|
            res[i-20].id.should == i+1
          end
        end
        
        it "should let you fetch a subset of items with :limit and :page" do
          res = @tmp.find(:scan, :limit => 20, :page => 3)
          res.length.should == 20
          (40...60).each do |i|
            res[i-40].id.should == i+1
          end
        end
        
        it "should return guesstimate information about the paging through total_pages, total_rows, and more?" do
          res = @tmp.find(:scan, :limit => 20, :page => 1)
          # these are wrong because it's guessing due to the fact that it didn't use calc_found_rows to determine the real number of results
          res.total_pages.should == 2
          res.total_rows.should == 40
          res.more?.should be_true
        end
        
        it "should return the correct page information when on the last page, even if calc_rows wasn't used" do
          res = @tmp.find(:scan, :limit => 30, :page => 4)
          res.total_pages.should == 4
          res.total_rows.should == 100
          res.more?.should be_false
        end
        
        it "should return the correct page information if :calc_rows is used" do
          res = @tmp.find(:scan, :limit => 20, :page => 1, :calc_rows => true)
          res.total_pages.should == 5
          res.total_rows.should == 100
          res.more?.should be_true
          
          res = @tmp.find(:scan, :limit => 30, :page => 4, :calc_rows => true)
          res.total_pages.should == 4
          res.total_rows.should == 100
          res.more?.should be_false
        end
        
        it "should give the same object if the same row is fetched twice" do
          res = @tmp.find(:first, 1)
          res.id.should == 1
          res2 = @tmp.find(:first, 1)
          res2.id.should == 1
          
          res.object_id.should == res2.object_id
        end
        
        it "should give the same object if the same row is fetched with two different id lists" do
          res = @tmp.find(1,2,3)
          res = res[1]
          res.id.should == 2
          
          res2 = @tmp.find(2,3,4)
          res2 = res2[0]
          res2.id.should == 2
          
          res.object_id.should == res2.object_id
        end
        
        it "should give the same object if the same row is fetched in two different ways" do
          res = @tmp.find(:first, 50)
          res.id.should == 50
          
          res2 = @tmp.find(:first, :conditions => ['text = ?', "49"])
          res2.should be_kind_of(@tmp)
          res2.id.should == 50
          
          res.object_id.should == res2.object_id
        end
        
        it "should give a consistent result within the same context even if an outside force changes the row" do
          res = @tmp.find(:first, 50)
          res.id.should == 50
          res.text.should == "49"
          
          @server.query("UPDATE tmp SET text = 'boom' WHERE id = 50")
          
          res2 = @tmp.find(:first, 50)
          res2.id.should == 50
          res2.text.should == "49"
        end
        
        it "should give a refreshed result from a new context if an outside force changed the row" do
          Context.use(SimpleContext.new) do
            res = @tmp.find(:first, 50)
            res.id.should == 50
            res.text.should == "49"
          end
          
          @server.query("UPDATE tmp SET text = 'boom' WHERE id = 50")
          
          Context.use(SimpleContext.new) do
            res2 = @tmp.find(:first, 50)
            res2.id.should == 50
            res2.text.should == "boom"
          end
        end
        
        it "should give a refreshed result if explicitly asked to with :refresh, and the original object should be updated" do
          res = @tmp.find(:first, 50)
          res.id.should == 50
          res.text.should == "49"
          
          @server.query("UPDATE tmp SET text = 'boom' WHERE id = 50")
          
          res2 = @tmp.find(:first, :refresh, 50)
          res2.id.should == 50
          res2.text.should == "boom"
          res.text.should == "boom"
        end
        
        it "should only run one SELECT query against the database if the same item is fetched twice, and should give the same object both times" do
          lambda {
            res = @tmp.find(:first, 1)
            res.id.should == 1
            res2 = @tmp.find(:first, 1)
            res2.id.should == 1
          }.should run_queries(1)
        end        
      end
        
    end
    
    describe "compound indexes" do
      before(:each) do
        @tmp = create_table(
          "user_id INT(10) NOT NULL", 
          "item_id INT(10) NOT NULL", 
          "parent_id INT(10) NOT NULL",
          "text VARCHAR(50) NOT NULL", 
          "PRIMARY KEY(user_id, item_id)",
          "INDEX compound_index(user_id, parent_id)")
        
        (0...20).each do |i|
          (0...20).each do |j|
            item = @tmp.new
            item.user_id = i
            item.item_id = j
            item.parent_id = j - 1
            item.text = "#{i}:#{j}"
            item.store
          end
        end
      end
      
      it "should let you fetch a single item from the compound primary key" do
        res = @tmp.find(:first, 0, 5)
        res.user_id.should == 0
        res.item_id.should == 5
        res.parent_id.should == 4
        res.text.should == "0:5"
      end
      
      it "should let you fetch multiple items by their primary key" do
        res = @tmp.find([0, 5], [10, 15])
        res[0].user_id.should == 0
        res[0].item_id.should == 5
        res[1].user_id.should == 10
        res[1].item_id.should == 15
      end
      
      it "should let you fetch an item by the compound secondary key by naming it as a parameter to the find" do
        res = @tmp.find(:first, :compound_index, 9, 12)
        res.user_id.should == 9
        res.parent_id.should == 12
      end
      
      it "should let you fetch multiple items by the compound secondary key by naming it as a parameter to the find" do
        res = @tmp.find(:compound_index, [1, 2], [3, 4], [5, 6])
        res[0].user_id.should == 1
        res[0].parent_id.should == 2
        res[1].user_id.should == 3
        res[1].parent_id.should == 4
        res[2].user_id.should == 5
        res[2].parent_id.should == 6
      end
    end
  end
end