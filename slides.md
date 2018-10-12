% Superior string spaghetti with PureScript
% Justin Woo
% October 12 2018

## Problem: Untyped Parameterized SQL Queries

We want to work with parameterized SQL queries, but they’re always untyped

```hs
thing =
  queryDB """
    select name, count from mytable
    where name = $name and count = $count
  """
    { "$name": "Bill"
    , "$count": 10
    }
```

But we know statically what the query string is here!

What if we could use it at the type level and extract a type from it?

## What if you could Cons Symbol like Lists?

In PureScript 0.12, we can!

"ABC" -> "A" "BC"

```hs
class Cons (head :: Symbol) (tail :: Symbol) (symbol :: Symbol)
  | head tail -> symbol, symbol -> head tail
```

Now we can parse Symbols!

```hs
class ParseParamName (x :: Symbol) (xs :: Symbol)
                     (acc :: Symbol) (out :: Symbol)
  | x xs -> acc out
```

## The problem with normal instance matching

When parsing, we need to work with both the head and the tail

E.g. when parsing a param name until a space or end of the string

```hs
class ParseParamName (x :: Symbol) (xs :: Symbol)
                     (acc :: Symbol) (out :: Symbol) | -- ...

-- invalid overloading instances!
instance endRParseParamName :: ( Symbol.Append acc x out ) =>
                                ParseParamName x "" acc out

instance spaceParseParamName :: ParseParamName " " xs out out
```

## Instance chains at work

In PureScript 0.12, we have instance chains (groups)

First come, first served, with regular fundep-based instance matching (not constraints/guards)

```hs
instance endRParseParamName ::
 ( Symbol.Append acc x out
 ) => ParseParamName x "" acc out

-- note the else here:
else instance spaceParseParamName ::
 ParseParamName " " xs out out
```

Instance chain (groups) can only be implemented within a module, which is fine

## How do these solve our problem?

Now we can write a parser at the type level, and we can synthesize row types as usual:

```hs
getEm :: forall a b
   . AllowedParamType a => AllowedParamType b
  => DBConnection
  -> { "$name" :: a
     , "$count" :: b
     }
  -> Aff Foreign
getEm db = J.queryDB db $ SProxy :: SProxy """
    select name, count from mytable
    where name = $name and count = $count
  """
```

## Top level function

```hs
queryDB :: forall query params
   . IsSymbol query => ExtractParams query params
  => SQLite3.DBConnection
  -> SProxy query
  -> { | params }
  -> Aff Foreign
```

```hs
class ExtractParams (query :: Symbol) (params :: # Type)
  | query -> params
```

```hs
instance extractParams ::
 ( Symbol.Cons x xs query
 , ExtractParamsParse x xs params
 ) => ExtractParams query params
```

## Parsing and Extracting Params

```hs
class ExtractParamsParse
  (x :: Symbol) -- current character
  (xs :: Symbol) -- tail
  (params :: # Type) -- row type of parsed parameters
  | x xs -> params -- fundeps, params are determined
```

```hs
-- base case, no more to extract at end of string:
instance endExtractParamsParse :: ExtractParamsParse x "" ()
```

-----

On “$”, parse out the parameter name and add it to our record

```hs
else instance paramExtractParams ::
 ( Symbol.Cons y ys xs
 , ParseParamName y ys "$" out
 , Symbol.Cons z zs ys
 , Row.Cons out ty row' row
 , AllowedParamType ty
 , ExtractParamsParse z zs row'
 ) => ExtractParamsParse "$" xs row
```

Otherwise, continue

```hs
else instance nExtractParams ::
 ( Symbol.Cons y ys xs
 , ExtractParamsParse y ys row
 ) => ExtractParamsParse x xs row
```

## Row.Cons?

Remember that record types are parameterized by row type in PureScript

```hs
data Record :: # Type -> Type

type MyRecord = { a :: Int, b :: String }
       ~ Record ( a :: Int, b :: String )
```

So it makes sense we can use RowCons to add to it

```hs
class Cons (label :: Symbol) (a :: Type)
           (tail :: # Type) (row :: # Type)
 | label a tail -> row, label row -> a tail
```

-----

![](./rowcons.png)

## Back to the top

Hopefully now this all makes sense:

```hs
queryDB :: forall query params
   . IsSymbol query => ExtractParams query params
  => SQLite3.DBConnection
  -> SProxy query
  -> { | params }
  -> Aff Foreign
```

-----

```hs
getEm :: forall a b
   . AllowedParamType a => AllowedParamType b
  => DBConnection
  -> { "$name" :: a, "$count" :: b }
  -> Aff Foreign
getEm db = J.queryDB db $ SProxy :: SProxy """
    select name, count from mytable
    where name = $name and count = $count
  """
```

## Available as a library

<https://github.com/justinwoo/purescript-jajanmen>

![](./jajanmen.png)

## Conclusion

With PureScript 0.12, we can...

* Extract a lot of information from Symbols
* Use instance chains to safely use overlapping instances
* Use existing techniques from 0.11.x to synthesize types using the extracted information from Symbols

## Thanks

* More detailed post here <https://github.com/justinwoo/my-blog-posts#well-typed-parameterized-sqlite-parameters-with-purescript>
* Csongor Kiss’s post on Symbol.Cons and his printf library: <http://kcsongor.github.io/purescript-safe-printf/>
* Twitter: @jusrin00

-----

![Your face on PureScript](./promotion.png)
