{-# LINE 1 "Expressions.lhs" #-}
#line 1 "Expressions.lhs"

  module Expressions where

  import Semantics
  import Constructs
  import PureExpressions

  import IL.FoF.FoF

  import Constructs.Arrays(compileArrays, runArrays)
  import Constructs.Conditionals(compileConditionals, runConditionals)
  import Constructs.Enumerations(compileEnumerations, runEnumerations)
  import Constructs.Functions(compileFunctions, runFunctions)
  import Constructs.References(compileReferences, runReferences)
  import Constructs.Strings(compileString, runString)
  import Constructs.Typedef(compileTypedef, runTypedef)
  import Constructs.Structures(compileStructures, runStructures)
  import Constructs.Unions(compileUnions, runUnions)

  import Libc.Assert(compileAssert, runAssert)
  import Libc.Printf(compilePrintf, runPrintf)

  import Libbarrelfish.HasDescendants(compileHasDescendants, runHasDescendants)
  import Libbarrelfish.MemToPhys(compileMemToPhys, runMemToPhys)
  import Libbarrelfish.GetAddress(compileGetAddress, runGetAddress)



































  data Heap = Hp { freshLoc :: Int ,
                   refMap :: [(VarName, Data)],
                   freshSLoc :: Int,
                   strMap :: [(VarName, [(String, Data)])],
                   freshALoc :: Int,
                   arrayMap :: [(VarName, [Data])]}






  runAlgebra :: FoFConst (Heap -> (PureExpr, Heap)) -> Heap -> (PureExpr, Heap)
  runAlgebra x@(NewArray _ _ _ _) = runArrays x
  runAlgebra x@(ReadArray _ _ _) = runArrays x
  runAlgebra x@(WriteArray _ _ _ _) = runArrays x
  runAlgebra x@(If _ _ _ _) = runConditionals x
  runAlgebra x@(For _ _ _ _ _) = runConditionals x
  runAlgebra x@(While _ _ _) = runConditionals x
  runAlgebra x@(DoWhile _ _ _) = runConditionals x
  runAlgebra x@(Switch _ _ _ _) = runConditionals x
  runAlgebra x@Break = runConditionals x
  runAlgebra x@Continue = runConditionals x
  runAlgebra x@(NewEnum _ _ _ _ _) = runEnumerations x
  runAlgebra x@(NewDef _ _ _ _ _ _) = runFunctions x
  runAlgebra x@(CallDef _ _ _ _) = runFunctions x
  runAlgebra x@(Return _) = runFunctions x
  runAlgebra x@(NewRef _ _ _) = runReferences x
  runAlgebra x@(ReadRef _ _) = runReferences x
  runAlgebra x@(WriteRef _ _ _) = runReferences x
  runAlgebra x@(NewString _ _ _) = runString x
  runAlgebra x@(Typedef _ _) = runTypedef x
  runAlgebra x@(TypedefE _ _ _) = runTypedef x
  runAlgebra x@(NewStruct _ _ _ _ _) = runStructures x
  runAlgebra x@(ReadStruct _ _ _) = runStructures x
  runAlgebra x@(WriteStruct _ _ _ _) = runStructures x
  runAlgebra x@(NewUnion _ _ _ _ _ _) = runUnions x
  runAlgebra x@(ReadUnion _ _ _) = runUnions x
  runAlgebra x@(WriteUnion _ _ _ _) = runUnions x
  runAlgebra x@(Assert _ _) = runAssert x
  runAlgebra x@(Printf _ _ _) = runPrintf x
  runAlgebra x@(HasDescendants _ _ _) = runHasDescendants x
  runAlgebra x@(MemToPhys _ _ _) = runMemToPhys x
  runAlgebra x@(GetAddress _ _ _) = runGetAddress x













  data Binding = Binding { freshVar :: Int ,
                           defStructs :: [(String,TypeExpr)],
                           defUnions :: [(String,TypeExpr)],
                           defEnums :: [(String, [(String, Int)])] }





  compileAlgebra :: FoFConst (Binding -> (ILFoF, Binding)) ->
                    (Binding -> (ILFoF, Binding))
  compileAlgebra x@(NewArray _ _ _ _) = compileArrays x
  compileAlgebra x@(ReadArray _ _ _) = compileArrays x
  compileAlgebra x@(WriteArray _ _ _ _) = compileArrays x
  compileAlgebra x@(If _ _ _ _) = compileConditionals x
  compileAlgebra x@(For _ _ _ _ _) = compileConditionals x
  compileAlgebra x@(While _ _ _) = compileConditionals x
  compileAlgebra x@(DoWhile _ _ _) = compileConditionals x
  compileAlgebra x@(Switch _ _ _ _) = compileConditionals x
  compileAlgebra x@Break = compileConditionals x
  compileAlgebra x@Continue = compileConditionals x
  compileAlgebra x@(NewDef _ _ _ _ _ _) = compileFunctions x
  compileAlgebra x@(CallDef _ _ _ _) = compileFunctions x
  compileAlgebra x@(Return _) = compileFunctions x
  compileAlgebra x@(NewEnum _ _ _ _ _) = compileEnumerations x
  compileAlgebra x@(NewRef _ _ _) = compileReferences x
  compileAlgebra x@(ReadRef _ _) = compileReferences x
  compileAlgebra x@(WriteRef _ _ _) = compileReferences x
  compileAlgebra x@(NewString _ _ _) = compileString x
  compileAlgebra x@(Typedef _ _) = compileTypedef x
  compileAlgebra x@(TypedefE _ _ _) = compileTypedef x
  compileAlgebra x@(NewStruct _ _ _ _ _) = compileStructures x
  compileAlgebra x@(ReadStruct _ _ _) = compileStructures x
  compileAlgebra x@(WriteStruct _ _ _ _) = compileStructures x
  compileAlgebra x@(NewUnion _ _ _ _ _ _) = compileUnions x
  compileAlgebra x@(ReadUnion _ _ _) = compileUnions x
  compileAlgebra x@(WriteUnion _ _ _ _) = compileUnions x
  compileAlgebra x@(Assert _ _) = compileAssert x
  compileAlgebra x@(Printf _ _ _) = compilePrintf x
  compileAlgebra x@(HasDescendants _ _ _) = compileHasDescendants x
  compileAlgebra x@(MemToPhys _ _ _) = compileMemToPhys x
  compileAlgebra x@(GetAddress _ _ _) = compileGetAddress x
