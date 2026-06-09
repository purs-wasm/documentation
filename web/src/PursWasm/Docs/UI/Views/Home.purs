module PursWasm.Docs.UI.Views.Home where

import Prelude

import Effect.Class (class MonadEffect)
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import PursWasm.Docs.UI.Base (asset)

make :: forall q i o m. MonadEffect m => H.Component q i o m
make = Hooks.component \_ _ -> Hooks.do
  Hooks.pure (render {})
  where
  render _ = do
    HH.div []
      [ HH.div [ HP.class_ $ ClassName "mb-10" ]
          [ HH.img
              [ HP.src (asset "emblem.svg")
              , HP.alt "purs-wasm"
              , HP.class_ $ ClassName "w-14 h-14 rounded-lg mb-5 dark:invert"
              ]
          , HH.h1 [ HP.class_ $ ClassName "text-3xl font-bold tracking-tight text-fg-strong" ]
              [ HH.text "PureScript → WebAssembly" ]
          , HH.p [ HP.class_ $ ClassName "mt-3 text-fg-muted leading-relaxed max-w-2xl" ]
              [ HH.text "An experimental PureScript backend that compiles to WebAssembly GC. Browse the developer's guide to learn how the compiler represents values, lowers code, and stays fast." ]
          ]
      ]
