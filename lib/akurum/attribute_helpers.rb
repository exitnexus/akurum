module Akurum
  # Defines a set of attribute helpers for data types
  # that are useful in an ORM. Include into a class with:
  #   extend AttributeHelpers
  # You use extend so the methods become available in the
  # class scope rather than in the instance's.
  module AttributeHelpers
  end
  
  require 'akurum/attribute_helpers/class'
  require 'akurum/attribute_helpers/enum'
  require 'akurum/attribute_helpers/enum_map'
end