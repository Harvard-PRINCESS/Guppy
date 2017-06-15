{-# LINE 1 "MemToPhys.lhs" #-}
#line 1 "MemToPhys.lhs"













  module Libbarrelfish.MemToPhys where

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile
  import IL.FoF.Run













  mem_to_phys :: PureExpr -> FoFCode PureExpr
  mem_to_phys cte = inject (MemToPhys Nothing cte return)
 
  mem_to_physN :: String -> PureExpr -> FoFCode PureExpr
  mem_to_physN name cte = inject (MemToPhys (Just name) cte return)





  compileMemToPhys (MemToPhys mName arg r) binding = 
      let (loc, binding1) = getFreshVar binding in
      let name = case mName of
                   Just x -> Provided x
                   Nothing -> makeVarName Local loc in
      let ref = CLRef Local uint64T name in
      let (cont, binding2) = r ref binding1 in
      (FStatement (FFFICall "mem_to_phys" [ref, arg]) cont,
       binding2)






  runMemToPhys (MemToPhys _ a r) heap = error "MemToPhys: eval not implemented"
