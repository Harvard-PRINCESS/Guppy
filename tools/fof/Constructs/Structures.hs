{-# LINE 1 "Structures.lhs" #-}
#line 1 "Structures.lhs"













  module Constructs.Structures where

  import Data.Maybe

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile

















  newStaticStruct :: String -> 
                     [(TypeExpr, String, Data)] -> 
                     FoFCode Loc
  newStaticStruct name stt = 
      inject (NewStruct Nothing StaticStruct name 
                        (map (\(t,n,v) -> (n,(t,v))) stt) 
                        return)
 
  newStaticStructN :: String ->
                      String -> 
                     [(TypeExpr, String, Data)] -> 
                     FoFCode Loc
  newStaticStructN nameStr name stt = 
      inject (NewStruct (Just nameStr) StaticStruct name 
                        (map (\(t,n,v) -> (n,(t,v))) stt) 
                        return)
 
  newStruct :: String -> 
               [(TypeExpr, String, Data)] -> 
               FoFCode Loc
  newStruct name stt = 
      inject (NewStruct Nothing DynamicStruct name 
                        (map (\(t,n,v) -> (n,(t,v))) stt) 
                        return)
 
  newStructN :: String ->
                String -> 
               [(TypeExpr, String, Data)] -> 
               FoFCode Loc
  newStructN nameStr name stt = 
      inject (NewStruct (Just nameStr) DynamicStruct name 
                        (map (\(t,n,v) -> (n,(t,v))) stt) 
                        return)



  readStruct :: Loc -> String -> FoFCode Data
  readStruct l f = inject (ReadStruct l f return)
 
  writeStruct :: Loc -> String -> Data -> FoFCode ()
  writeStruct l f d = inject (WriteStruct l f d (return ()))







  compileStructures (NewStruct refName allocStruct name fields r) binding =
      (FStatement newS cont,
       binding2)
          where (loc, binding1) = getFreshVar binding 
                structName = case refName of
                             Just x -> Provided x 
                             Nothing -> makeVarName Dynamic loc 
                fieldsTypeStr = [ (field, typ)
                                  | (field,(typ,_)) <- fields] 
                typeStr = TStruct DynamicStruct name fieldsTypeStr 
                ret = CLRef Dynamic typeStr structName 
                (cont, binding2) = r ret binding1 
                newS = FNewStruct structName allocStruct name fields
 
  compileStructures (ReadStruct ref@(CLRef origin 
                                           typ@(TStruct alloc name fields) 
                                           xloc) 
                                field r) binding =
      (FStatement readS cont,
       binding2)
          where (loc, varName, binding1) = heritVarName binding xloc 
                typeField = fromJust $ field `lookup` fields
                ret = CLRef (allocToOrigin alloc) (readOf typeField) varName 
                (cont, binding2) = r ret binding1
                readS = FReadStruct varName ref field
                allocToOrigin StaticStruct = Local
                allocToOrigin DynamicStruct = Dynamic
 
  compileStructures (WriteStruct ref@(CLRef origin 
                                            typ@(TStruct alloc name fields) 
                                            xloc) 
                                 field 
                                 value r) binding =
      (FStatement writeS  cont,
       binding1)
          where (cont, binding1) = r binding 
                writeS = FWriteStruct ref field value






  runStructures (NewStruct _ a b c r) heap = 
      uncurry r $ runNewStruct a b c heap
  runStructures (ReadStruct a b r) heap = 
      uncurry r $ runReadStruct a b heap
  runStructures (WriteStruct a b c r) heap = 
      r $ runWriteStruct a b c heap



  runNewStruct :: AllocStruct ->
                  String -> 
                  [(String, (TypeExpr,Data))] -> 
                  Heap -> (Loc, Heap)
  runNewStruct alloc name struct heap =
      let structT = map (\(x1,(x2,_)) -> (x1,x2)) struct in
      let structD = map (\(x1,(_,x2)) -> (x1,x2)) struct in
      let loc = freshLoc heap in
      let structs = strMap heap in
      let varName = makeVarName Local loc in
      let heap1 = heap { freshLoc = loc + 1 } in
      let heap2 = heap1 { strMap = (varName, structD) : structs } in
      (CLRef Local (TStruct alloc name structT) varName, heap2)
 
  runReadStruct :: Loc -> String -> Heap -> (Data, Heap)
  runReadStruct (CLRef _ _ location) field heap =
      let structs = strMap heap in
      let struct = fromJust $ location `lookup` structs in
      let val = fromJust $ field `lookup` struct in
      (val, heap)
 
  runWriteStruct :: Loc -> String -> Data -> Heap -> Heap
  runWriteStruct (CLRef _ _ location) field value heap =
      let structs = strMap heap in
      let struct = fromJust $ location `lookup` structs in
      let struct1 = (field, value) : struct in
      let structs1 = (location, struct1) : structs in
      heap { strMap = structs1 }
