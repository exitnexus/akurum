module Kernel
  if (methods.include?(:funcall))
    alias send funcall
  end
end

module Akurum
  module AttributeHelpers
    # Defines a class attribute on the class executed in. If +writer+ is true,
    # it will define a writer as well as a reader.
    # Example:
    #   class Blah
    #     extend AttributeHelpers
    #     class_attr :blah, true
    #   end
    #   Blah.blah = "blorp"
    #   Blah.blah # => "blorp"
    # Going through a child class that doesn't re-define the attribute
    # will set the same attribute as the parent class:
    #   class Blah
    #     extend AttributeHelpers
    #     class_attr :blah, true
    #   end
    #   class Blorp < Blah
    #     blah = "woop"
    #   end
    #   Blorp.blah # => "woop"
    #   Blah.blah # => "woop"
    def class_attr(symbol, writer=true)
      class_attr_reader(symbol);
      class_attr_writer(symbol) if writer;
    end

    # Defines a class attribute on the class executed in. Defines
    # both a reader and a writer.
    # Example:
    #   class Blah
    #     extend AttributeHelpers
    #     class_attr_accessor :blah, :blorp
    #   end
    #   Blah.blah = "blorp"
    #   Blah.blah # => "blorp"
    #   Blah.blorp = "woop"
    #   Blah.blorp # => "woop"
    # See AttributeHelpers.class_attr for more information.
    def class_attr_accessor(*syms)
      class_attr_reader(*syms);
      class_attr_writer(*syms);
    end

    # Defines a class attribute on the class executed in. Defines
    # only a reader (this behaviour seems kind of useless, and is
    # only here for symmetry with instance attributes)
    # Example:
    #   class Blah
    #     extend AttributeHelpers
    #     class_attr_reader :blah, :blorp
    #     class_attr_writer :blah, :blorp
    #   end
    #   Blah.blah = "blorp"
    #   Blah.blah # => "blorp"
    #   Blah.blorp = "woop"
    #   Blah.blorp # => "woop"
    # See AttributeHelpers.class_attr for more information.
    def class_attr_reader(*syms)
      self_name = self.to_s;
      self_name.gsub!(':', '_');

      syms.flatten.each { |sym|
        if (!class_variable_defined?("@@#{self_name}_#{sym}"))
          class_variable_set(:"@@#{self_name}_#{sym}", nil);
        end

        self.send(:define_method, sym) {
          return self.class.send(sym);
        }

        Thread.current['class_attr_temp'] = [self_name, sym];
        class << self
          self_name, sym = ::Thread.current['class_attr_temp'];
          variable_name = :"@@#{self_name}_#{sym}"
          self.send(:define_method, sym) {
            class_variable_get(variable_name);
          }
        end
      }
    end


    # Defines a class attribute on the class executed in. Defines
    # only a writer (this behaviour seems kind of useless, and is
    # only here for symmetry with instance attributes)
    # Example:
    #   class Blah
    #     extend AttributeHelpers
    #     class_attr_reader :blah, :blorp
    #     class_attr_writer :blah, :blorp
    #   end
    #   Blah.blah = "blorp"
    #   Blah.blah # => "blorp"
    #   Blah.blorp = "woop"
    #   Blah.blorp # => "woop"
    # See AttributeHelpers.class_attr for more information.
    def class_attr_writer(*syms)
      self_name = self.to_s;
      self_name.gsub!(':', '_');

      syms.flatten.each { |sym|
        self.send(:define_method, :"#{sym}=") { |value|
          self.class.send(:"#{sym}=", value);
        }

        Thread.current['class_attr_temp'] = [self_name, sym];
        class << self
          self_name, sym = ::Thread.current['class_attr_temp'];
          variable_name = :"@@#{self_name}_#{sym}"
          self.send(:define_method, :"#{sym}=") { |value|
            class_variable_set(variable_name, value);
          }
        end
      }
    end
  end
end