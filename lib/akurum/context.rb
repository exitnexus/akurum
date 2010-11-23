module Akurum
  # This class provides a context area for Akurum. In a web framework, for example, this
  # context should be set for the duration of each request. The context provides query 
  # logging and per-request caching. It's important to not use the same context for
  # an indefinitely long period of time or information will accumulate in it and suck up memory.
  class Context
    # Log items must respond to at least to_s, but may provide
    # any additional information desired through other accessors.
    # A Context provider should, by the way, never insist on anything
    # but the to_s requirement. A String object is, in fact, a valid log
    # object.
    class Log
      SPAM = 0
      TRACE = 1
      DEBUG = 2
      INFO = 3
      WARNING = 4
      ERROR = 5
      CRITICAL = 6    
      
      def initialize(string)
        @str = string
      end
      def to_s()
        return @str
      end
    end
    
    # A hash of arbitrary cache objects during this context.
    attr_reader :cache
    
    def initialize()
      @cache = {}
    end

    # Passed an Akurum::Context::Log object for loggable stuff within the context. Examples would
    # include Backends::Base::Log objects for SQL queries and MemCache::Log objects for memcache
    # queries.
    def log(log_item, importance = Log::DEBUG)
    end
    
    # Retrieves a cached key from the context cache object
    def [](key)
      @cache[key]
    end
    
    # Stores a value in the context cache
    def []=(key,value)
      @cache[key] = value
    end
    
    # Called when the context object is activated through Context.use with the previous context object,
    # if any. Base implementation does nothing.
    def start(prev_ctx)
    end
    
    # Called when the context object is deactivated through Context.use. Base implementation
    # does nothing.
    def finish()
    end
    
    # Returns the currently active context for the current thread. Optionally, if a block
    # is passed it will yield the current context (if any) to the block
    def self.current
      cur = Thread.current[:akurum_context_current]
      if (block_given? && !cur.nil?)
        yield cur
      else
        cur
      end      
    end
    
    # Returns the currently active context for the current thread or raises an Akurum::Error if not available
    def self.current!
      Thread.current[:akurum_context_current] || raise(Error, "No currently active context.")
    end
    
    # Uses the object passed in to it as the current context until
    # the end of the passed in block
    def self.use(context)
      new_ctx = context
      Thread.current[:akurum_context_current], context = context, Thread.current[:akurum_context_current]
      begin
        new_ctx.start(context)
        yield
      ensure
        new_ctx.finish
        Thread.current[:akurum_context_current], context = context, Thread.current[:akurum_context_current]
      end
    end
    
    def self.log(log_item, importance = Log::DEBUG)
      cur = current
      cur.log(log_item) if (!cur.nil?)
    end
    def self.log!(log_item, importance = Log::DEBUG)
      cur = current
      raise ArgumentError, "No current context selected." if (cur.nil?)
      cur.log(log_item) if (!cur.nil?)
    end
    def self.[](key)
      cur = current
      raise ArgumentError, "No current context selected." if (cur.nil?)
      cur[key]
    end
    def self.[]=(key, value)
      cur = current
      raise ArgumentError, "No current context selected." if (cur.nil?)
      cur[key] = value
    end
  end

  class SimpleContext < Context
    # An array of Context::Log items, one for each logged entry
    attr_reader :log_items
    
    def initialize(min_log_level = Log::WARNING)
      super()
      @min = min_log_level
      @log_items = []
    end
    
    # Stores the log object in the query_log array.
    def log(log_item, importance = Log::DEBUG)
      @log_items << log_item if importance >= @min
    end
  end
end