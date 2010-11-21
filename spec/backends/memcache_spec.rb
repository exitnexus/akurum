require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'akurum/backends/memcache'

module Akurum::Backends
  describe MemCache do
  	SPEC_MEMCACHE_EXPIRE = 60
  	SPEC_MEMCACHE_KEY = 'spec_memcache'
  	SPEC_MEMCACHE_LOTS = 20480
	
	  describe "single server" do
    	before(:each) do
    		@cache = MemCache.new("localhost:6000")
    		@cache.flush_all
    	end
	
    	after(:each) do
    		@cache.flush_all
    		@cache.close
    	end
	
    	it 'should allow adding a numeric value' do
    		@cache.set(SPEC_MEMCACHE_KEY, 1, SPEC_MEMCACHE_EXPIRE)
    		@cache.get(SPEC_MEMCACHE_KEY).should == 1
    	end

    	it 'should allow adding a string value' do
    		@cache.set(SPEC_MEMCACHE_KEY, 'hello!', SPEC_MEMCACHE_EXPIRE)
    		@cache.get(SPEC_MEMCACHE_KEY).should == 'hello!'
    	end

    	it 'should allow adding a string value that is url-encodeable' do
    		s = 'hello, world!'
    		URI::encode(s).should_not == s
    		@cache.set(SPEC_MEMCACHE_KEY, s, SPEC_MEMCACHE_EXPIRE)
    		@cache.get(SPEC_MEMCACHE_KEY).should == s
    	end

    	it 'should allow adding an array value' do
    		a = [ 1, 2, 'three', 4.0 ]
    		@cache.set(SPEC_MEMCACHE_KEY, a, SPEC_MEMCACHE_EXPIRE)
    		@cache.get(SPEC_MEMCACHE_KEY).should == a
    	end

    	it 'should allow adding a hash value' do
    		h = { :a => 'a', :b => 'bee', :c => 123 }
    		@cache.set(SPEC_MEMCACHE_KEY, h, SPEC_MEMCACHE_EXPIRE)
    		@cache.get(SPEC_MEMCACHE_KEY).should == h
    	end
	
    	it 'should handle compressible value' do
    		s = "s" * 40960
    		@cache.set(SPEC_MEMCACHE_KEY, s, SPEC_MEMCACHE_EXPIRE)
    		@cache.get(SPEC_MEMCACHE_KEY).should == s
    	end

    	it 'should be able to check_and_add a new key' do
    		@cache.delete('spec_memcache_1')
    		@cache.check_and_add('spec_memcache_1', 1).should == true
    	end
	
    	it 'should not allow check_and_add to add a duplicate key' do
    		@cache.delete('spec_memcache_2')
    		@cache.check_and_add('spec_memcache_2', 1).should == true
    		@cache.check_and_add('spec_memcache_2', 1).should == false
    	end
	
    	it 'should timeout and allow adding duplicate key' do
    		@cache.delete('spec_memcache_3')
    		@cache.check_and_add('spec_memcache_3', 1).should == true
    		@cache.check_and_add('spec_memcache_3', 1).should == false
    		sleep 2
    		@cache.check_and_add('spec_memcache_3', 1).should == true
    	end
	
    	it 'should allow setting lots of keys at once' do
    		pairs = Hash.new
    		for i in 1..SPEC_MEMCACHE_LOTS
    			pairs["spec_memcache-#{i}"] = i
    		end
    		@cache.set_many(pairs, SPEC_MEMCACHE_EXPIRE)
    	end
	
    	it 'should allow getting lots of keys at once' do
    		# First, store some values
    		pairs = Hash.new
    		for i in 1..SPEC_MEMCACHE_LOTS
    			pairs["spec_memcache-#{i}"] = i
    			GC.start if (pairs.size % 1024) == 0
    		end
    		@cache.set_many(pairs, SPEC_MEMCACHE_EXPIRE)
		
    		# Now, retrieve them
    		keys = Array.new
    		pairs.each { |k, v|
    			keys << k
    		}
    		@cache.get(*keys).should == pairs.map { |k, v| v }
    	end
	
    	it 'should allow loading lots of keys at once' do
    		# First, store some values
    		pairs = Hash.new
    		for i in 1..SPEC_MEMCACHE_LOTS
    			pairs["spec_memcache-#{i}"] = i
    			GC.start if (pairs.size % 1024) == 0
    		end
    		@cache.set_many(pairs, SPEC_MEMCACHE_EXPIRE)

    		# Now, retrieve them
    		keys = Array.new
    		for i in 1..SPEC_MEMCACHE_LOTS
    			keys << [i.to_s]
    		end
    		retrieved = @cache.load('spec_memcache', keys,
    		 	SPEC_MEMCACHE_EXPIRE) {
    			# Nothing in block
    		}
		
    		retrieved.should == pairs
    	end
	
    	it 'should allow loading with missing keys' do
    		# First, store some values
    		pairs = Hash.new
    		for i in 1..256
    			pairs["spec_memcache-#{i}"] = i
    		end
    		@cache.set_many(pairs, SPEC_MEMCACHE_EXPIRE)
		
    		# Now, prepare some extra values
    		for i in 257..512
    			pairs["spec_memcache-#{i}"] = i
    		end

    		# Now, retrieve them
    		keys = Array.new
    		for i in 1..512
    			keys << [i.to_s]
    		end
    		retrieved = @cache.load('spec_memcache', keys,
    		 	SPEC_MEMCACHE_EXPIRE) { |missing_keys|
    			found_keys = Hash.new
    			missing_keys.each { |k, v|
    				found_keys[k] = k.first.to_i
    			}
    			found_keys
    		}
		
    		retrieved.should == pairs
    	end
    end
    
    describe "multiple servers" do
    	before(:each) do
    		@cache = MemCache.new("localhost:6000", "localhost:6001", "localhost:6002", "localhost:9999") {|k| k }
    		@cache.flush_all
    		@caches = [
    		  MemCache.new("localhost:6000"),
    		  MemCache.new("localhost:6001"),
    		  MemCache.new("localhost:6002")
    		]
    	end
	
    	after(:each) do
    		@cache.flush_all
    		@cache.close
    		@caches.each {|c| c.close }
    	end
    	
    	it "should set a key on a server and be retrievable again through the same interface" do
    	  @cache[0] = "blah"
    	  @cache[1] = "blorp"
    	  @cache[2] = "bloop"
    	  @cache[0].should == "blah"
    	  @cache[1].should == "blorp"
    	  @cache[2].should == "bloop"
  	  end
  	  
  	  it "should set a key on a server and be retrievable again on the correct server" do
    	  @cache[0] = "blah"
    	  @cache[1] = "blorp"
    	  @cache[2] = "bloop"
        
        @caches[0][0].should == "blah"
        @caches[1][1].should == "blorp"
        @caches[2][2].should == "bloop"
        
        @caches[0][1].should be_nil
        @caches[1][2].should be_nil
        @caches[2][0].should be_nil
      end
      
      it "should fail over a key to the next available server if the correct server is down" do
        @cache[3] = "woople"
        @caches[0][3].should == "woople"
        @caches[1][3].should be_nil
        @caches[2][3].should be_nil
      end
    end
  end
end