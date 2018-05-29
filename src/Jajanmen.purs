module Jajanmen where

import Effect.Aff (Aff)
import Foreign (Foreign)
import Prim.Row as Row
import Prim.Symbol as Symbol
import SQLite3 as SQLite3
import Type.Prelude (class IsSymbol, SProxy, reflectSymbol)

-- | type safe querying using a query symbol with $name params,
queryDB
  :: forall query params
   . IsSymbol query
  => ExtractLabels query params
  => SQLite3.DBConnection
  -> SProxy query
  -> { | params }
  -> Aff Foreign
queryDB db queryP params =
  SQLite3.queryObjectDB db query params
  where
    query = reflectSymbol queryP

-- e.g. "select * from whatever where a = $a and b = $b" { "$a": 1, "$b": "asdf" }
class ExtractLabels (query :: Symbol) (labels :: # Type) | query -> labels

instance extractLabels ::
  ( Symbol.Cons x xs query
  , ExtractLabelsParse x xs labels
  ) => ExtractLabels query labels

class ExtractLabelsParse (x :: Symbol) (xs :: Symbol) (labels :: # Type) | x xs -> labels

instance endExtractLabelsParse :: ExtractLabelsParse x "" ()

else instance parseParamExtractLabels ::
  ( Symbol.Cons y ys xs
  , ParseParamName y ys "$" out
  , Symbol.Cons z zs ys
  , Row.Cons out ty row' row
  , AllowedParamType ty
  , ExtractLabelsParse z zs row'
  ) => ExtractLabelsParse "$" xs row

else instance nExtractLabels ::
  ( Symbol.Cons y ys xs
  , ExtractLabelsParse y ys row
  ) => ExtractLabelsParse x xs row

class ParseParamName (x :: Symbol) (xs :: Symbol) (acc :: Symbol) (out :: Symbol) | x xs -> acc out

instance endRParseParamName ::
  ( Symbol.Append acc x out
  ) => ParseParamName x "" acc out

else instance endLParseParamName ::
  ParseParamName "" xs out out

else instance spaceParseParamName ::
  ParseParamName " " xs out out

else instance nParseParamName ::
  ( Symbol.Cons y ys xs
  , Symbol.Append acc x acc'
  , ParseParamName y ys acc' out
  ) => ParseParamName x xs acc out

class AllowedParamType ty
instance stringAllowedParamType :: AllowedParamType String
instance intAllowedParamType :: AllowedParamType Int
instance numberAllowedParamType :: AllowedParamType Number
