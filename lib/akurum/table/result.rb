require 'akurum/table'
module Akurum
  #Table::Result is returned by any find call to Table that doesn't return a single row object
  #its purpose is to add extra functionality to array that is useful for sets of row objects
  #most of the methods are simple wrappers to array methods that return a Table::Result as opposed to an array
  class Table::Result < Array
    attr :total_rows, true
    
    # Meta-information about the keys retrieved in this request. Used internally
    # by Table
    attr :keys
    
    def initialize(*args)
      super(*args)
      @keys = []
    end
  
    def total_rows
      if (@total_rows)
        return @total_rows
      else
        return self.length
      end
    end
  
    def compact
      return Table::Result.new(super)
    end

    def concat(*args)
      if (args.length == 1 && args.first.kind_of?(Array))
        super(*args)
      else
        super(args)
      end
    end
  
    def flatten
      return Table::Result.new(super)
    end
  
    def map(*args)
      return Table::Result.new(super(*args))
    end
    alias :collect :map
  
    #return a table result of objects that matches the tableid (should be of type table)
    def match(tableid)
      return self.select {|element| tableid === element }
    end
  
    def reverse
      return Table::Result.new(super)
    end
  
    def select(*args)
      return Table::Result.new(super(*args))
    end

    def slice(*args)
      result = super(*args)
      if (result)
        return Table::Result.new(result)
      else
        return result
      end
    end
  
    def [](*args)
      super_result = super(*args)
      if (super_result.kind_of? Array)
        return Table::Result.new(super_result)
      else
        return super_result
      end
    end
  
    def to_hash
      hash = {}
      self.each {|table|
        hash[[*table.get_primary_key]] = table
      }
      hash
    end
  
    def sort(*args)
      return Table::Result.new(super(*args))
    end

    def sort_by(*args, &block)
      return Table::Result.new(super(*args, &block))
    end
  
    def uniq
      return Table::Result.new(super)
    end
  
    def |(*args)
      return Table::Result.new(super(*args))
    end
  end
end