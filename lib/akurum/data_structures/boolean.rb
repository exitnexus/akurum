require "akurum/data_structures/enum_map"

module Akurum
  class Boolean < EnumMap

    BOOL_SYMBOLS = {false => 0, true => 1}

    def initialize(bool=false)
      super(bool, BOOL_SYMBOLS)
    end
  end
end