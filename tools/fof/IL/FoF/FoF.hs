{-# LINE 1 "FoF.lhs" #-}
#line 1 "FoF.lhs"


  module IL.FoF.FoF where

  import Constructs
  import PureExpressions


  data ILFoF
      = FConstant PureExpr
      | FStatement FStatement ILFoF
      | FClosing FClosing
      | FNewDef [FunAttr] String ILFoF TypeExpr [PureExpr] ILFoF
      | FIf ILFoF ILFoF ILFoF ILFoF
      | FFor ILFoF ILFoF ILFoF ILFoF ILFoF
      | FWhile ILFoF ILFoF ILFoF
      | FDoWhile ILFoF ILFoF ILFoF
      | FSwitch PureExpr [(PureExpr, ILFoF)] ILFoF ILFoF




  data FStatement
      = FNewUnion VarName AllocUnion String [(String,TypeExpr)] (String, Data)
      | FReadUnion VarName Loc String
      | FWriteUnion Loc String Data
      | FTypedef TypeExpr String
      | FTypedefE String TypeExpr
      | FNewStruct VarName AllocStruct String [(String,(TypeExpr,Data))]
      | FReadStruct VarName Loc String
      | FWriteStruct Loc String Data
      | FNewString VarName String
      | FNewRef  VarName Data
      | FReadRef VarName Loc
      | FWriteRef Loc Data
      | FNewEnum VarName String Enumeration String
      | FNewArray VarName AllocArray [Data]
      | FReadArray VarName Loc Index
      | FWriteArray Loc Index Data
      | FCallDef (Maybe VarName) PureExpr [PureExpr]
      | FFFICall String [PureExpr]



  data FClosing
      = FReturn PureExpr
      | FBreak
      | FContinue


