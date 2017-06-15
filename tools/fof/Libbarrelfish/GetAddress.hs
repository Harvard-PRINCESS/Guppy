{-# LINE 1 "GetAddress.lhs" #-}
#line 1 "GetAddress.lhs"













  module Libbarrelfish.GetAddress where

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile
  import IL.FoF.Run














  get_address :: PureExpr -> FoFCode PureExpr
  get_address cte = inject (GetAddress Nothing cte return)
 
  get_addressN :: String -> PureExpr -> FoFCode PureExpr
  get_addressN name cte = inject (GetAddress (Just name) cte return)





  compileGetAddress (GetAddress mName arg r) binding = 
      let (loc, binding1) = getFreshVar binding in
      let name = case mName of
                   Just x -> Provided x
                   Nothing -> makeVarName Local loc in
      let ref = CLRef Local uint64T name in
      let (cont, binding2) = r ref binding1 in
      (FStatement (FFFICall "get_address" [ref, arg]) cont,
       binding2)






  runGetAddress (GetAddress _ a r) heap = error "GetAddress: eval not implemented"
