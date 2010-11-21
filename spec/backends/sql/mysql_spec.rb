require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
require 'backends/sql/helper'
require 'akurum/backends/sql/mysql'

module Akurum::Backends::SQL
  describe MySQL do    
    DATABASE_OPTIONS = {
      :host => 'localhost',
      :login => 'akurum_test',
      :passwd => 'akurum_test',
      :db => 'akurum_test_dev'
    }
    
    it "should be able to connect and disconnect successfully." do
      config = MySQL::Config.new(:options => DATABASE_OPTIONS)
      server = MySQL.new(:single, 1, config)
      server.connect.should be(true)
      server.close.should eql(true)
    end
    
    describe "connected" do
      before(:each) do
        config = MySQL::Config.new(:options => DATABASE_OPTIONS)
        @server = MySQL.new(:single, 1, config)
        @server.connect
        @id = 1
      end
    
      after(:each) do
        @server.close
      end
    
      it "should be able to populate the database with test data" do
        HelperBackendSQL::populate_test(@server)
      end
      
      describe "and populated" do
        before(:each) do
          HelperBackendSQL::populate_test(@server)
        end
    
        it "should support basic single server operations" do
          sql = "SELECT num,str FROM tmp"
          result = @server.query(sql)
          result.should be_kind_of(MySQL::DBResultMysql)
          result.num_rows().should eql(result.total_rows())

          sql = "SELECT SQL_CALC_FOUND_ROWS num,str FROM tmp WHERE id < #{HelperBackendSQL::TEST_DATA_ROWS_SQL / 2} LIMIT 20"
          result = @server.query(sql)
          result.should be_kind_of(MySQL::DBResultMysql)
          result.num_rows().should_not eql(result.total_rows())
        end
        
        it "should fetch and store query results" do
          rows_before = []
          rows_streamed = []
          rows_after = []

          sql = "SELECT num,str FROM tmp WHERE id < #{HelperBackendSQL::TEST_DATA_ROWS_SQL / 2} ORDER BY num"

          result_before = @server.query(sql)
          result_before.should be_kind_of(MySQL::DBResultMysql)
          result_before.each {|row| rows_before << row['num']}

          result_streamed = @server.query_streamed(sql)
          result_streamed.should be_kind_of(MySQL::DBResultMysql)
          result_streamed.each {|row| rows_streamed << row['num']}
          # this shouldn't retrieve any additional rows
          result_streamed.each {|row| rows_streamed << row['num']}

          # check if we can query correctly after stream query
          result_after = @server.query(sql)
          result_after.should be_kind_of(MySQL::DBResultMysql)
          result_after.each {|row| rows_after << row['num']}

          # validate that replies are the same
          rows_before.length.should eql(rows_streamed.length)
          rows_before.length.should eql(rows_after.length)
          rows_before.length.times {|i| rows_before[i].should eql(rows_streamed[i])}
          rows_before.length.times {|i| rows_before[i].should eql(rows_after[i])}
        end
        
        it "should raise QueryException for a bad query" do
          # in this query we have error
          sql = "SELECT SOMETHING num,str FROM tmp WHERE id < #{HelperBackendSQL::TEST_DATA_ROWS_SQL / 2} ORDER BY num"

          proc {
            @server.query(sql)
          }.should raise_error(Base::QueryError)
        end
        
        it "should handle use and store query synchronization" do
          rows_before = []
          rows_after = []

          sql = "SELECT num,str FROM tmp WHERE id < #{HelperBackendSQL::TEST_DATA_ROWS_SQL / 2} ORDER BY num"

          result_before = @server.query(sql)
          result_before.should be_kind_of(MySQL::DBResultMysql)
          result_before.each {|row| rows_before << row['num']}
          result_streamed = @server.query_streamed(sql)
          result_streamed.should be_kind_of(MySQL::DBResultMysql)

          # validate synchronization error, query after streamed query
          proc {
            result_after = @server.query(sql)
          }.should raise_error(Base::CommandsSyncError)

          # validate that connection is cleaned
          result_before = @server.query(sql)
          result_before.should be_kind_of(MySQL::DBResultMysql)
          result_before.each {|row| rows_after << row['num']}

          # validate results
          rows_before.length.should eql(rows_after.length)
          rows_before.length.times {|i| rows_before[i].should eql(rows_after[i])}
        end
        
        it "should handle query cleanup correctly" do
          sql = "SELECT num,str FROM tmp WHERE id < #{HelperBackendSQL::TEST_DATA_ROWS_SQL / 2} ORDER BY num"

          # validate manual cleanup of streamed query
          @server.query_streamed(sql).free
          @server.query(sql).should be_kind_of(MySQL::DBResultMysql)

          # validate cleanup after broken retrieval of rows
          result = @server.query_streamed(sql)
          result.should be_kind_of(MySQL::DBResultMysql)
          result.each {|row| break}

          # validate that query was cleaned
          @server.query(sql).should be_kind_of(MySQL::DBResultMysql)
        end
      end
    end
  end
end