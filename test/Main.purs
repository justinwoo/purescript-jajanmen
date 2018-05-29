module Test.Main where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, throwError)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Exception (error)
import Foreign (Foreign)
import Jajanmen as J
import SQLite3 as SL
import Simple.JSON as JSON
import Test.Assert as Assert
import Type.Prelude (SProxy(..))

-- -- inferred type:
getEm
  :: forall a b
   . J.AllowedParamType a
  => J.AllowedParamType b
  => SL.DBConnection
  -> { "$name" :: a, "$count" :: b }
  -> Aff Foreign
getEm db = J.queryDB db queryP
  where
    queryP = SProxy :: SProxy "select name, count from mytable where name = $name and count = $count"

-- -- inferred type:
getSomethin :: SL.DBConnection -> Aff Foreign
getSomethin db = J.queryDB db queryP params
  where
    queryP = SProxy :: SProxy "select name, count from mytable where name = $name and count = $count"
    params = { "$name": "asdf", "$count": 4 }

addSomethin :: SL.DBConnection -> { "$name" :: String, "$count" :: Int } -> Aff Foreign
addSomethin db params = J.queryDB db queryP params
  where
    queryP = SProxy :: SProxy "insert or replace into mytable (name, count) values ($name, $count)"

type MyRow = { name :: String, count :: Int }

main :: Effect Unit
main = launchAff_ do
  db <- SL.newDB "./test/testdb.sqlite"
  _ <- SL.queryDB db "create table if not exists mytable (name text, count int)" []
  _ <- SL.queryDB db "delete from mytable" []
  _ <- addSomethin db { "$name": "apples", "$count": 3 }
  _ <- addSomethin db { "$name": "asdf", "$count": 4 }

  f1 <- getEm db { "$name": "apples", "$count": 3 }
  testResult f1 [{ name: "apples", count: 3 }]

  f2 <- getSomethin db
  testResult f2 [{ name: "asdf", count: 4 }]

  log "tests passed"
  where
    testResult f expected =
      case JSON.read f of
        Left e -> throwError (error $ show e)
        Right (actual :: Array MyRow) -> assertEqual { actual, expected }
    assertEqual = liftEffect <<< Assert.assertEqual
