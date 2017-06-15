{-# LINE 1 "Builders.lhs" #-}
#line 1 "Builders.lhs"













  module IL.Paka.Builders where

  import Text.PrettyPrint.HughesPJ hiding (first)
  import qualified Data.Map as Map
  import Debug.Trace

  import PureExpressions

  import IL.Paka.Syntax















  type PakaBuilding = (ILPaka -> ILPaka, PakaCode, PakaIntra)










  f # g = \x -> g (f x) 






  first :: (a -> b) -> (a, c, d) -> (b, c, d)
  first f (a,b,c) = (f a, b, c)
 
  second :: (a -> b) -> (c, a, d) -> (c, b, d)
  second f (a,b,c) = (a, f b, c)
 
  third :: (a -> b) -> (c, d, a) -> (c, d, b)
  third f (a,b,c) = (a,b,f c)






  include :: String -> PakaBuilding -> PakaBuilding
  include id = second $ include' id 
      where include' id globalEnv 
                = case id `Map.lookup` incls of
                    Nothing -> globalEnv { includes = Map.insert id decl incls }
                    Just _ -> globalEnv
                where incls = includes globalEnv
                      decl = text "#include" <+> text id 



  declare :: String -> Doc -> Doc -> PakaBuilding -> PakaBuilding
  declare id typ decl = second $ declare' id typ decl
      where declare' id typ decl globalEnv =
                case id `Map.lookup` typs of
                  Nothing -> globalEnv { declarations = (id,decl) : decls,
                                         types = Map.insert id typ typs }
                  Just _ -> globalEnv
                where decls = declarations globalEnv
                      typs = types globalEnv



  globalVar :: String -> Doc -> PakaBuilding -> PakaBuilding
  globalVar id def = second $ globalVar' id def
      where globalVar' id def globalEnv =
                case id `lookup` vars of
                  Nothing -> globalEnv { globalVars = (id,def) : vars  }
                  Just _ -> globalEnv
                where vars = globalVars globalEnv



  prototype :: String -> Doc -> PakaBuilding -> PakaBuilding
  prototype id proto = second $ prototype' id proto
      where prototype' id proto globalEnv =
                case id `Map.lookup` protos of
                  Nothing -> globalEnv { prototypes = Map.insert id proto protos }
                  Just _ -> globalEnv
                where protos = prototypes globalEnv



  function :: Doc -> Doc -> String -> Doc -> PakaIntra -> ILPaka -> PakaBuilding -> PakaBuilding
  function returnT attrs funName funArgs lEnv body = 
      second $ function' returnT attrs funName funArgs lEnv body
      where function' returnT attrs funName funArgs lEnv body gEnv =
                case funName `Map.lookup` functions' of
                  Nothing -> gEnv { functions = Map.insert funName (returnT, attrs, funName, funArgs, lEnv, body) functions' }
                  Just _ -> gEnv
                where functions' = functions gEnv







  localVar :: String -> Doc -> PakaBuilding -> PakaBuilding
  localVar id def = third $ localVar' id def
      where localVar' id def localEnv 
                = case id `Map.lookup` vars of
                    Nothing -> localEnv { localVars = Map.insert id def vars  }
                    Just _ -> localEnv
                where vars = localVars localEnv



  constant :: PureExpr -> PakaBuilding -> PakaBuilding
  constant e = third $ constant' e
      where constant' e lEnv = lEnv { expr = Just e }
















  instr :: Term -> [PakaVarName] -> PakaBuilding -> PakaBuilding
  instr instruction vars = first $ instr' instruction vars
      where instr' instruction varNames k 
                = \c ->
                  k $ PStatement (PInstruction instruction varNames) c
 
  assgn :: PakaVarName -> Term -> [PakaVarName] -> PakaBuilding -> PakaBuilding
  assgn wVarName assgnmt rVarNames = first $ assgn' wVarName assgnmt rVarNames
      where assgn' wVarName assgnmt rVarNames k
                = \c ->
                  k $ PStatement (PAssign wVarName assgnmt rVarNames) c




  close :: PakaClosing -> PakaBuilding -> PakaBuilding
  close c = first $ close' c
      where close' c = \k _ -> k (PClosing c)




  pif :: ILPaka -> PureExpr -> ILPaka -> ILPaka -> PakaBuilding -> PakaBuilding
  pif cond test ifTrue ifFalse = first $ pif' cond test ifTrue ifFalse
      where pif' cond test ifTrue ifFalse cont = \c ->
                cont $ PIf cond test ifTrue ifFalse c
 
  pwhile :: ILPaka -> PureExpr -> ILPaka -> PakaBuilding -> PakaBuilding
  pwhile cond test loop = first $ pwhile' cond test loop
      where pwhile' cond test loop cont = \c ->
                cont $ PWhile cond test loop c
 
  pdoWhile :: ILPaka -> ILPaka -> PureExpr -> PakaBuilding -> PakaBuilding
  pdoWhile loop cond test = first $ pdoWhile' loop cond test
      where pdoWhile' loop cond test cont = \c ->
                cont $ PDoWhile loop cond test c
 
  pswitch :: PureExpr -> [(PureExpr,ILPaka)] -> ILPaka -> PakaBuilding -> PakaBuilding
  pswitch test cases defaultCase = first $ pswitch' test cases defaultCase
      where pswitch' test cases defaultCase cont = \c ->
                cont $ PSwitch test cases defaultCase c

