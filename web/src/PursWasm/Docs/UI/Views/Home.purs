module PursWasm.Docs.UI.Views.Home where

import Prelude

import Effect.Class (class MonadEffect)
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import PursWasm.Docs.UI.Base (asset)
import PursWasm.Docs.UI.Base as Base
import PursWasm.Docs.UI.Hooks.UseApp (Theme(..), useApp)

make :: forall q i o m. MonadEffect m => H.Component q i o m
make = Hooks.component \_ _ -> Hooks.do
  appApi <- useApp

  Hooks.pure (render { theme: appApi.theme })
  where
  render ctx = do
    HH.div []
      [ HH.div [ HP.class_ $ ClassName "mb-10" ]
          [ HH.img
              [ HP.src (asset "emblem.svg")
              , HP.alt "purs-wasm"
              , HP.class_ $ ClassName "w-14 h-14 rounded-lg mb-5 dark:invert"
              ]
          , HH.h1
              [ HP.class_ $ ClassName "text-3xl font-bold tracking-tight text-fg-strong" ]
              [ HH.span []
                  [ HH.span [ HP.class_ $ ClassName "text-purs" ] [ HH.text "PureScript" ]
                  , HH.text " → "
                  , HH.span [ HP.class_ $ ClassName "text-wasm" ] [ HH.text "WebAssembly" ]
                  ]
              ]
          , HH.p
              [ HP.class_ $ ClassName "my-6 max-w-2xl" ]
              [ HH.span [ HP.class_ $ ClassName "text-fg-muted leading-relaxed " ]
                  [ HH.text
                      "Purs-wasm is an experimental compiler from PureScript to WebAssembly. \
                      \According to our benchmarks, the compiled wasm typically runs faster than \
                      \the JavaScript emitted by both the stock PureScript compiler and "
                  ]
              , HH.a
                  [ HP.href "https://github.com/aristanetworks/purescript-backend-optimizer"
                  , HP.class_ $ ClassName "text-accent underline"
                  , HP.target "_blank"
                  , HP.rel "noopener noreferrer"
                  ]
                  [ HH.text "purs-backend-es" ]
              ]
          , HH.a
              [ HP.class_ $ ClassName "flex gap-5 items-center"
              , HP.href "https://github.com/purs-wasm/purescript-backend-wasm"
              , HP.target "_blank"
              , HP.rel "noopener noreferrer"
              ]
              [ HH.div
                  [ HP.class_ $ ClassName "flex gap-3 p-3 rounded-sm items-center bg-github text-[#ffffff]" ]
                  [ HH.img
                      [ HP.src $
                          case ctx.theme of
                            Dark -> Base.asset "img/github-mark.svg"
                            Light -> Base.asset "img/github-mark-white.svg"
                      , HP.class_ $ ClassName "w-8 h-8"
                      ]
                  , HH.span
                      [ HP.class_ $ ClassName "font-bold text-xl dark:text-[#24292e]" ]
                      [ HH.text "GitHub" ]
                  ]

              , HH.a
                  [ HP.class_ $ ClassName "flex gap-1 p-3 rounded-sm items-center bg-[#cb3837] text-[#ffffff]"
                  , HP.href "https://www.npmjs.com/package/purs-wasm"
                  , HP.target "_blank"
                  , HP.rel "noopener noreferrer"
                  ]
                  [ HH.img
                      [ HP.src $ Base.asset "img/npmjs-icon.svg"
                      , HP.class_ $ ClassName "w-8 h-8"
                      ]
                  , HH.span
                      [ HP.class_ $ ClassName "font-bold text-xl " ]
                      [ HH.text "npm" ]
                  ]
              ]
          ]
      ]
