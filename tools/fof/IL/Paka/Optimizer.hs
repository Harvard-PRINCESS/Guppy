{-# LINE 1 "Optimizer.lhs" #-}
#line 1 "Optimizer.lhs"













  module IL.Paka.Optimizer where

  import Data.List
  import qualified Data.Map as Map

  import IL.Paka.Syntax
  import IL.Paka.Compile



























  optimizePaka :: PakaCode -> PakaCode
  optimizePaka = optimizeAssgmtElim




  optimizeAssgmtElim :: PakaCode -> PakaCode
  optimizeAssgmtElim code = code { functions = optFunc }
      where funcs = functions code
            optFunc = Map.mapMaybe (\(b,c,d,e,f,fun) -> Just (b,c,d,e,f, assgmtElim fun)) funcs















  assgmtElim :: ILPaka -> ILPaka













  assgmtElim (PStatement a@(PAssign (Var x) _ [Var y]) k) =
      if (not (isUsed flatten y k))
         && (not (isUsed flattenS x k)) then
          assgmtElim $ replace (Var x) (Var y) k
      else
          PStatement a $
          assgmtElim k




  assgmtElim (PStatement a k) =
      PStatement a $
      assgmtElim k



  assgmtElim (PIf c t ifT ifF k) =
      PIf 
      (assgmtElim c)
      t 
      (assgmtElim ifT)
      (assgmtElim ifF)
      (assgmtElim k)
  assgmtElim (PWhile c t l k) =
      PWhile
      (assgmtElim c)
      t
      (assgmtElim l)
      (assgmtElim k)
  assgmtElim (PDoWhile l c t k) =
      PDoWhile 
      (assgmtElim l)
      (assgmtElim c)
      t 
      (assgmtElim k)
  assgmtElim (PSwitch t cases d k) =
      PSwitch
      t
      (map (\(a,b) -> (a, assgmtElim b)) cases)
      (assgmtElim d)
      (assgmtElim k)
  assgmtElim x = x
















  isUsed :: (PakaVarName -> Maybe String) -> String -> ILPaka -> Bool
  isUsed p var PVoid = False
  isUsed p var (PClosing (PReturn k)) = Just var == (flatten $ pakaValName k)
  isUsed p var (PClosing _) = False
  isUsed p var (PStatement s k) = isUsedStmt s || isUsed p var k
                                where isUsedStmt (PAssign t _ ls) =
                                          Just var `elem` map flatten (t : ls)
                                      isUsedStmt (PInstruction _ ls) =
                                          Just var `elem` map flatten ls
  isUsed p var (PIf c t ifT ifF k) 
      = (Just var == (flatten $ pakaValName t)) ||
        (isUsed p var c || isUsed p var ifT 
        || isUsed p var ifF || isUsed p var k)
  isUsed p var (PWhile c t l k) 
      = (Just var == (flatten $ pakaValName t)) ||
        isUsed p var c || isUsed p var l || isUsed p var k
  isUsed p var (PDoWhile l c t k)
      = (Just var == (flatten $ pakaValName t)) ||
        isUsed p var c || isUsed p var l || isUsed p var k
  isUsed p var (PSwitch t c d k) 
      = (Just var == (flatten $ pakaValName t)) ||
        foldl' (\a (_,b) -> a || isUsed p var b) False c 
        || isUsed p var d || isUsed p var k




  flatten :: PakaVarName -> Maybe String
  flatten (Var s) = Just $ s
  flatten (Ptr x) = flatten x
  flatten (Deref x) = flatten x
  flatten (Complex x) = flatten x
  flatten (K _) = Nothing 
 
  flattenS :: PakaVarName -> Maybe String
  flattenS (Var s) = Nothing
  flattenS (Ptr x) = Nothing
  flattenS (Deref x) = Nothing
  flattenS (Complex x) = flatten x
  flattenS (K _) = Nothing







  replace :: PakaVarName -> PakaVarName -> ILPaka -> ILPaka
  replace dest source (PStatement (PAssign dst stmt srcs) k) = 
      PStatement (PAssign dst stmt srcs') 
      (replace dest source k)
      where srcs' = replaceL dest source srcs
  replace dest source (PStatement (PInstruction stmt srcs) k) =
      PStatement (PInstruction stmt srcs') 
      (replace dest source k)
      where srcs' = replaceL dest source srcs
  replace dest source (PIf c t ifT ifF k) =
      PIf (replace dest source c) t
          (replace dest source ifT) 
          (replace dest source ifF)
          (replace dest source k)
  replace dest source (PWhile c t l k) =
      PWhile (replace dest source c)
             t
             (replace dest source l)
             (replace dest source k)
  replace dest source (PDoWhile l c t k) =
      PDoWhile (replace dest source l)
               (replace dest source c)
               t
               (replace dest source k)
  replace dest source (PSwitch t cases d k) =
      PSwitch t
              (map (\(a,b) -> (a, replace dest source b)) cases)
              (replace dest source d)
              (replace dest source k)
  replace dest source x = x
 
  replaceL x y = map (\z -> if z == x then y else z)
