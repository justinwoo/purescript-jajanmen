module Jajanmen where

import Prelude

import Effect.Aff (Aff)
import Foreign (Foreign)
import Prim.Row as Row
import Prim.RowList as RL
import Prim.Symbol as Symbol
import SQLite3 as SQLite3
import Type.Prelude (class IsSymbol, SProxy, reflectSymbol)

-- | type safe querying using a query symbol with $name params,
-- | where corresponding $name labels are required in the params
queryDB
  :: forall query params labels labelsL
   . IsSymbol query
  => ExtractLabels query labels
  => RL.RowToList labels labelsL
  => ValidateParams labelsL params
  => SQLite3.DBConnection
  -> SProxy query
  -> { | params }
  -> Aff Foreign
queryDB db queryP params =
  SQLite3.queryObjectDB db query params
  where
    query = reflectSymbol queryP

-- e.g. "select * from whatever where a = ?1 and b = ?10"
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
  , Row.Cons out Void row' row
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

class ValidateParams (paramsL :: RL.RowList) (labels :: # Type) | paramsL -> labels

instance nilValidateParams :: ValidateParams RL.Nil ()

instance consValidateParams ::
  ( ValidateParams paramsL row'
  , Row.Cons name ty row' row
  , AllowedParamType ty
  ) => ValidateParams (RL.Cons name Void paramsL) row

class AllowedParamType ty
instance stringAllowedParamType :: AllowedParamType String
instance intAllowedParamType :: AllowedParamType Int
instance numberAllowedParamType :: AllowedParamType Number
