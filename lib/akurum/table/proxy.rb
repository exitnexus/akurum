module Akurum
  class Table
    class Proxy < Lazy::Promise
      #Proxy::TableClass is defined in Table#inherited so that it maps to the correct child class of Table
    
      attr_reader :properties_hash
    
      def initialize(properties_hash, &block)
        @properties_hash = properties_hash
      
        #we need to use __class__ rather than class here so that the method call isn't passed through to
        #the underlying object (nil in this case)
        @unsafe_columns = self.__class__::TableClass.columns.keys - properties_hash.keys
        @table = self.__class__::TableClass.new(false)
        @table.update_method = :update
      
        # BEGIN CRAZiNESS! (To solve a set of problems where promised Table objects were returning nil values for columns
        # that are not nil because the promise was not getting triggered). If you define a method on a Table that uses
        # "unsafe" columns, before this CRAZiNESS was added, you would find yourself within that method, inside the dummy
        # @table that's getting created here, where every column was nil except for the columns passed in via the
        # properties_hash. The code essentially forgets that it's operating within a proxy object at this point. The code
        # within this section is here to help it "remember".
      
        # Get the eigenclass! Wow, this was the first time I heard of an eigenclass too, and while it's not in wikipedia, it
        # is a reasonably common term in the Ruby community for a "singleton class" (i.e. a class that is only for a single
        # object). Check out http://rubysnips.com/enter-the-eigenclass-singleton for more info. I'm going to use it here
        # to undefine the "unsafe methods" from our dummy Table object so that any calls to them will trip the method_missing
        # method, which I can then define to go back to this class.
        table_eigenclass = class << @table; self; end
        @unsafe_columns.each { |m| 
          table_eigenclass.send :undef_method, m
          table_eigenclass.send :undef_method, :"#{m}=" if @table.respond_to? :"#{m}="
          table_eigenclass.send :undef_method, :"#{m}!" if @table.respond_to? :"#{m}!"
        }

        # Store a pointer to this proxy object in the dummy table object so that if we access one of the "unsafe" columns
        # within a "safe" method that we got into by accident, we'll realize that we are in the dummy object (via the fact that
        # the "unsafe" method will now be missing, due to the undef calls above) and trigger method_missing on the proxy object
        # so that it will trigger the proper response from the lazy promise. Whew! Just writing that out almost got me into a
        # Tomloop. Hopefully no one will ever have to revisit this code, or if they do, these comments help a bit.
        @table.instance_variable_set :@__table_proxy__, self      
        def @table.method_missing(method, *args, &block)
          if (@__table_proxy__.unsafe_method(method))
            @__table_proxy__.method_missing(method, *args, &block)
          end
        end
        # END CRAZiNESS!
      
        properties_hash.each {|column, value|
          @table.instance_variable_set(:"@#{column}", value)
        }
        super() {
          result = yield
          result.instance_variable_set(:@relations_to, @table.instance_variable_get(:@relations_to))
          result.instance_variable_set(:@modified_hash, @table.modified_hash)
          result
        }
      end
    
      def respond_to?(*args)
        return @table.respond_to?(*args) || super(*args)
      end
    
      def unsafe_method(method)
        #convert the method to how it would look if it was accessing a column
        normalized_method = method.to_s
        normalized_method.chomp!('=')
        normalized_method.chomp!('!')
        normalized_method = normalized_method.to_sym
      
        return @unsafe_columns.include?(normalized_method);
      end
    
      def method_missing(method, *args, &block)
        #@computation should be true if and only if the promise is unevaluated.
        if (@computation)
          #the only thing we reject are columns not passed into the constructor
          #this allows functions that only depend on safe columns to work properly
          #and functions which depend on unsafe columns will simply hit this again and
          #execute the promise
          unless (unsafe_method(method))
            return @table.send(method, *args, &block)
          end
        end
        #if it is already calculated or is unsafe then just let Lazy deal with it
        super
      end
    end
  end
end