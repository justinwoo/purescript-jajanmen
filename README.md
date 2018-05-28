# PureScript-Jajanmen

Cool type-safe Symbol query parameterized helper for [Node-SQLite3](https://github.com/justinwoo/purescript-node-sqlite3). WIP.

![](https://i.imgur.com/bYe4UrU.jpg)

Because jajanmen is delicious, and my other library is called [Chanpon](https://github.com/justinwoo/purescript-chanpon).

## Usage

WIP

```hs
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
```
