require "akurum/data_structures/enum"
require "akurum/data_structures/enum_map"
require "akurum/data_structures/boolean"
require "akurum/backends/mysql"

require 'date'
require 'time'

module Akurum::Backends
  #Column acts as a type bridge between SQL and Ruby and also stores column info.
  class Mysql::Column < Base::Column
    AUTO_INCR = "auto_increment"
    BOOL_Y = 'y'
    BOOL_N = 'n'

    # The default for this column in SQL string format (nil if none)
    attr_reader :default
    # The default for this column in ruby object format (nil if none)
    attr_reader :default_value
    attr_reader :extra
    attr_reader :enum_symbols
    attr_reader :name
    attr_reader :sym_type

    #Takes a row from SqlDB#fetch_fields(table) as a constructor.
    def initialize(column_info, enum_map = nil)
      @name = column_info['Field'];

      # setup optional properties
      # NOTE: those are only set if needed, this will make object smaller
      @primary = true if column_info['Key'] == 'PRI'
      @unique = true if column_info['Key'] == 'PRI' || column_info['Key'] == 'UNI'
      @key = true if column_info['Key'];
      @nullable = true if column_info['Null'] != 'NO'
      @extra = column_info['Extra'] if column_info['Extra']

      /^(\w+)(\(.*\))?.*$/ =~ column_info['Type'];
      @sym_type = "#{$1}".to_sym

      @default = column_info['Default'];

      if (@sym_type == :enum)
        @enum_symbols = Akurum::Enum.parse_type(column_info['Type'])

        # initialize boolean property for enums
        if (@enum_symbols.length == 2)
          if (enum_symbols.include?(BOOL_N) && enum_symbols.include?(BOOL_Y))
            @sym_type = :boolean
          end
        elsif (@enum_symbols.length == 1)
          if (enum_symbols.include?(BOOL_Y) && @nullable)
            @sym_type = :boolean
          end
        end
      end
      if (!enum_map.nil?)
        @enum_map = enum_map
        @enum_symbols = enum_map.keys
        @sym_type = :enum_map
      end

      if (@default.nil?)
        @default_value = nil
      else
        @default_value = parse_string(@default)
      end
    end
    
    def primary?
      @primary
    end
    def unique?
      @unique
    end
    def key?
      @key
    end
    
    def nullable?
      @nullable
    end

    def auto_increment?
      @extra == AUTO_INCR
    end

    #Transforms a string into the column's corresponding ruby type.
    def parse_string(string)
      if (@enum_map.nil?)
        return self.send(@sym_type, string);
      else
        return enum_map(self.send(@sym_type, string));
      end
    end

    private
    def varchar(string)
      return string
    end
    def tinyint(string)
      return string.to_i
    end
    def text(string)
      return string
    end
    def date(string)
      return Date.parse(string)
    end
    def smallint(string)
      return string.to_i
    end
    def mediumint(string)
      return string.to_i
    end
    def int(string)
      return string.to_i
    end
    def bigint(string)
      return string.to_i
    end
    def float(string)
      return string.to_f
    end
    def double(string)
      return string.to_f
    end
    def decimal(string)
      return string.to_f
    end
    def datetime(string)
      timestamp(string)
    end
    def timestamp(string)
      return Time.parse(string)
    end
    def char(string)
      return string
    end
    def tinyblob(string)
      return string
    end
    def tinytext(string)
      return string
    end
    def blob(string)
      return string
    end
    def mediumblob(string)
      return string
    end
    def mediumtext(string)
      return string
    end
    def longblob(string)
      return string
    end
    def longtext(string)
      return string
    end
    def boolean(string)
      return Akurum::Boolean.new((string == BOOL_Y))
    end
    def enum(string)
      return Akurum::Enum.new(string, @enum_symbols)
    end
    def enum_map(string)
      return Akurum::EnumMap.new(string, @enum_map)
    end
  end
end