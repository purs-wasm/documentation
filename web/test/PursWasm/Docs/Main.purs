module Test.PursWasm.Docs.Main where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (for_)
import Effect (Effect)
import PursWasm.Docs.UI.Base (assetWith, stripBaseWith, withBaseWith)
import PursWasm.Docs.UI.Route (Route(..), route)
import Routing.Duplex as RD
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess)

-- Every route value the app can navigate to. `Search` carries a query.
allRoutes :: Array Route
allRoutes =
  [ Home
  , GettingStarted
  , DevelopersGuide
  , SupportedFeatures
  , RuntimeRepresentation
  , CompilationPipeline
  , Optimizations
  , JsInterop
  , Search { q: "effect monad" }
  ]

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] do
  describe "Route" do
    it "round-trips every route through print/parse" do
      for_ allRoutes \r ->
        RD.parse route (RD.print route r) `shouldEqual` Right r

    it "prints the expected paths" do
      RD.print route Home `shouldEqual` "/"
      RD.print route GettingStarted `shouldEqual` "/getting-started"
      RD.print route DevelopersGuide `shouldEqual` "/dev"
      RD.print route Optimizations `shouldEqual` "/dev/optimizations.md"
      RD.print route (Search { q: "x y" }) `shouldEqual` "/search?q=x%20y"

    it "does not confuse the guide entry with a guide page" do
      RD.parse route "/dev" `shouldEqual` Right DevelopersGuide
      RD.parse route "/dev/optimizations.md" `shouldEqual` Right Optimizations

  describe "Base path" do
    it "round-trips withBase / stripBase under a sub-path deploy" do
      let b = "/documentation/"
      for_ [ "/", "/getting-started", "/dev", "/dev/optimizations.md" ] \p ->
        stripBaseWith b (withBaseWith b p) `shouldEqual` p

    it "prefixes app paths and assets under a sub-path" do
      withBaseWith "/documentation/" "/dev/foo" `shouldEqual` "/documentation/dev/foo"
      withBaseWith "/documentation/" "/" `shouldEqual` "/documentation/"
      assetWith "/documentation/" "img/x.svg" `shouldEqual` "/documentation/img/x.svg"

    it "strips the base from a location pathname" do
      stripBaseWith "/documentation/" "/documentation/dev/foo" `shouldEqual` "/dev/foo"
      stripBaseWith "/documentation/" "/documentation/" `shouldEqual` "/"

    it "is a no-op at the root base" do
      withBaseWith "/" "/dev/foo" `shouldEqual` "/dev/foo"
      stripBaseWith "/" "/dev/foo" `shouldEqual` "/dev/foo"
      assetWith "/" "emblem.svg" `shouldEqual` "/emblem.svg"
