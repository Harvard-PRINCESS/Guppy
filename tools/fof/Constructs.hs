{-# LINE 1 "Constructs.lhs" #-}
#line 1 "Constructs.lhs"













  module Constructs where

  import PureExpressions
  import Semantics













  data FoFConst a 



      = Assert PureExpr a



      | Printf String [PureExpr] a



      | HasDescendants (Maybe String) PureExpr (PureExpr -> a)



      | MemToPhys (Maybe String) PureExpr (PureExpr -> a)



      | GetAddress (Maybe String) PureExpr (PureExpr -> a)



      | NewUnion (Maybe String) AllocUnion String [(String,TypeExpr)] (String, Data) (Loc -> a)
      | ReadUnion Loc String (Data -> a)
      | WriteUnion Loc String Data a



      | Typedef TypeExpr a
      | TypedefE String TypeExpr a



      | NewStruct (Maybe String) AllocStruct String [(String,(TypeExpr,Data))] (Loc -> a)
      | ReadStruct Loc String (Data -> a)
      | WriteStruct Loc String Data a



      | NewString (Maybe String) String (Loc -> a)



       | NewRef (Maybe String) Data (Loc -> a)
       | ReadRef Loc (Data -> a)
       | WriteRef Loc Data a



       | NewDef [FunAttr] String Function TypeExpr [(TypeExpr, Maybe String)] 
                (PureExpr -> a)
       | CallDef (Maybe String) PureExpr [PureExpr] 
                 (PureExpr -> a)
       | Return PureExpr



       | NewEnum (Maybe String) String Enumeration String (Loc -> a)



       | If (FoFCode PureExpr)
            (FoFCode PureExpr) 
            (FoFCode PureExpr) a
       | For (FoFCode PureExpr)  
             (FoFCode PureExpr) 
             (FoFCode PureExpr) 
             (FoFCode PureExpr) a
       | While (FoFCode PureExpr) 
               (FoFCode PureExpr) a
       | DoWhile (FoFCode PureExpr) 
                 (FoFCode PureExpr) a
       | Switch PureExpr 
                [(PureExpr, FoFCode PureExpr)] 
                (FoFCode PureExpr) a
       | Break
       | Continue 



       | NewArray (Maybe String) AllocArray [Data] (Loc -> a)
       | ReadArray Loc Index (Data -> a)
       | WriteArray Loc Index Data a






  type Data = PureExpr
  type Loc = PureExpr
  type Index = PureExpr






  data FunAttr = Static
               | Inline
               deriving (Eq)

  instance Show FunAttr where
      show Static = "static"
      show Inline = "inline"






  type Enumeration = [(String, Int)]







  instance Functor FoFConst where
      fmap f (Assert a b) = Assert a (f b)
      fmap f (Printf a b c) = Printf a b (f c)
      fmap f (HasDescendants a b c) = HasDescendants a b (f . c)
      fmap f (MemToPhys a b c) = MemToPhys a b (f . c)
      fmap f (GetAddress a b c) = GetAddress a b (f . c)
      fmap f (NewUnion a b c d e g) = NewUnion a b c d e (f . g)
      fmap f (ReadUnion a b c) = ReadUnion a b (f . c)
      fmap f (WriteUnion a b c d) = WriteUnion a b c (f d)
      fmap f (Typedef a c) = Typedef a (f c)
      fmap f (TypedefE a b c) = TypedefE a b (f c)
      fmap f (NewStruct a b c d e) = NewStruct a b c d (f . e)
      fmap f (ReadStruct a b c) = ReadStruct a b (f . c)
      fmap f (WriteStruct a b c d) = WriteStruct a b c (f d)
      fmap f (NewString a b c) = NewString a b (f . c)
      fmap f (NewRef a b c) = NewRef a b (f . c)
      fmap f (ReadRef a b) = ReadRef a (f . b)
      fmap f (WriteRef a b c) = WriteRef a b (f c)
      fmap g (NewDef a b c d e f) = NewDef a b c d e (g . f)
      fmap f (CallDef a b c d) = CallDef a b c (f . d)
      fmap f (Return a) = Return a
      fmap f (NewEnum a b c d e) = NewEnum a b c d (f . e)
      fmap f (If a b c d) = If a b c (f d)
      fmap f (For a b c d e) = For a b c d (f e)
      fmap f (While a b c) = While a b (f c)
      fmap f (DoWhile a b c) = DoWhile a b (f c)
      fmap f (Switch a b c d) = Switch a b c (f d)
      fmap f Break = Break
      fmap f Continue = Continue
      fmap f (NewArray a b c d) = NewArray a b c (f . d)
      fmap f (ReadArray a b c) = ReadArray a b (f . c)
      fmap f (WriteArray a b c d) = WriteArray a b c (f d)






  type FoFCode a = Semantics FoFConst a

