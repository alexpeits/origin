{-# LANGUAGE RankNTypes #-}
module Options.Harg.Util where

import           Data.Functor.Compose   (Compose (..))
import           Data.Functor.Const     (Const(..))
import           Data.Functor.Product   (Product (..))

import qualified Data.Barbie            as B

import           Options.Harg.Het.HList
import           Options.Harg.Types


bpairwise
  :: forall a f g h. B.ProductB a
  => (forall x. f x -> g x -> h x)
  -> a f
  -> a g
  -> a h
bpairwise f xs ys
  = B.bmap (\(Pair x y) -> f x y) (B.bprod xs ys)

compose
  :: forall f g a.
      ( Functor f
      , B.FunctorB a
      )
  => (forall x. x -> g x)
  -> a f
  -> a (Compose f g)
compose to
  = B.bmap (Compose . fmap to)

allToDummyOpts
  :: forall m ts xs.
     ( Monoid m
     , MapAssocList xs
     )
  => AssocListF ts xs Opt
  -> AssocListF ts xs (Compose Opt (Const m))
allToDummyOpts
  = mapAssocList toDummyOpts

toDummyOpts
  :: forall m a.
     ( B.FunctorB a
     , Monoid m
     )
  => a Opt
  -> a (Compose Opt (Const m))
toDummyOpts
  = B.bmap toDummy
  where
    toDummy opt@Opt{..}
      = Compose
      $ Const
      <$> opt
            { _optDefault = Just mempty
            , _optReader  = pure . const mempty
            , _optType
                = case _optType of
                    OptionOptType   -> OptionOptType
                    FlagOptType _   -> FlagOptType mempty
                    ArgumentOptType -> ArgumentOptType
            }
