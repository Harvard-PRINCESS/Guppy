{-# LINE 1 "Semantics.lhs" #-}
#line 1 "Semantics.lhs"













  module Semantics where

  import Control.Monad






























  data Semantics f a = Pure a
                     | Impure (f (Semantics f a))




  instance Functor f => Functor (Semantics f) where
      fmap f (Pure x) = Pure (f x)
      fmap f (Impure t) = Impure (fmap (fmap f) t)



  instance (Functor f) => Applicative (Semantics f) where
      pure = return
      (<*>) = ap



  instance Functor f => Monad (Semantics f) where
      return = Pure
      (Pure x) >>= f = f x
      (Impure t) >>= f = Impure (fmap (>>= f) t)



  inject :: f (Semantics f a) -> Semantics f a
  inject x = Impure x














  foldSemantics :: Functor f => (a -> b) -> (f b -> b) -> Semantics f a -> b
  foldSemantics pure imp (Pure x) = pure x
  foldSemantics pure imp (Impure t) = imp $ fmap (foldSemantics pure imp) t








  sequenceSem ms = foldr k (return []) ms
      where k m m' = 
                do
                  x <- m
                  xs <- m'
                  return (x : xs)
