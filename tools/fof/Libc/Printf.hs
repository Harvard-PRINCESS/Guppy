{-# LINE 1 "Printf.lhs" #-}
#line 1 "Printf.lhs"













  module Libc.Printf where

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF














  printf :: String -> [PureExpr] -> FoFCode PureExpr
  printf format params = inject (Printf format params (return Void))









  compilePrintf (Printf format params r) binding = 
      let (cont, binding1) = r binding in
      (FStatement (FFFICall "printf" ((quote format) : params)) cont, 
       binding1)






  runPrintf (Printf a b r) heap = r heap







