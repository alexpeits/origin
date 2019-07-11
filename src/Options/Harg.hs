{-# LANGUAGE PatternSynonyms #-}
module Options.Harg
  ( Opt

  , Single (..)
  , single
  , TSingle (..)
  , tsingle

  , Nested (..)
  , nested
  , getNested
  , TNested (..)
  , tnested
  , getTNested

  , toOpt

  , optLong
  , optShort
  , optHelp
  , optMetavar
  , optEnvVar
  , optDefault

  , option
  , optionWith
  , flag
  , flagWith
  , switch
  , switchWith
  , switch'
  , switchWith'
  , argument
  , argumentWith

  , parseWith
  , readParser
  , strParser
  , boolParser

  , getCtx
  , ctxFromArgs
  , ctxFromEnv
  , pureCtx

  , execOpt
  , execOptDef
  , execCommands
  , execCommandsDef

  , EnvSource (..)
  , JSONSource (..)
  , YAMLSource (..)
  , noSources
  , defaultSources

  , (:*) (..)
  , Tagged (..)

  , VariantF (..)
  , pattern In1
  , pattern In2
  , pattern In3
  , pattern In4
  , pattern In5

  , foldF

  , AssocListF (..)
  , (:+)
  , pattern (:+)
  , (:->)

  -- re-exports
  , B.FunctorB
  , B.TraversableB
  , B.ProductB

  , HKD.HKD
  , HKD.build
  , HKD.construct
  ) where

import           Options.Harg.Construct
import           Options.Harg.Het.HList
import           Options.Harg.Het.Prod
import           Options.Harg.Het.Variant
import           Options.Harg.Nested
import           Options.Harg.Operations
import           Options.Harg.Single
import           Options.Harg.Sources
import           Options.Harg.Sources.Env
import           Options.Harg.Sources.JSON
import           Options.Harg.Sources.NoSource
import           Options.Harg.Sources.YAML
import           Options.Harg.Types

import qualified Data.Barbie                   as B
import qualified Data.Generic.HKD              as HKD
