module Expressions where

import Semantics
import Constructs
import PureExpressions

import IL.FoF.FoF



data Heap = Hp { freshLoc :: Int ,
                 refMap :: [(VarName, Data)],
                 freshSLoc :: Int,
                 strMap :: [(VarName, [(String, Data)])],
                 freshALoc :: Int,
                 arrayMap :: [(VarName, [Data])]}

runAlgebra :: FoFConst (Heap -> (PureExpr, Heap)) -> 
              (Heap -> (PureExpr, Heap))



data Binding = Binding { freshVar :: Int ,
                         defStructs :: [(String,TypeExpr)],
                         defUnions :: [(String,TypeExpr)],
                         defEnums :: [(String, [(String, Int)])] }

compileAlgebra :: FoFConst (Binding -> (ILFoF, Binding)) ->
                  (Binding -> (ILFoF, Binding))
