{-# LINE 1 "Unions.lhs" #-}
#line 1 "Unions.lhs"













  module Constructs.Unions where

  import Data.Maybe

  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import Semantics

  import IL.FoF.FoF
  import IL.FoF.Compile












  newStaticUnion :: String -> 
                    [(TypeExpr, String)] -> 
                    String ->
                    Data ->
                    FoFCode Loc
  newStaticUnion name fields field dat = 
      inject (NewUnion Nothing StaticUnion name 
                       (map (\(s1,s2) -> (s2,s1)) fields)
                       (field, dat)
                       return)
 
  newStaticUnionN :: String ->
                     String -> 
                    [(TypeExpr, String)] -> 
                    String ->
                    Data ->
                    FoFCode Loc
  newStaticUnionN nameU name fields field dat = 
      inject (NewUnion (Just nameU) StaticUnion name 
                       (map (\(s1,s2) -> (s2,s1)) fields)
                       (field, dat)
                       return)
 
  newUnion ::  String -> 
               [(TypeExpr, String)] -> 
               String ->
               Data ->
               FoFCode Loc
  newUnion name fields field dat = 
      inject (NewUnion Nothing DynamicUnion
                       name 
                       (map (\(s1,s2) -> (s2,s1)) fields)
                       (field, dat)
                       return)
 
  newUnionN :: String ->
               String -> 
               [(TypeExpr, String)] -> 
               String ->
               Data ->
               FoFCode Loc
  newUnionN nameU name fields field dat = 
      inject (NewUnion (Just nameU) DynamicUnion
                       name 
                       (map (\(s1,s2) -> (s2,s1)) fields)
                       (field, dat)
                       return)



  readUnion :: Loc -> String -> FoFCode Data
  readUnion l f = inject (ReadUnion l f return)

  writeUnion :: Loc -> String -> Data -> FoFCode ()
  writeUnion l f d = inject (WriteUnion l f d (return ()))






  compileUnions (NewUnion refName allocUnion nameU fields (initField, initData) r) binding = 
      (FStatement newU cont, 
       binding2)
          where typeUnion = TUnion DynamicUnion nameU fields 
                (loc, binding1) = getFreshVar binding 
                name = case refName of
                     Nothing -> makeVarName Dynamic loc 
                     Just x -> Provided x 
                ret = CLRef Dynamic typeUnion name 
                (cont, binding2) = r ret binding1 
                newU = FNewUnion name allocUnion nameU fields (initField, initData)
 
  compileUnions (ReadUnion ref@(CLRef _ typeU@(TUnion alloc
                                                      nameU 
                                                      fields) xloc) 
                           field r) binding =
      (FStatement readU cont,
       binding2)
          where (loc, name, binding1) = heritVarName binding xloc 
                typeField = fromJust $ field `lookup` fields 
                origin = allocToOrigin alloc
                ret = CLRef origin (readOf typeField) name
                (cont, binding2) = r ret binding1
                readU = FReadUnion name ref field
                allocToOrigin StaticUnion = Local
                allocToOrigin DynamicUnion = Dynamic
 
  compileUnions (WriteUnion ref@(CLRef origin 
                                   typ@(TUnion alloc _ fields) 
                                   xloc) 
                             field 
                             value r) binding =
      (FStatement writeU cont,
       binding1)
          where (cont, binding1) = r binding 
                writeU = FWriteUnion ref field value









  runUnions (NewUnion _ a b c d r) heap = error "runUnions: not yet implemented"
  runUnions (ReadUnion a b r) heap = error "runUnions: not yet implemented"
  runUnions (WriteUnion a b c r) heap = error "runUnions: not yet implemented"

