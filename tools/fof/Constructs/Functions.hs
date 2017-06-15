{-# LINE 1 "Functions.lhs" #-}
#line 1 "Functions.lhs"













  module Constructs.Functions where

  import Data.List
  import Data.Maybe

  import Semantics
  import Constructs
  import PureExpressions
  import {-# SOURCE #-} Expressions

  import IL.FoF.FoF
  import IL.FoF.Compile
  import IL.FoF.Run
















  def :: [FunAttr] ->
         String -> 
         ([PureExpr] -> FoFCode PureExpr) ->
         TypeExpr ->
         [(TypeExpr, Maybe String)] ->
         FoFCode PureExpr
  def attr name fun returnT argsT = 
      inject (NewDef attr name (Fun fun) returnT argsT return)











  call :: PureExpr -> [PureExpr] -> FoFCode PureExpr
  call funRef params = 
      inject (CallDef Nothing funRef params return)
 
  callN :: String -> PureExpr -> [PureExpr] -> FoFCode PureExpr
  callN varName funRef params = 
      inject (CallDef (Just varName) funRef params return)





  returnc :: PureExpr -> FoFCode PureExpr
  returnc value = inject (Return value)







  compileFunctions (NewDef attr nameF (Fun func) return args r)
                   binding =  
      (FNewDef attr nameF compBody return instanceArgs cont,
       binding2)
        where instanceArgs = instanciateArgs args 
              (compBody, binding1) = compileSemtoFoF' (func instanceArgs) binding 
              ref = CLRef Global (TFun nameF (Fun func) return args) (Provided nameF)
              (cont, binding2) = r ref (binding1 |-> binding)
              instanciateArgs :: [(TypeExpr, Maybe String)] -> [PureExpr]
              instanciateArgs params = reverse $ foldl' instanciateArg [] $ 
                                                 zip [1..] params
                  where instanciateArg l (idx, (typ, mName)) = (CLRef Param typ name) : l
                            where name = case mName of
                                         Just x -> Provided x
                                         Nothing -> makeVarName Param idx

 
  compileFunctions (CallDef mName f@(CLRef _ (TFun nameF 
                                                 func 
                                                 returnT 
                                                 argsT) _)
                                   args r) binding =
      (FStatement (FCallDef name f args) cont,
       binding2)
          where (name, binding1) 
                    = case returnT of
                      TVoid -> (Nothing, binding)
                      _ -> case mName of
                           Just x -> (Just $ Provided x, binding)
                           Nothing -> 
                               (Just $ makeVarName Local loc,
                                binding') 
                               where (loc, binding') = getFreshVar binding 
                (cont, binding2) 
                    = case returnT of 
                      TVoid -> r Void binding1
                      _ -> r (CLRef Local 
                                    returnT 
                                    (fromJust name))
                           binding1 




  compileFunctions (Return e) binding =
      (FClosing $ FReturn e, binding)





  runFunctions (NewDef _ _ f _ _ r) heap = 
      uncurry r $ runNewDef f heap
  runFunctions (CallDef _ a b r) heap = 
      uncurry r $ runCallDef a b heap
  runFunctions (Return a) heap =
      runReturn a heap -- OK??



  runReturn :: PureExpr -> Heap -> (PureExpr, Heap)
  runReturn e heap = (e,heap)
 
  runNewDef :: Function -> Heap -> (PureExpr, Heap)
  runNewDef function heap = 
    (CLRef Global (TFun undefined function undefined undefined) undefined, heap)
 
  runCallDef :: PureExpr -> [PureExpr] -> Heap -> 
                            (PureExpr, Heap)
  runCallDef (CLRef _ (TFun _ (Fun function) _ _) _) args heap =
      let (result, heap1) = run (function args) heap in
      (result, heap1)
