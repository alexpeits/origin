module Options.Harg.Cmdline where
  -- ( mkOptparseParser
  -- , execParserPure
  -- ) where

import           Control.Applicative  ((<|>))
import           Data.Functor.Compose (Compose (..))
import           Data.List            (foldl')
import           Data.Maybe           (fromMaybe)

import qualified Data.Barbie          as B
import qualified Options.Applicative  as Optparse

import           Options.Harg.Pretty  (ppHelp)
import           Options.Harg.Types

-- | Create a 'Optparse.Parser' from a list of source results and an option
-- parser. The source results are folded using '<|>' and then used as a single
-- result.
mkOptparseParser
  :: forall f a.
     ( Applicative f
     , B.TraversableB a
     , B.ProductB a
     )
  => [a (Compose Maybe f)]  -- ^ Source results
  -> a (Compose Opt f)      -- ^ Target configuration options
  -> Optparse.Parser (a (Compose Maybe f))
mkOptparseParser sources opts
  = B.bsequence $ B.bzipWith mkParser srcOpts opts
  where
    srcOpts
      = foldl'
          (B.bzipWith (<|>))
          (B.bmap (const (Compose Nothing)) opts)
          sources

-- | Create a 'Optparse.Parser' for a single option, using the accumulated
-- source results.
mkParser
  :: Compose Maybe f a   -- ^ Accumulated source results
  -> Compose Opt f a     -- ^ Target option
  -> Compose Optparse.Parser (Compose Maybe f) a
mkParser srcs opt@(Compose Opt{..})
  = case _optType of
      OptionOptType      -> toOptionParser srcs opt
      FlagOptType active -> toFlagParser srcs opt active
      ArgumentOptType    -> toArgumentParser srcs opt

-- | Create a 'Optparse.Parser' for an 'OptionOpt', which results in an
-- @optparse-applicative@ 'Optparse.option'.
toOptionParser
  :: Compose Maybe f a
  -> Compose Opt f a
  -> Compose Optparse.Parser (Compose Maybe f) a
toOptionParser sources (Compose opt@Opt{..})
  = Compose
      $ fmap Compose
      $ Optparse.optional
      $ Optparse.option (Optparse.eitherReader _optReader)
      $ foldMap (fromMaybe mempty)
          [ Optparse.long <$> _optLong
          , Optparse.short <$> _optShort
          , Optparse.help <$> ppHelp opt
          , Optparse.metavar <$> _optMetavar
          , Optparse.value <$> (getCompose sources <|> _optDefaultVal)
          ]

-- | Create a 'Optparse.Parser' for a 'FlagOpt', which results in an
-- @optparse-applicative@ 'Optparse.flag'.
toFlagParser
  :: Compose Maybe f a
  -> Compose Opt f a
  -> f a
  -> Compose Optparse.Parser (Compose Maybe f) a
toFlagParser sources (Compose opt@Opt{..}) active
  = Compose
    $ fmap Compose
    $ Optparse.optional
    $ case mDef of
        Nothing ->
          Optparse.flag' active modifiers
        Just def ->
          Optparse.flag def active modifiers
  where
    mDef
      = getCompose sources <|> _optDefaultVal
    modifiers
      = foldMap (fromMaybe mempty)
          [ Optparse.long <$> _optLong
          , Optparse.short <$> _optShort
          , Optparse.help <$> ppHelp opt
          ]

-- | Create a 'Optparse.Parser' for a 'ArgumentOpt', which results in an
-- @optparse-applicative@ 'Optparse.argument'.
toArgumentParser
  :: Compose Maybe f a
  -> Compose Opt f a
  -> Compose Optparse.Parser (Compose Maybe f) a
toArgumentParser sources (Compose opt@Opt{..})
  = Compose
      $ fmap Compose
      $ Optparse.optional
      $ Optparse.argument (Optparse.eitherReader _optReader)
      $ foldMap (fromMaybe mempty)
          [ Optparse.help <$> ppHelp opt
          , Optparse.metavar <$> _optMetavar
          , Optparse.value <$> (getCompose sources <|> _optDefaultVal)
          ]

-- | Run the optparse-applicative parser and return the
-- 'Optparse.ParserResult'
execParserPure
  :: [String]
  -> Optparse.Parser a
  -> Optparse.ParserResult a
execParserPure args parser
  = Optparse.execParserPure Optparse.defaultPrefs parserInfo args
  where
    parserInfo
      = Optparse.info (Optparse.helper <*> parser) Optparse.forwardOptions
