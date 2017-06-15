{-# LINE 1 "Compile.lhs" #-}
#line 1 "Compile.lhs"













  module Compile where

  import Semantics
  import Constructs
  import PureExpressions
  import Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile

  import IL.Paka.Paka
  import IL.Paka.Syntax
  import IL.Paka.Optimizer
































  compile :: Semantics FoFConst PureExpr -> PakaCode
  compile sem =
      optimizePaka $!
      compileFoFtoPaka $!
      compileSemtoFoF sem

























