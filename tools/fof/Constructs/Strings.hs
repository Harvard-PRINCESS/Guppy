{-# LINE 1 "Strings.lhs" #-}
#line 1 "Strings.lhs"













  module Constructs.Strings where

  import Data.Maybe

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile
















  newString :: String -> FoFCode Loc
  newString value = inject (NewString Nothing value return)
 
  newStringN :: String -> String -> FoFCode Loc
  newStringN name value = inject (NewString (Just name) value return)






  compileString (NewString name dat r) binding =
      let (publicName, binding1)
              = case name of
                  Just x -> (Provided x, binding)
                  Nothing -> 
                      let (loc, binding1) = getFreshVar binding in
                      (makeVarName Global loc,
                       binding1) in
      let ret = CLRef Global 
                      (TArray (StaticArray $ length dat) TChar) 
                      publicName in
      let (cont, binding2) = r ret binding1 in
      (FStatement (FNewString publicName dat) cont,
       binding2)






  runString (NewString a b r) heap = uncurry r $ runNewString b heap

  runNewString :: String -> Heap -> (Loc, Heap)
  runNewString string heap = 
      let loc = freshALoc heap in
      let size = length string in
      let name = makeVarName Dynamic loc in
      let ref = CLRef Dynamic (TArray (StaticArray size) TChar) name in
      let heap1 = heap { freshALoc = loc + 1,
                         arrayMap = (name, map cchar string) : (arrayMap heap) } in
      (ref, heap1)
