# Minimal repro case for a Tapioca Bug

This repository illustrates the minimum configuration required to activate a bug that is present in Tapioca 0.16.5.

## How to use this

1. Clone the repo.
2. Run `bundle`.
3. Run `bundle exec srb tc`: Observe that this runs without any type errors!
4. Run `ruby example.rb`: Still just fine!
5. Run `bundle exec tapioca dsl`: This crashes when evaluating the line `StructTest.new(container: ConcreteContainer[Integer].new)`

## Analysis

Normally, Sorbet performs type erasure on generic types, which we can see in the [implementation of `T::Generic#[]`](https://github.com/sorbet/sorbet/blob/f3331edbb1100a137fc1c8050b4de7765e649d25/gems/sorbet-runtime/lib/types/generic.rb#L11-L13), which just returns the type itself.

However, Tapioca [monkeypatches this method](https://github.com/Shopify/tapioca/blob/14c955d16d3acd6f5897bc1e187920392014d7d7/lib/tapioca/sorbet_ext/generic_name_patch.rb#L13-L19) so that it preserves the type information, which is then accessible to DSL compilers.

For generic interfaces—and presumably, generic classes that have subclasses—this creates the potential for Sorbet validation errors at runtime because concrete implementations don't use `T::Generic#[]` when including the interface they implement.

When Tapioca runs, it sets the default check level to `:never` and overrides all of the Sorbet error handlers to silence them, as seen [here](https://github.com/Shopify/tapioca/blob/14c955d16d3acd6f5897bc1e187920392014d7d7/exe/tapioca#L8-L10).

As long as the application doesn't provide its own error handler, this mostly works fine.

However, `T::Struct` does not respect the value of `T::Configuration.default_checked_level`, so if an application _does_ provide its own handler--which is common enough in legacy apps that may need to configure environment-specific behavior--then any runtime instantiation of a `T::Struct` that refers to a generic interface will crash if instantiated while loading the Rails app.

## Possible resolutions

Here are some of the ways that I could see this going, in increasing order of my own personal preference

- Document this as an official limitation (I hope not!)
- Document the need to explicitly disable Sorbet runtime checks/crashes, ideally with a recommended pattern for doing so
- Maybe figure out a way to monkeypatch `T::Configuration.call_validation_error_handler` so that runtime checks _can't_ be enabled?
- Submit a patch to Sorbet itself so that `T::Struct` respects `T::Configuration.default_checked_level`
