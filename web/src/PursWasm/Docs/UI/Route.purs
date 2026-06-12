module PursWasm.Docs.UI.Route where

import Prelude hiding ((/))

import Data.Array (filter)
import Data.Generic.Rep (class Generic)
import Data.Show.Generic (genericShow)
import Data.String (Pattern(..), joinWith, split)
import Routing.Duplex as RD
import Routing.Duplex (rest, string)
import Routing.Duplex.Generic (noArgs)
import Routing.Duplex.Generic as RDG
import Routing.Duplex.Generic.Syntax ((?))

-- Docs pages are data driven (see Manifest), so instead of one constructor per
-- page the router carries the path segments in `Doc`. Home and Search stay
-- typed; `Doc` is the catch-all matched last.
data Route
  = Home
  | Search { q :: String }
  | Doc (Array String)

derive instance Eq Route
derive instance Ord Route
derive instance Generic Route _

instance Show Route where
  show = genericShow

route :: RD.RouteDuplex' Route
route = RD.root $ RDG.sum
  { "Home": RDG.noArgs
  , "Search": "search" ? { q: string }
  , "Doc": rest
  }

-- Build the `Doc` route for a manifest path like "/dev/optimizations.md".
docRoute :: String -> Route
docRoute = Doc <<< filter (_ /= "") <<< split (Pattern "/")

-- The path a `Doc` route points at, e.g. Doc ["dev"] -> "/dev". For non-Doc
-- routes this is "/", which never matches a manifest page.
routePath :: Route -> String
routePath = case _ of
  Doc segs -> "/" <> joinWith "/" segs
  _ -> "/"
