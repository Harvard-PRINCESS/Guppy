{-# LINE 1 "References.lhs" #-}
#line 1 "References.lhs"














  module Constructs.References where

  import Text.PrettyPrint.HughesPJ as Pprinter
  import Data.Maybe

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile

















  newRef :: Data -> FoFCode Loc
  newRef d = inject (NewRef Nothing d return)
 
  newRefN :: String -> Data -> FoFCode Loc
  newRefN name d = inject (NewRef (Just name) d return)



  readRef :: Loc -> FoFCode Data
  readRef l = inject (ReadRef l return)
 
  writeRef :: Loc -> Data -> FoFCode PureExpr
  writeRef l d = inject (WriteRef l d (return Void))

















  compileReferences (NewRef refName ref r) binding =
      (FStatement (FNewRef publicName ref) cont,
       binding2)         
          where (publicName, binding1)
                    = case refName of
                      Just x -> (Provided x, binding)
                      Nothing -> 
                          let (loc, binding1) = getFreshVar binding in
                          (makeVarName Local loc, binding1) 
                ret = CLRef Local (TPointer (typeOf ref) Avail) publicName 
                (cont, binding2) = r ret binding1 
 
  compileReferences (ReadRef ref@(CLRef _ _ xloc) r) binding =
      (FStatement (FReadRef name ref) cont, 
       binding2)
          where (loc, name, binding1) = heritVarName binding xloc 
                ret = CLRef Local (unfoldPtrType ref) name 
                (cont, binding2) = r ret binding1



  compileReferences (WriteRef ref d r) binding =
      (FStatement (FWriteRef ref d) cont,
       binding1)
          where (cont, binding1) = r binding 







  runReferences (NewRef _ d r) heap = uncurry r $ runNewRef d heap
  runReferences (ReadRef l r) heap = uncurry r $ runReadRef l heap
  runReferences (WriteRef l v r) heap = r $ runWriteRef l v heap



  runNewRef :: Data -> Heap -> (Loc, Heap)
  runNewRef value heap =
      ( CLRef Local typeOfVal name, heap2 )
          where typeOfVal = typeOf value 
                loc = freshLoc heap
                refs = refMap heap 
                name = makeVarName Local loc 
                heap1 = heap { freshLoc = loc + 1 } 
                heap2 = heap1 { refMap = (name, value) : refs } 
 
  runReadRef :: Loc -> Heap -> (Data, Heap)
  runReadRef (CLRef _ _ location) heap =
      let refs = refMap heap in
      let val = fromJust $ location `lookup` refs in
      (val, heap)
 
  runWriteRef :: Loc -> Data -> Heap -> Heap
  runWriteRef (CLRef _ _ location) value heap =
      let refs = refMap heap in
      let refs1 = (location, value) : refs in
      heap { refMap = refs1 }
