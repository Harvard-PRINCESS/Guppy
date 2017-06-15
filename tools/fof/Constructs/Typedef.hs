{-# LINE 1 "Typedef.lhs" #-}
#line 1 "Typedef.lhs"













  module Constructs.Typedef where

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile













  alias :: TypeExpr -> FoFCode PureExpr
  alias typedef = inject (Typedef typedef (return void))





  aliasE :: String ->
            TypeExpr ->
            FoFCode PureExpr
  aliasE incl typedef = inject (TypedefE incl typedef (return void))





  compileTypedef (Typedef (TTypedef typ aliasName) r) binding = 
      let (cont, binding1) = r binding in
      (FStatement (FTypedef typ aliasName) cont,
       binding1)
 
  compileTypedef (TypedefE inclDirective typeDef@(TTypedef typ aliasName) r) binding =
      let (cont, binding1) = r binding in
      (FStatement (FTypedefE inclDirective typeDef) cont,
       binding1)







  runTypedef (Typedef _ r) heap = r heap
  runTypedef (TypedefE _ _ r) heap = r heap

