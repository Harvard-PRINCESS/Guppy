{-# LINE 1 "Syntax.lhs" #-}
#line 1 "Syntax.lhs"

  module IL.Paka.Syntax where

  import Text.PrettyPrint.HughesPJ
  import qualified Data.Map as Map

  import PureExpressions

  data PakaCode
      = PakaCode { includes     :: Map.Map String Doc,
                   types        :: Map.Map String Doc,
                   declarations :: [(String, Doc)],
                   prototypes   :: Map.Map String Doc,
                   globalVars   :: [(String, Doc)],
                   functions    :: Map.Map String (Doc, Doc, String, Doc, PakaIntra, ILPaka) }

  emptyCode = PakaCode { includes = Map.empty,
                         types = Map.empty,
                         declarations = [],
                         prototypes = Map.empty,
                         globalVars = [],
                         functions = Map.empty }

  data PakaIntra
      = PakaIntra { localVars :: Map.Map String Doc,
                    expr      :: (Maybe PureExpr)}
        deriving Show

  emptyIntra = PakaIntra { localVars = Map.empty,
                           expr = Nothing }

  data ILPaka
      = PVoid
      | PClosing PakaClosing
      | PStatement PakaStatement ILPaka
      | PIf ILPaka PureExpr ILPaka ILPaka ILPaka
      | PWhile ILPaka PureExpr ILPaka ILPaka
      | PDoWhile ILPaka ILPaka PureExpr ILPaka
      | PSwitch PureExpr [(PureExpr, ILPaka)] ILPaka ILPaka

  data PakaStatement
      = PAssign PakaVarName Term [PakaVarName]
      | PInstruction Term [PakaVarName]


  type Term = [Doc] -> Doc


  data PakaVarName
      = Var String
      | Ptr PakaVarName
      | Deref PakaVarName
      | Complex PakaVarName
      | K PureExpr
        deriving (Show, Eq)


  data PakaClosing
      = PReturn PureExpr
      | PBreak
      | PContinue
        deriving Show
