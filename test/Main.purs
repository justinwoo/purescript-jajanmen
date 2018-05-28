module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Console (log)
import Foreign (Foreign)
import Jajanmen as J
import SQLite3 as SL
import Type.Prelude (SProxy(..))

-- -- inferred type:
getEm
  :: forall a b
   . J.AllowedParamType a
  => J.AllowedParamType b
  => SL.DBConnection
  -> { "$name" :: a, "$code" :: b }
  -> Aff Foreign
getEm db = J.queryDB db queryP
  where
    queryP = SProxy :: SProxy "select * from mytable where name = $name and code = $code"

-- -- inferred type:
getSomethin :: SL.DBConnection -> Aff Foreign
getSomethin db = J.queryDB db queryP params
  where
    queryP = SProxy :: SProxy "select * from mytable where name = $name and count = $count"
    params = { "$name": "asdf", "$count": 4 }

main :: Effect Unit
main = do
  log "You should add some tests."
