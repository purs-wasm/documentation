module PursWasm.Docs.UI.Route where

import Prelude hiding ((/))

import Data.Generic.Rep (class Generic)
import Routing.Duplex as RD
import Routing.Duplex (string)
import Routing.Duplex.Generic (noArgs)
import Routing.Duplex.Generic as RDG
import Routing.Duplex.Generic.Syntax ((/), (?))

data Route
  = Home
  | SupportedFeatures
  | RuntimeRepresentation
  | CompilationPipeline
  | Optimizations
  | JsInterop
  | Search { q :: String }

derive instance Eq Route
derive instance Ord Route
derive instance Generic Route _

route :: RD.RouteDuplex' Route
route = RD.root $ RDG.sum
  { "Home": RDG.noArgs
  , "SupportedFeatures": "dev" / "supported-features.md" / noArgs
  , "RuntimeRepresentation": "dev" / "runtime-representation.md" / noArgs
  , "CompilationPipeline": "dev" / "compilation-pipeline.md" / noArgs
  , "Optimizations": "dev" / "optimizations.md" / noArgs
  , "JsInterop": "dev" / "interop.md" / noArgs
  , "Search": "search" ? { q: string }
  }
