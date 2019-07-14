{-# LANGUAGE AllowAmbiguousTypes  #-}
{-# LANGUAGE PatternSynonyms      #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE UndecidableInstances #-}
module Options.Harg.Het.Variant where

import           Data.Kind            (Type)

import qualified Data.Barbie          as B

import           Options.Harg.Het.Nat


data VariantF (xs :: [(Type -> Type) -> Type]) (f :: Type -> Type) where
  HereF  :: x f           -> VariantF (x ': xs) f
  ThereF :: VariantF xs f -> VariantF (y ': xs) f

instance
    ( B.FunctorB x
    , B.FunctorB (VariantF xs)
    ) => B.FunctorB (VariantF (x ': xs)) where
  bmap nat (HereF x)   = HereF $ B.bmap nat x
  bmap nat (ThereF xs) = ThereF $ B.bmap nat xs

instance B.FunctorB (VariantF '[]) where
  bmap _ _ = error "Impossible: empty variant"

instance
    ( B.TraversableB x
    , B.TraversableB (VariantF xs)
    ) => B.TraversableB (VariantF (x ': xs)) where
  btraverse nat (HereF x)   = HereF <$> B.btraverse nat x
  btraverse nat (ThereF xs) = ThereF <$> B.btraverse nat xs

instance B.TraversableB (VariantF '[]) where
  btraverse _ _ = error "Impossible: empty variant"

-- u mad?
pattern In1 :: x1 f -> VariantF (x1 ': xs) f
pattern In1 x = HereF x

pattern In2 :: x2 f -> VariantF (x1 ': x2 ': xs) f
pattern In2 x = ThereF (In1 x)

pattern In3 :: x3 f -> VariantF (x1 ': x2 ': x3 ': xs) f
pattern In3 x = ThereF (In2 x)

pattern In4 :: x4 f -> VariantF (x1 ': x2 ': x3 ': x4 ': xs) f
pattern In4 x = ThereF (In3 x)

pattern In5 :: x5 f -> VariantF (x1 ': x2 ': x3 ': x4 ': x5 ': xs) f
pattern In5 x = ThereF (In4 x)

-- Fold
type family FoldSignatureF (xs :: [(Type -> Type) -> Type]) r f where
  FoldSignatureF (x ': xs) r f = (x f -> r) -> FoldSignatureF xs r f
  FoldSignatureF '[] r f = r

class FromVariantF xs result f where
  fromVariantF :: VariantF xs f -> FoldSignatureF xs result f

instance FromVariantF '[x] result f where
  fromVariantF (HereF  x) f = f x
  fromVariantF (ThereF _) _ = error "Impossible: empty variant"

instance
    ( tail ~ (x' ': xs)
    , FromVariantF tail result f
    , IgnoreF tail result f
    ) => FromVariantF (x ': x' ': xs) result f where
  fromVariantF (ThereF x) _ = fromVariantF @_ @result x
  fromVariantF (HereF  x) f = ignoreF @tail (f x)

class IgnoreF (args :: [(Type -> Type) -> Type]) result f where
  ignoreF :: result -> FoldSignatureF args result f

instance IgnoreF '[] result f where
  ignoreF result = result

instance IgnoreF xs result f => IgnoreF (x ': xs) result f where
  ignoreF result _ = ignoreF @xs @_ @f result

-- Inject into variant based on position
class InjectPosF
    (n :: Nat)
    (x :: (Type -> Type) -> Type)
    (xs :: [(Type -> Type) -> Type]) where
  injectPosF :: SNat n -> (x f -> VariantF xs f)

instance InjectPosF Z x (x ': xs) where
  injectPosF SZ = HereF

instance InjectPosF n x xs => InjectPosF (S n) x (y ': xs) where
  injectPosF (SS n) = ThereF . injectPosF n
