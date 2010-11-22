require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require 'backends/helper'
require 'akurum/backends/mysql'

module Akurum::Backends
  describe Mysql do
    DATABASE_OPTIONS = {
      :host => 'localhost',
      :login => 'akurum_test',
      :passwd => 'akurum_test',
      :db => 'akurum_test_dev'
    }
    
    it "should be able to connect and disconnect successfully." do
      config = Mysql::Config.new(:options => DATABASE_OPTIONS)
      server = Mysql.new(:single, 1, config)
      server.connect.should be(true)
      server.close.should eql(true)
    end
    
    describe "connected" do
      include BackendsHelper
      
      before(:each) do
        config = Mysql::Config.new(:options => DATABASE_OPTIONS)
        @server = Mysql.new(:single, 1, config)
        @server.connect
        @id = 1
      end
    
      after(:each) do
        @server.close
      end
    
      it "should be able to populate the database with test data" do
        populate_test()
      end
      
      describe "and populated" do
        include BackendsHelper
        
        before(:each) do
          populate_test
        end
    
        it "should support basic single server operations" do
          sql = "SELECT num,str FROM tmp"
          result = @server.query(sql)
          result.should be_kind_of(Mysql::Result)
          result.num_rows().should eql(result.total_rows())

          sql = "SELECT SQL_CALC_FOUND_ROWS num,str FROM tmp WHERE id < #{BackendsHelper::TEST_DATA_ROWS_SQL / 2} LIMIT 20"
          result = @server.query(sql)
          result.should be_kind_of(Mysql::Result)
          result.num_rows().should_not eql(result.total_rows())
        end
        
        it "should fetch and store query results" do
          rows_before = []
          rows_streamed = []
          rows_after = []

          sql = "SELECT num,str FROM tmp WHERE id < #{BackendsHelper::TEST_DATA_ROWS_SQL / 2} ORDER BY num"

          result_before = @server.query(sql)
          result_before.should be_kind_of(Mysql::Result)
          result_before.each {|row| rows_before << row['num']}

          result_streamed = @server.query_streamed(sql)
          result_streamed.should be_kind_of(Mysql::Result)
          result_streamed.each {|row| rows_streamed << row['num']}
          # this shouldn't retrieve any additional rows
          result_streamed.each {|row| rows_streamed << row['num']}

          # check if we can query correctly after stream query
          result_after = @server.query(sql)
          result_after.should be_kind_of(Mysql::Result)
          result_after.each {|row| rows_after << row['num']}

          # validate that replies are the same
          rows_before.length.should eql(rows_streamed.length)
          rows_before.length.should eql(rows_after.length)
          rows_before.length.times {|i| rows_before[i].should eql(rows_streamed[i])}
          rows_before.length.times {|i| rows_before[i].should eql(rows_after[i])}
        end
        
        it "should raise QueryException for a bad query" do
          # in this query we have error
          sql = "SELECT SOMETHING num,str FROM tmp WHERE id < #{BackendsHelper::TEST_DATA_ROWS_SQL / 2} ORDER BY num"

          proc {
            @server.query(sql)
          }.should raise_error(Mysql::QueryError)
        end
        
        it "should handle use and store query synchronization" do
          rows_before = []
          rows_after = []

          sql = "SELECT num,str FROM tmp WHERE id < #{BackendsHelper::TEST_DATA_ROWS_SQL / 2} ORDER BY num"

          result_before = @server.query(sql)
          result_before.should be_kind_of(Mysql::Result)
          result_before.each {|row| rows_before << row['num']}
          result_streamed = @server.query_streamed(sql)
          result_streamed.should be_kind_of(Mysql::Result)

          # validate synchronization error, query after streamed query
          proc {
            result_after = @server.query(sql)
          }.should raise_error(Mysql::CommandsSyncError)

          # validate that connection is cleaned
          result_before = @server.query(sql)
          result_before.should be_kind_of(Mysql::Result)
          result_before.each {|row| rows_after << row['num']}

          # validate results
          rows_before.length.should eql(rows_after.length)
          rows_before.length.times {|i| rows_before[i].should eql(rows_after[i])}
        end
        
        it "should handle query cleanup correctly" do
          sql = "SELECT num,str FROM tmp WHERE id < #{BackendsHelper::TEST_DATA_ROWS_SQL / 2} ORDER BY num"

          # validate manual cleanup of streamed query
          @server.query_streamed(sql).free
          @server.query(sql).should be_kind_of(Mysql::Result)

          # validate cleanup after broken retrieval of rows
          result = @server.query_streamed(sql)
          result.should be_kind_of(Mysql::Result)
          result.each {|row| break}

          # validate that query was cleaned
          @server.query(sql).should be_kind_of(Mysql::Result)
        end
      end
    end
  end
end