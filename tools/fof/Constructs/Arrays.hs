{-# LINE 1 "Arrays.lhs" #-}
#line 1 "Arrays.lhs"













  module Constructs.Arrays where

  import Data.Maybe

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import Eval

  import IL.FoF.FoF
  import IL.FoF.Compile




















  newArray :: [Data] -> FoFCode Loc
  newArray value = inject (NewArray Nothing DynamicArray value return)

  newStaticArray :: [Data] -> FoFCode Loc
  newStaticArray value = inject (NewArray Nothing (StaticArray $ length value) value return)



  newArrayN :: String -> [Data] -> FoFCode Loc
  newArrayN name value = inject (NewArray (Just name) DynamicArray value return)

  newStaticArrayN :: String -> [Data] -> FoFCode Loc
  newStaticArrayN name value = inject (NewArray (Just name) (StaticArray $ length value) value return)



  readArray :: Loc -> Index -> FoFCode Data
  readArray l f = inject (ReadArray l f return)



  writeArray :: Loc -> Index -> Data -> FoFCode ()
  writeArray l f d = inject (WriteArray l f d (return ()))







  runArrays :: FoFConst (Heap -> (a, Heap)) -> (Heap -> (a, Heap))
  runArrays (NewArray a b c r) heap = uncurry r $ runNewArray b c heap
  runArrays (ReadArray a b r) heap = uncurry r $ runReadArray a b heap
  runArrays (WriteArray a b c r) heap = r $ runWriteArray a b c heap




  runNewArray :: AllocArray -> [Data] -> Heap -> (Loc, Heap)
  runNewArray alloc initData heap = 
      let loc = freshALoc heap in
      let sizeInt = length initData in
      let name = makeVarName Dynamic loc in
      let ref = CLRef Dynamic (TArray alloc $ typeOf $ head initData) name in
      let heap1 = heap { freshALoc = loc + 1,
                         arrayMap = (name, initData) : (arrayMap heap) } in
      (ref, heap1)
 
  runReadArray :: Loc -> Index -> Heap -> (Data, Heap)
  runReadArray (CLRef _ (TArray _ _) loc) index heap = 
      let array = fromJust $ loc `lookup` (arrayMap heap) in
      let (CLInteger _ _ indexInt) = symbEval index in
      let val = array !! (fromInteger indexInt) in
      (val, heap)
 
  runWriteArray :: Loc -> Index -> Data -> Heap -> Heap
  runWriteArray (CLRef _ (TArray _ _) loc) index dat heap = 
      let array = fromJust $ loc `lookup` (arrayMap heap) in
      let (CLInteger _ _ indexInt) = symbEval index in
      let (arrayBegin, arrayEnd) = splitAt (fromInteger indexInt) array in
      let array1 = arrayBegin ++ (dat : tail arrayEnd) in
      let heap1 = heap { arrayMap = (loc, array1) : arrayMap heap } in
      heap1






  compileArrays :: FoFConst (Binding -> (ILFoF, Binding)) ->
                   (Binding -> (ILFoF, Binding))





  compileArrays (NewArray name allocArray dat r) binding =
      let scopeVar 
                = case allocArray of
                DynamicArray -> Dynamic
                StaticArray _ -> Global in
      let (publicName, binding1)
              = case name of 
                Just x -> (Provided x, binding)
                Nothing -> 
                    let (loc, binding1) = getFreshVar binding in
                    (makeVarName scopeVar loc, 
                     binding1) in
      let typeOfDat = typeOf $ head dat in
      let ret = CLRef Dynamic (TArray allocArray typeOfDat) publicName in
      let (cont, binding2) = r ret binding in
      (FStatement (FNewArray publicName allocArray dat) cont, 
       binding2)
 
  compileArrays (ReadArray ref@(CLRef origin (TArray arrayAlloc typ) xloc) index r) binding =
      let (loc, name, binding1) = heritVarName binding xloc in
      let ret = CLRef Dynamic (readOf typ) name in
      let (cont, binding2) = r ret binding1 in
      (FStatement (FReadArray name ref index) cont,
       binding2)
 
  compileArrays (WriteArray ref@(CLRef origin 
                                       (TArray arrayAlloc typ) 
                                       xloc) 
                            index dat r) binding =
      let (cont, binding1) = r binding in
      (FStatement (FWriteArray ref index dat) cont,
       binding1)


