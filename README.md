# `harg` :nut_and_bolt:

`harg` is a library for configuring programs by scanning command line arguments, environment
variables and default values. Under the hood, it uses a subset of `optparse-applicative` to expose
regular arguments, switch arguments and subcommands. The library relies heavily on the use of higher
kinded data (HKD), especially the `barbies` library. Using `higgledy` also allows for reducing
boilerplate significantly.

The main goal while developing `harg` was to not have to go through the usual pattern of manually
`mappend`ing the results of command line parsing, env vars and defaults.

# Usage

(WIP)

Here are some different usage scenarios. Let's first enable some language extensions and add some
imports:

``` haskell
{-# LANGUAGE DeriveAnyClass     #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE DerivingVia        #-}
{-# LANGUAGE FlexibleInstances  #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications   #-}
{-# LANGUAGE TypeOperators      #-}

import           Data.Function    ((&))
import           GHC.Generics     (Generic)

import qualified Data.Barbie      as B
import qualified Data.Generic.HKD as HKD

import           Data.Harg

main :: IO ()
main = putStrLn "this is a literate haskell file"
```

## One flat (non-nested) datatype

The easiest scenario is when the target configuration type is one single record with no levels of
nesting:

``` haskell
data FlatConfig
  = FlatConfig
      { _fcHost :: String
      , _fcPort :: Int
      , _fcLog  :: Bool  -- whether to log or not
      }
  deriving (Show, Generic)
```

(The `Generic` instance is required for section `3` later on)

There are 3 ways to configure this datatype.

### 1. Using a `barbie` type

`barbie` types are types of kind `(Type -> Type) -> Type`. The `barbie` type for `FlatConfig`
looks like this:

``` haskell
data FlatConfigB f
  = FlatConfigB
      { _fcHostB :: f String
      , _fcPortB :: f Int
      , _fcLogB  :: f Bool
      }
  deriving (Generic, B.FunctorB, B.TraversableB, B.ProductB)
```

I also derived some required instances that come from the `barbies` package. These instances allow
us to change the `f` (`bmap` from `FunctorB`), traverse all types in the record producing side
effects (`btraverse` from `TraversableB`) and to treat two HKDs with different `f`s as a product of
these type constructors. The last one is useful for defining the semigroup instance, which can be
trivially derived via a helper `Barbie` newtype, exposed by this package:

``` haskell
deriving via (Barbie FlatConfigB OptValue) instance Semigroup (FlatConfigB OptValue)
```

Where `OptValue` is the specific type constructor we want the `Semigroup` instance for, and it is
a sum type that keeps information on whether the option construction was successful, if something
was not found or whether there was a parsing error.

Now let's define the value of this datatype, which holds our option configuration. The type
constructor needed for the options is `Opt`:

``` haskell
flatConfigOpt1 :: FlatConfigB Opt
flatConfigOpt1
  = FlatConfigB hostOpt portOpt logOpt
  where
    hostOpt
      = mkOpt ( arg "host" strParser
              & optShort 'h'
              & optMetavar "HOST"
              & optHelp "The database host"
              )
    portOpt
      = mkOpt ( arg "port" readParser
              & optHelp "The database port"
              & optEnvVar "DB_PORT"
              & optDefault 5432
              )
    logOpt
      = mkOpt ( switch "log"
              & optHelp "Whether to log or not"
              )
```

Here, we use `arg` to define a command line argument that expects a value after it, and `switch` to
define a boolean command line flag that, if present, sets the target value to `True`. The `opt*`
functions (here applied using `&` to make things look more declarative) modify the option
configuration. `optHelp` adds help text, `optDefault` adds a default value, `optShort` adds a short
command line option as an alternative to the long one (the string after `arg` or `switch`),
`optEnvVar` sets the associated environment variable and `optMetavar` sets the metavariable to be
shown in the help text generated by `optparse-applicative`.

Now let's actually run things:

``` haskell
getFlatConfig1 :: IO ()
getFlatConfig1 = do
  FlatConfigB host port log <- getOptions flatConfigOpt1

  config <- execOpt (FlatConfig <$> host <*> port <*> log)

  print config
```

(`execOpt` is a helper function that either returns the value or fails and prints an error message)

