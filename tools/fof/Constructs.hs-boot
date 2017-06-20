module Constructs where

import Semantics

data FoFConst a
type FoFCode a = Semantics FoFConst a
