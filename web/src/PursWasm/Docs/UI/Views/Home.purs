module PursWasm.Docs.UI.Views.Home where

import Prelude

import Effect.Class (class MonadEffect)
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import PursWasm.Docs.UI.Base (asset)
import PursWasm.Docs.UI.Hooks.UseNavigate (useNavigate)
import PursWasm.Docs.UI.Route (Route(..), route)

cards :: Array { to :: Route, title :: String, desc :: String }
cards =
  [ { to: SupportedFeatures, title: "Supported Features", desc: "Which PureScript language features the backend supports, and how far." }
  , { to: RuntimeRepresentation, title: "Runtime Representations", desc: "How PureScript values are laid out as WebAssembly GC types." }
  , { to: CompilationPipeline, title: "Compilation Pipeline", desc: "From CoreFn through the IR stages down to emitted WASM." }
  , { to: Optimizations, title: "Optimizations", desc: "The transformations that make the generated code fast." }
  , { to: JsInterop, title: "JS Interop", desc: "Crossing the boundary between JavaScript and WebAssembly." }
  ]

make :: forall q i o m. MonadEffect m => H.Component q i o m
make = Hooks.component \_ _ -> Hooks.do
  navigator <- useNavigate route
  Hooks.pure (render navigator.navigateTo)
  where
  render go = do
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
              [ HH.text "An optimizing PureScript backend that compiles to WebAssembly GC. Browse the developer's guide to learn how the compiler represents values, lowers code, and stays fast." ]
          ]
      , HH.div [ HP.class_ $ ClassName "grid grid-cols-1 sm:grid-cols-2 gap-3" ]
          (renderCard go <$> cards)
      ]

  renderCard go { to, title, desc } =
    HH.button
      [ HP.class_ $ ClassName "text-left p-4 rounded-lg border border-border bg-surface hover:border-accent transition-colors cursor-pointer group"
      , HE.onClick \_ -> go to
      ]
      [ HH.div [ HP.class_ $ ClassName "font-semibold text-fg-strong group-hover:text-accent transition-colors" ]
          [ HH.text title ]
      , HH.p [ HP.class_ $ ClassName "mt-1 text-sm text-fg-muted leading-snug" ]
          [ HH.text desc ]
      ]
