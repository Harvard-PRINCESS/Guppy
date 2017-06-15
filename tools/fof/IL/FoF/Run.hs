{-# LINE 1 "Run.lhs" #-}
#line 1 "Run.lhs"













  module IL.FoF.Run where

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions













  run :: Semantics FoFConst PureExpr -> Heap -> (PureExpr, Heap)
  run = foldSemantics (,) runAlgebra


