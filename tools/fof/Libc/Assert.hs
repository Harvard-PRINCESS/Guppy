{-# LINE 1 "Assert.lhs" #-}
#line 1 "Assert.lhs"













  module Libc.Assert where

  import Text.PrettyPrint.HughesPJ as Pprinter

  import Semantics

  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF











  assert :: PureExpr -> FoFCode PureExpr
  assert test = inject (Assert test (return Void))





  compileAssert (Assert e r) binding = 
      let (cont, binding1) = r binding in
      (FStatement (FFFICall "assert" [e]) cont,
       binding1)







  runAssert (Assert a r) heap = r heap




