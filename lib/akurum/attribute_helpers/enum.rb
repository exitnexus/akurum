require "akurum/data_structures/enum"

module Akurum
  module AttributeHelpers
    # define name and name= to wrap around an Enum type.
    # if a symbol is invalid it will raise exception on assignment.
    # Example:
    #   class Blah
    #     extend AttributeHelpers
    #     enum_attr :blah, :a, :b, :c
    #   end
    #   x = Blah.new
    #   x.blah = :a
    #   x.blah # => :a
    #   x.blah = :sldfkas # raises ArgumentError
    def enum_attr(sym_name, *syms)
      sym_name = sym_name.to_sym
      variable_name = :"@#{variable_name}"
      syms.flatten!

      self.send(:define_method, sym_name) {
        if (instance_variable_defined?(variable_name))
          return instance_variable_get(variable_name).symbol;
        else
          instance_variable_set(variable_name, Enum.new(syms.first, syms));
          return instance_variable_get(variable_name).symbol;
        end
      }

      self.send(:define_method, :"#{sym_name}=") { |symbol|
        if (instance_variable_defined?(variable_name))
          instance_variable_get(variable_name).symbol = symbol;
        else
          instance_variable_set(variable_name, Enum.new(symbol, syms));
        end
      }
    end
  end
end