`getOptions` returns an `OptValue x` where `x` is the type of the options we are configuring, in
this case `FlatConfigB`. Here, we pattern matched on the barbie-type, and then used the
`Applicative` instance of `OptValue` to get back a `OptValue FlatConfig`. By using `execOpt`, if the
parsing was successful, we get back the `FlatConfig` and print it.

This is still a bit boilerplate-y. Let's look at another way.

### 2. Using an `HList`

Looking at `FlatConfigB`, it's only used because of it's `barbie`-like capabilities. Other than that,
it's just a simple product type with the additional `f` before all its sub-types.

An `HList` (heterogeneous list) is like an arbitrary length tuple. For example,
`HList '[Int, Bool, String]` is exactly the same as `(Int, Bool, String)`. `harg` defines an
enhanced version of `HList` called `HListF`, which stores barbie-like types and also keeps the `f`
handy: `data HListF (xs :: [(Type -> Type) -> Type]) (f :: Type -> Type) where ...`. `HListF` is
also easily made an instance of `Generic`, `FunctorB`, `TraversableB`, `ProductB` and `Semigroup`
(when `f ~ OptValue`). With all that, let's rewrite the options value and the function to get the
configuration:

``` haskell
flatConfigOpt2 :: (Single String :* Single Int :* Single Bool) Opt
flatConfigOpt2
  = single hostOpt :* single portOpt :* single logOpt :* HNilF
  where
    hostOpt
      = mkOpt ( arg "host" strParser
              & optShort 'h'
              & optMetavar "HOST"
              & optHelp "The database host"
              )
    portOpt
      = mkOpt ( arg "port" readParser
              & optHelp "The database port"
              & optEnvVar "DB_PORT"
              & optDefault 5432
              )
    logOpt
      = mkOpt ( switch "log"
              & optHelp "Whether to log or not"
              )

getFlatConfig2 :: IO ()
getFlatConfig2 = do
  host :* port :* log :* _ <- getOptions flatConfigOpt2

  config <- execOpt (FlatConfig <$> getSingle host <*> getSingle port <*> getSingle log)

  print config
```

This looks aufully similar to the previous version, but without having to write another datatype
and derive all the instances. `:*` is both a type-level constructor and a value-level function
(actually pattern) that acts like list's `:`. Thanks to type families, there's no need to terminate
it using a `nil` when writing the type signature (although a `HNilF` is required when writing values
or when pattern matching).

The `Single` type constructor is used when talking about a single value, rather than a nested
datatype. `Single a f` is a simple newtype over `f a`. The reason for using that is simply to
switch the order of application, so that we can later apply the `f` (here `Opt`) to the compound
type (which is the `HList`). In addition, `single` is used to wrap an `f a` into a `Single a f`, and
`getSingle` is used to unwrap it. Later on we'll see how to construct nested configurations using
`Nested`.

However, the real value when having flat datatypes comes from the ability to use `higgledy`.

### 3. Using `HKD` from `higgledy`

``` haskell
flatConfigOpt3 :: HKD.HKD FlatConfig Opt
flatConfigOpt3
  = HKD.build @FlatConfig hostOpt portOpt logOpt
  where
    hostOpt
      = mkOpt ( arg "host" strParser
              & optShort 'h'
              & optMetavar "HOST"
              & optHelp "The database host"
              )
    portOpt
      = mkOpt ( arg "port" readParser
              & optHelp "The database port"
              & optEnvVar "DB_PORT"
              & optDefault 5432
              )
    logOpt
      = mkOpt ( switch "log"
              & optHelp "Whether to log or not"
              )

getFlatConfig3 :: IO ()
getFlatConfig3 = do
  result <- getOptions flatConfigOpt3

  config <- execOpt (HKD.construct result)

  print config
```

This is the most straightforward way to work with flat configuration types. The `build` function
takes as arguments the options (`Opt a` where `a` is each type in `FlatConfig`) **in the order they
appear in the datatype**, and returns the generic representation of a type that's exactly the same
as `FlatConfigB`. This means that we get all the `barbie` instances for free.

To go back from the `HKD` representation of a datatype to the base one, we use `construct`.
`construct` uses the applicative instance of the `f` which wraps each type in `FlatConfig` to give
back an `f FlatConfig` (in our case an `OptValue FlatConfig`).

# Roadmap

- Print errors using `optparse-applicative`'s internals
- Be able to use the same type for many tagged subcommands
