{-# LINE 1 "Compile.lhs" #-}
#line 1 "Compile.lhs"













  module IL.FoF.Compile where

  import Semantics
  import PureExpressions
  import {-# SOURCE #-} Expressions
  import Constructs

  import IL.FoF.FoF















  compileSemtoFoF' :: FoFCode PureExpr -> Binding -> (ILFoF, Binding)
  compileSemtoFoF' = foldSemantics compilePure compileAlgebra







  compilePure :: PureExpr -> Binding -> (ILFoF, Binding)
  compilePure x binding = (FConstant x, binding)





  compileSemtoFoF :: FoFCode PureExpr -> ILFoF
  compileSemtoFoF term = fst $ compileSemtoFoF' term emptyBinding
      where emptyBinding = Binding { freshVar = 1,
                                     defStructs = [],
                                     defUnions = [],
                                     defEnums = [] }










  getFreshVar :: Binding -> (Int, Binding)
  getFreshVar binding = (loc, binding1)
      where loc = freshVar binding
            binding1 = binding { freshVar = loc + 1 }



  better_getFreshVar :: Binding -> (Int -> Binding -> t) -> t
  better_getFreshVar binding f = undefined












  passFreshVar :: Binding -> Binding -> Binding
  passFreshVar upBinding stableBinding =
      stableBinding { freshVar = freshVar upBinding,
                      defStructs = defStructs upBinding,
                      defUnions = defUnions upBinding,
                      defEnums = defEnums upBinding }
  (|->) = passFreshVar






  makeVarName :: Origin -> Int -> VarName
  makeVarName orig loc = Generated $ makeVarName' orig loc
      where makeVarName' Local x = "fof_x" ++ show x
            makeVarName' Param x = "fof_y" ++ show x
            makeVarName' Dynamic x = "fof_d" ++ show x
            makeVarName' Global x = "fof_g" ++ show x





  heritVarName :: Binding -> VarName -> (Int, VarName, Binding)
  heritVarName binding name = (loc, Inherited loc name, binding1)
      where (loc, binding1) = getFreshVar binding 
      





























  typeOf :: PureExpr -> TypeExpr
  typeOf (Void) = TVoid
  typeOf (CLInteger sign size _) = TInt sign size
  typeOf (CLFloat _) = TFloat
  typeOf (CLRef _ typ _) = typ
  typeOf (Unary _ x) = typeOf x





  typeOf (Binary _ x y) = 
      if (typeOfx == typeOfy) then
         typeOfx
      else error "typeOf: Binop on distinct types."
 
      where typeOfx = typeOf x
            typeOfy = typeOf y
 
  typeOf (Test _ t1 t2) =
      if (typeOft1 == typeOft2) then
         typeOft1
      else error "typeOf: Test exits on distinct types"
      
      where typeOft1 = typeOf t1 
            typeOft2 = typeOf t2 






  typeOf (Sizeof _) = TInt Unsigned TInt64





  typeOf (Cast t _) = t















  readOf :: TypeExpr -> TypeExpr
  readOf (TPointer typ _) = TPointer typ Read
  readOf x = x
 
  unfoldPtrType :: PureExpr -> TypeExpr
  unfoldPtrType (CLRef _ (TPointer typ _) _) = readOf typ











  liftType :: TypeExpr -> TypeExpr
  liftType (TPointer x _) = x
  liftType x = x

















  deref :: PureExpr -> String
  deref (CLRef _ (TPointer _ _) _) = "&"
  deref _ = ""

