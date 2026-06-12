module PursWasm.Docs.UI.Manifest where

import Prelude

import Data.Array (find)
import Data.Maybe (Maybe)

-- A renderable docs page: its route `path`, full `title` (the H1, used for
-- search/heading), short `nav` label for the sidebar, and inlined `html`.
type Page =
  { path :: String
  , title :: String
  , nav :: String
  , html :: String
  }

-- A site section: a clickable `landing` page (shown at the section root and the
-- sidebar headline) plus its ordered child `pages`.
type Section =
  { id :: String
  , title :: String
  , landing :: Page
  , pages :: Array Page
  }

-- The whole docs tree, generated at build time from manifest.json.
foreign import sections :: Array Section

-- Every page reachable in the app (each section landing + its pages), flattened.
allPages :: Array Page
allPages = sections >>= \s -> [ s.landing ] <> s.pages

-- Resolve a route path (e.g. "/dev" or "/getting-started/overview.md") to its page.
lookupByPath :: String -> Maybe Page
lookupByPath p = find (\pg -> pg.path == p) allPages
