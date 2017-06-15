{-# LINE 1 "HasDescendants.lhs" #-}
#line 1 "HasDescendants.lhs"













  module Libbarrelfish.HasDescendants where

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile
  import IL.FoF.Run














  has_descendants :: PureExpr -> FoFCode PureExpr
  has_descendants cte = inject (HasDescendants Nothing cte return)
 
  has_descendantsN :: String -> PureExpr -> FoFCode PureExpr
  has_descendantsN name cte = inject (HasDescendants (Just name) cte return)






  compileHasDescendants (HasDescendants mName arg r) binding =
      let (loc, binding1) = getFreshVar binding in
      let name = case mName of
                   Nothing -> makeVarName Local loc
                   Just x -> Provided x in
      let ref = CLRef Local uint64T name in
      let (cont, binding2) = r ref binding1 in
      (FStatement (FFFICall "has_descendants" [ref, arg]) cont, 
       binding2)







  runHasDescendants (HasDescendants _ a r) heap = error "HasDescendants: eval not implemented"
