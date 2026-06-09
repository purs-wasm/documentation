module PursWasm.Docs.UI.Views.MarkdownView where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen (ClassName(..), PropName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Hooks (useLifecycleEffect)
import Halogen.Hooks as Hooks

foreign import scrollToCurrentHash :: Effect Unit

type Input = { html :: String }

make :: forall q o m. MonadEffect m => H.Component q Input o m
make = Hooks.component \_ { html } -> Hooks.do
  -- The content is injected via innerHTML, so scroll to the URL hash (if any)
  -- once the document is in the DOM, after the route resolves.
  useLifecycleEffect do
    liftEffect scrollToCurrentHash
    pure Nothing

  Hooks.pure (render { html })
  where
  render { html } = do
    HH.div
      [ HP.class_ (ClassName "md-doc")
      , HP.prop (PropName "innerHTML") html
      ]
      []
