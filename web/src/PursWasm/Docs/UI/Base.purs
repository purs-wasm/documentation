-- | Helpers for the deploy base path (GitHub Pages serves this site under
-- | `/documentation/`). `baseUrl` is injected by vite and ends with a slash.
-- | The `*With` variants take the base explicitly and are pure (unit-testable);
-- | the unqualified ones are those applied to the injected `baseUrl`.
module PursWasm.Docs.UI.Base
  ( baseUrl
  , asset
  , withBase
  , stripBase
  , assetWith
  , withBaseWith
  , stripBaseWith
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as Str

foreign import baseUrl :: String

-- A base without its trailing slash, e.g. "/documentation" (or "" at root).
baseNoSlash :: String -> String
baseNoSlash b = fromMaybe b (Str.stripSuffix (Str.Pattern "/") b)

-- | Resolve a public asset path (given without a leading slash) against a base,
-- | e.g. `assetWith "/documentation/" "img/sun.svg"` -> "/documentation/img/sun.svg".
assetWith :: String -> String -> String
assetWith b path = b <> path

-- | Prefix an absolute app path with a base, e.g.
-- | `withBaseWith "/documentation/" "/dev/foo"` -> "/documentation/dev/foo".
withBaseWith :: String -> String -> String
withBaseWith b path = baseNoSlash b <> path

-- | Remove the base prefix from a location pathname so routing-duplex (which
-- | works from "/") can parse it. Inverse of `withBaseWith`.
stripBaseWith :: String -> String -> String
stripBaseWith b path = case Str.stripPrefix (Str.Pattern (baseNoSlash b)) path of
  Just "" -> "/"
  Just rest -> rest
  Nothing -> path

asset :: String -> String
asset = assetWith baseUrl

withBase :: String -> String
withBase = withBaseWith baseUrl

stripBase :: String -> String
stripBase = stripBaseWith baseUrl
