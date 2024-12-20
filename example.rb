# typed: strict

require 'sorbet-runtime'

# Raising in the validation error handler is a pretty common practice, although
# it's often tied to configuration and whatnot. For the minimal repro, we'll
# just always raise.
#
# If we *don't* raise, then Tapioca will run without crashing.
T::Configuration.call_validation_error_handler = lambda do |signature, opts|
  raise TypeError.new(opts[:pretty_message])
end

# We start with the simplest possible generic
# interface definition.
module Container
  extend T::Sig
  extend T::Generic

  interface!

  Value = type_member
end

# And the simplest possible implementation.
class ConcreteContainer
  extend T::Sig
  extend T::Generic

  include Container
  Value = type_member
end

# First up, we illustrate a usage of the interface
# that *doesn't* crash.
module BasicTest
  extend T::Sig

  sig { params(container: Container[Integer]).void }
  def self.test(container)
    # This can be a no-op because we're only testing
    # interactions with the type checker.
  end
end

# This call works just fine.
BasicTest.test(ConcreteContainer[Integer].new)

# But if we use the same interface in a struct...
class StructTest < T::Struct
  const :container, Container[Integer]
end

# We crash when we try to create an instance!
StructTest.new(container: ConcreteContainer[Integer].new)
