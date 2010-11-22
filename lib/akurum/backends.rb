module Akurum
  # This module will auto-load backends by attempting to load
  # Akurum::Backends::ClassName => "akurum/backends/class_name"
  # This allows for external gem-based backends by going through
  # a generic load mechanism.
  module Backends
    def self.const_missing(sym)
      path_name = sym.to_s.gsub(/^([A-Z])/) {|c| $1.downcase }.gsub(/(.)([A-Z])/) {|c| $1 + "_" + $2.downcase }
      begin
        require(File.join("akurum", "backends", path_name))
      rescue LoadError
        raise NameError, "uninitialized constant #{sym}, autoload of akurum/backends/#{path_name} failed."
      end
      if (!const_defined? sym)
        raise NameError, "uninitialized constant #{sym}, autoload of akurum/backends/#{path_name} failed."
      end
      return const_get(sym)
    end
  end
end