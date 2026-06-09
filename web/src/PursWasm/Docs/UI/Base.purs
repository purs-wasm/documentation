-- | Helpers for the deploy base path (GitHub Pages serves this site under
-- | `/documentation/`). `baseUrl` is injected by vite and ends with a slash.
module PursWasm.Docs.UI.Base
  ( baseUrl
  , asset
  , withBase
  , stripBase
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as Str

foreign import baseUrl :: String

-- baseUrl without its trailing slash, e.g. "/documentation" (or "" at root).
baseNoSlash :: String
baseNoSlash = fromMaybe baseUrl (Str.stripSuffix (Str.Pattern "/") baseUrl)

-- | Resolve a public asset path (given without a leading slash) against the
-- | base, e.g. `asset "img/sun.svg"` -> "/documentation/img/sun.svg".
asset :: String -> String
asset path = baseUrl <> path

-- | Prefix an absolute app path with the base, e.g.
-- | `withBase "/dev/foo"` -> "/documentation/dev/foo".
withBase :: String -> String
withBase path = baseNoSlash <> path

-- | Remove the base prefix from a location pathname so routing-duplex (which
-- | works from "/") can parse it. Inverse of `withBase`.
stripBase :: String -> String
stripBase path = case Str.stripPrefix (Str.Pattern baseNoSlash) path of
  Just "" -> "/"
  Just rest -> rest
  Nothing -> path
