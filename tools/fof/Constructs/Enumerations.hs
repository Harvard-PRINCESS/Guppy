{-# LINE 1 "Enumerations.lhs" #-}
#line 1 "Enumerations.lhs"













  module Constructs.Enumerations where

  import Data.Maybe 

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile














  newEnum :: String ->
             Enumeration ->
             String ->
             FoFCode PureExpr
  newEnum nameEnum fields value =
      inject (NewEnum Nothing nameEnum fields value return)



  newEnumN :: String ->
             String ->
             Enumeration ->
             String ->
             FoFCode PureExpr
  newEnumN name nameEnum fields value =
      inject (NewEnum (Just name) name fields value return)





  compileEnumerations (NewEnum name enumName vals value r) binding = 
      (FStatement (FNewEnum publicName enumName vals value) cont, 
       binding3)
          where (publicName, binding2) 
                    = case name of
                        Just x -> (Provided x, binding)
                        Nothing -> (makeVarName Local loc,
                                    binding1)
                            where (loc, binding1) = getFreshVar binding 
                ret = CLRef Global uint64T (Provided value) 
                (cont, binding3) = r ret binding2

















  runEnumerations (NewEnum _ _ enum name r) heap =
      let ref = uint64 $ toInteger $ fromJust $ name `lookup` enum in
      r ref heap 
