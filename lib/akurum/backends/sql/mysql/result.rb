require 'akurum/backends/sql/mysql'

module Akurum
  module Backends
    module SQL
      class MySQL
        # the result of a SELECT query from the mysql implementation of the SqlDB class
        class Result < Base::Result
          def initialize(db, result, total_rows)
            @db = db; #the db object
            @result = result; #the result object
            @total_rows = total_rows; #if the query had SQL_CALC_FOUND_ROWS, this is the result of that
            @freed = false
          end

          def free
            @freed = true
            begin
              @result.free
            rescue Mysql::Error
              # it's really obnoxious that:
              # free() raises if it's already been freed
              # it raises a generic error object with a string.
              # it doesn't provide a way to tell if the results have already been freed.
              raise if ($!.message != "Mysql::Result object is already freed")
            end
          end

          # Check whether result is empty
          def empty?
            return @result.empty?
          end

          # Check whether there are still pending use_results to fetch
          def pending?
            return !(@result.eof)
          end

          # number of rows in the result set. Equivalent to fetch_set.length
          # possibly should be avoided, as most dbs don't have this function
          def num_rows()
            return @result.num_rows();
          end

          # if the query had SQL_CALC_FOUND_ROWS, this is the result of that, otherwise just num_rows
          def total_rows()
            if(@total_rows)
              return @total_rows;
            else
              return num_rows();
            end
          end

          #number of rows affected by the last query. If another query was run since this one, this will be wrong!
          def affected_rows()
            return @db.db.affected_rows();
          end

          #insert id of the last query. If another query was run since this one, this will be wrong!
          def insert_id()
            return @db.db.insert_id();
          end

          # return one result at a time as a hash
          def fetch
            return @result.fetch_hash()
          end

          # return one result at a time as an array
          # generally only useful for: col1, col2 = fetch_array()
          def fetch_array
            return @result.fetch_row();
          end

          # loop through the associated code block with each row as a hash as the parameter
          # NOTE: if +mutex+ is present then it synchronizes on yield. This variant
          #       may be used to ensure no race condition during parallel blocks execution.
          def each(mutex = nil)
            return if @freed

            if mutex
              # yield each row with synchronization
              while (line = @result.fetch_hash())
                mutex.synchronize {yield line}
              end
            else
              # yield each row
              while (line = @result.fetch_hash())
                yield line
              end
            end
          ensure
            # always clear result for use results
            free()
          end

          def collect
            out = []
            while(line = @result.fetch_hash())
              out.push(yield(line))
            end
            out
          end

          # return an array of all the rows as hashes
          def fetch_set()
            results = [];

            while(line = @result.fetch_hash())
              results.push(line);
            end

            return results;
          end

          # return a single field
          # generally only useful for queries that always return exactly one row with one column
          def fetch_field()
            return fetch_array()[0];
          end

          def use_result()
            # validate correct type
            if @result.class != Mysql
              raise SqlBase::ResultError.new("Result already stored/used")
            end

            @result = @result.use_result()
            return self
          end

          def store_result()
            # validate correct type
            if @result.class != Mysql
              raise SqlBase::ResultError.new("Result already stored/used")
            end

            @result = @result.store_result()
            return self
          end
        end
      end
    end
  end
end