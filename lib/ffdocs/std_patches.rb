# Reduce data written by the `#inspect` method in `Struct` instances.
class Struct
  def inspect
    str = "#<struct #{self.class.name}"
    to_h.each_pair do |k, v|
      v = v.inspect
      if v.size > 32
        v = "#{v[..32]}…"
      end
      str << " #{k}=#{v}"
    end

    str << ">"
  end
end

# Provides a `memoize` class method. It only works if the
# memoized method has no arguments.
class Class
  def memoize(method_name)
    original = "__memoize_original_#{method_name}"
    memoized = "__memoize_value_#{method_name}"

    alias_method original, method_name

    module_eval <<~RUBY
      def #{method_name}
        @#{memoized} ||= #{original}
      end
    RUBY
  end
end
