{-# LINE 1 "PureExpressions.lhs" #-}
#line 1 "PureExpressions.lhs"













  module PureExpressions where

  import Data.Char

  import {-# SOURCE #-} Constructs




































  data TypeExpr = TVoid
                | TInt Signedness Size
                | TFloat
                | TChar
                | TStruct AllocStruct String TFieldList
                | TUnion AllocUnion String TFieldList
                | TCompPointer String 
                | TEnum String [(String, Int)]
                | TArray AllocArray TypeExpr
                | TPointer TypeExpr Mode
                | TTypedef TypeExpr String
                | TFun String Function TypeExpr [(TypeExpr, Maybe String)]
                  deriving (Eq, Show)










  data Function = Fun ([PureExpr] -> FoFCode PureExpr)





  instance Show Function where
      show _ = "<fun>"







  instance Eq Function where
      _ == _ = False













  data AllocStruct = StaticStruct
                   | DynamicStruct
                     deriving (Eq, Show)
  data AllocUnion = StaticUnion
                  | DynamicUnion
                     deriving (Eq, Show)
  data AllocArray = StaticArray Int
                  | DynamicArray
                     deriving (Eq, Show)





  type TFieldList = [(String, TypeExpr)]














  data Signedness = Unsigned 
                  | Signed
                    deriving (Eq, Ord, Show)
 
  data Size = TInt8
            | TInt16
            | TInt32
            | TInt64
              deriving (Eq, Ord, Show)    


















  data Mode = Avail
            | Read
              deriving (Eq, Show)










  voidT :: TypeExpr
  voidT = TVoid
 
  uint8T, uint16T, uint32T, uint64T :: TypeExpr 
  uint8T = TInt Unsigned TInt8
  uint16T = TInt Unsigned TInt16
  uint32T = TInt Unsigned TInt32
  uint64T = TInt Unsigned TInt64
 
  int8T, int16T, int32T, int64T :: TypeExpr
  int8T = TInt Signed TInt8
  int16T = TInt Signed TInt16
  int32T = TInt Signed TInt32
  int64T = TInt Signed TInt64
 
  floatT :: TypeExpr
  floatT = TFloat
 
  charT :: TypeExpr
  charT = TChar

  uintptrT :: TypeExpr
  uintptrT = TCompPointer "void"





  arrayDT :: TypeExpr -> TypeExpr
  arrayDT typ = TArray DynamicArray typ 
 
  arrayST :: Int -> TypeExpr -> TypeExpr
  arrayST size typ = TArray (StaticArray size) typ 
 
  ptrT :: TypeExpr -> TypeExpr
  ptrT typ = TPointer typ Avail
 
  structDT, unionDT,
   structST, unionST :: String -> TFieldList -> TypeExpr
  structDT name fields = TStruct DynamicStruct name fields
  unionDT name fields = TUnion DynamicUnion name fields
  structST name fields = TStruct StaticStruct name fields
  unionST name fields = TUnion StaticUnion name fields
 
  enumT :: String -> [(String, Int)] -> TypeExpr
  enumT name fields = TEnum name fields
 
  typedef :: TypeExpr -> String -> TypeExpr
  typedef typ name = TTypedef typ name




  cptrT :: String -> TypeExpr
  cptrT id = TCompPointer id






























  data PureExpr = Void
                | CLInteger Signedness Size Integer
                | CLFloat Float
                | CLChar Char
                | CLRef Origin TypeExpr VarName
                | Unary UnaryOp PureExpr
                | Binary BinaryOp PureExpr PureExpr
                | Sizeof TypeExpr
                | Test PureExpr PureExpr PureExpr
                | Cast TypeExpr PureExpr
                | Quote String
                  deriving (Eq, Show)












  data VarName = Generated String
               | Provided String
               | Inherited Int VarName
                 deriving (Show, Eq)










  data Origin = Local
              | Global
              | Param
              | Dynamic
                deriving (Eq, Show)









  data UnaryOp = Minus | Complement | Negation
               deriving (Eq, Show)










  data BinaryOp = Plus | Sub | Mul    | Div   | Mod
                | Shl  | Shr | AndBit | OrBit | XorBit 
                | Le   | Leq | Ge     | Geq   | Eq  | Neq
                  deriving (Eq, Show)









  void :: PureExpr
  void = Void
 
  int8, int16, int32, int64 :: Integer -> PureExpr
  int8 x = CLInteger Signed TInt8 x
  int16 x = CLInteger Signed TInt16 x
  int32 x = CLInteger Signed TInt32 x
  int64 x = CLInteger Signed TInt64 x
 
  uint8, uint16, uint32, uint64 :: Integer -> PureExpr
  uint8 x = CLInteger Unsigned TInt8 x
  uint16 x = CLInteger Unsigned TInt16 x
  uint32 x = CLInteger Unsigned TInt32 x
  uint64 x = CLInteger Unsigned TInt64 x
 
  charc :: Char -> PureExpr
  charc x = CLInteger Unsigned TInt8 (toInteger $ ord x)
 
  float :: Float -> PureExpr
  float x = CLFloat x
 
  cchar :: Char -> PureExpr
  cchar x = CLChar x

  opaque :: TypeExpr -> String -> PureExpr
  opaque t s = CLRef Local t (Provided s)



  minus, comp, neg :: PureExpr -> PureExpr
  minus = Unary Minus 
  comp = Unary Complement
  neg = Unary Negation 





  exampleInfix :: PureExpr
  exampleInfix = (uint8 1) .<. ((uint8 2) .+. (uint8 4))





  (.+.), (.-.), (.*.), (./.), (.%.),
           (.<<.), (.>>.), (.&.), (.|.), (.^.),
           (.<.), (.<=.), (.>.), 
           (.>=.), (.==.), (.!=.) :: PureExpr -> PureExpr -> PureExpr
  (.+.) = Binary Plus
  (.-.) = Binary Sub
  (.*.) = Binary Mul
  (./.) = Binary Div
  (.%.) = Binary Mod
  (.<<.) = Binary Shl
  (.>>.) = Binary Shr
  (.&.) = Binary AndBit
  (.|.) = Binary OrBit
  (.^.) = Binary XorBit
  (.<.) = Binary Le
  (.<=.) = Binary Leq
  (.>.) = Binary Ge
  (.>=.) = Binary Geq
  (.==.) = Binary Eq
  (.!=.) = Binary Neq




  sizeof :: TypeExpr -> PureExpr
  sizeof t = Sizeof t
 
  test :: PureExpr -> PureExpr -> PureExpr -> PureExpr
  test c ift iff = Test c ift iff
 
  cast :: TypeExpr -> PureExpr -> PureExpr
  cast t e = Cast t e









  quote :: String -> PureExpr
  quote s = Quote s
