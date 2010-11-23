require 'akurum/context'
module Akurum
  module SpecHelpers
    class SpecContext < Context
      attr_reader :query_items, :other_items
      
      def initialize()
        super
        @query_items = []
        @other_items = []
      end
      
      def log(item, level = 0)
        if (item.kind_of? Backends::Mysql::Log)
          @query_items << item
        else
          @other_items << item
        end
      end
      
    end
    
    class SpecContextQueryCountMatcher
      def initialize(wanted_count)
        @wanted_count = wanted_count
      end
      def matches?(block)
        inner_ctx = SpecContext.new()
        Context.use(inner_ctx) do
          block.call
        end
        @real_count = inner_ctx.query_items.length
        if (@wanted_count.nil?)
          return @real_count > 0
        else
          return @real_count == @wanted_count
        end
      end
      def failure_message
        if (@wanted_count.nil?)
          "expected queries to run, but none were"
        else
          "expected #{@wanted_count} queries to run, #{@real_count} were run instead"
        end
      end
      def negative_failure_message
        if (@wanted_count.nil?)
          "expected no queries to run, but #{@real_count} were"
        else
          "expected a number of queries other than #{@wanted_count} to run"
        end
      end
    end
    class SpecContextQueryMatcher
      def initialize(wanted_query)
        @wanted_query = wanted_query
      end
      def matches?(block)
        @inner_ctx = SpecContext.new()
        Context.use(@inner_ctx) do
          block.call
        end
        @inner_ctx.query_items.each do |log|
          if (log.query == @wanted_query)
            return true
          end
        end
        return false
      end
      def failure_message
        str = "expected query: '#{@wanted_query}', but it didn't run. Found the following queries:\n"
        @inner_ctx.query_items.each do |log|
          str << "\t'" << log.query << "'\n"
        end
        return str
      end
      def negative_failure_message
        "expected query not to run: '#{@wanted_query}', but it did run."
      end
    end
    
    def run_queries(n = nil)
      SpecContextQueryCountMatcher.new(n)
    end
    def run_query(query)
      SpecContextQueryMatcher.new(query)
    end
  end
end