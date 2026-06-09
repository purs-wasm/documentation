module PursWasm.Docs.UI.App where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Halogen (AttrName(..), ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Hooks (useLifecycleEffect)
import Halogen.Hooks as Hooks
import PursWasm.Docs.UI.Base as Base
import PursWasm.Docs.UI.Hooks.UseNavigate (useNavigate)
import PursWasm.Docs.UI.MarkdownContent as Content
import PursWasm.Docs.UI.Route (Route(..), route)
import PursWasm.Docs.UI.SideMenuItem as SideMenuItem
import PursWasm.Docs.UI.Theme as Theme
import PursWasm.Docs.UI.Views.Home as Home
import PursWasm.Docs.UI.Views.MarkdownView as MarkdownView
import PursWasm.Docs.UI.Views.Search as SearchView
import Type.Proxy (Proxy(..))
import Web.UIEvent.KeyboardEvent as KE

labelOf :: Route -> String
labelOf = case _ of
  Home -> "Purs-wasm"
  Installation -> "Installation"
  DevelopersGuide -> "Developer's Guide"
  RuntimeRepresentation -> "Runtime Representations"
  CompilationPipeline -> "Compilation Pipeline"
  SupportedFeatures -> "Supported Features"
  Optimizations -> "Optimizations"
  JsInterop -> "JS ↔ WASM interop"
  Search _ -> "Search"

make :: forall q i o m. MonadAff m => H.Component q i o m
make = Hooks.component \_ _ -> Hooks.do
  navigator <- useNavigate route
  query /\ queryId <- Hooks.useState ""
  dark /\ darkId <- Hooks.useState false

  useLifecycleEffect do
    navigator.initialize
    liftEffect Theme.readDark >>= Hooks.put darkId
    pure Nothing

  Hooks.pure $ render
    { currentPage: navigator.currentRoute
    , query
    , queryId
    , navigateTo: navigator.navigateTo
    , dark
    , setDark: \next -> do
        liftEffect (Theme.applyDark next)
        Hooks.put darkId next
    }
  where
  render st =
    HH.div [ HP.class_ $ ClassName "flex flex-col h-screen bg-base text-fg" ]
      [ HH.header [ HP.class_ $ ClassName "shrink-0 bg-header text-brand border-b border-border" ]
          [ HH.div [ HP.class_ $ ClassName "flex items-center justify-between h-14 px-9" ]
              [ HH.div 
                  [ HP.class_ $ ClassName "flex items-center gap-5 font-mono font-semibold tracking-tight text-[20px] cursor-pointer" 
                  , HE.onClick \_ -> st.navigateTo Home
                  ]
                  [ HH.img [ HP.src (Base.asset "emblem.svg"), HP.alt "purs-wasm", HP.class_ $ ClassName "w-6 h-6 rounded-sm" ]
                  , HH.text "purs-wasm"
                  ]
              , HH.div [ HP.class_ $ ClassName "flex items-center gap-4" ]
                  [ themeToggle st
                  , HH.div [ HP.class_ $ ClassName "relative" ]
                      [ HH.span
                          [ HP.class_ $ ClassName "mask-icon text-fg-muted w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
                          , HP.style (maskImage (Base.asset "img/search-icon.svg"))
                          ]
                          []
                      , HH.input
                          [ HP.class_ $ ClassName "w-56 pl-9 pr-3 py-1.5 text-sm rounded-md border border-border bg-base text-fg placeholder:text-fg-muted focus:outline-none focus:border-accent"
                          , HP.type_ HP.InputText
                          , HP.placeholder "Search docs…"
                          , HP.value st.query
                          , HE.onValueInput \v -> Hooks.put st.queryId v
                          , HE.onKeyDown \ev ->
                              when (KE.key ev == "Enter" && st.query /= "")
                                (st.navigateTo (Search { q: st.query }))
                          ]
                      ]
                  , HH.a
                      [ HP.class_ $ ClassName "opacity-70 hover:opacity-100 transition-opacity"
                      , HP.href "https://github.com/katsujukou/purescript-backend-wasm"
                      , HP.target "_blank"
                      , HP.rel "noopener noreferrer"
                      ]
                      [ HH.img [ HP.src (Base.asset "img/github-mark.svg"), HP.alt "GitHub", HP.class_ $ ClassName "w-6 h-6 block dark:invert" ] ]
                  ]
              ]
          ]
      , HH.main [ HP.class_ $ ClassName "flex-1 min-h-0 flex" ]
          [ HH.aside [ HP.class_ $ ClassName "w-64 shrink-0 min-h-0 overflow-y-auto border-r border-border bg-surface py-6" ]
              [ HH.nav [ HP.class_ $ ClassName "flex flex-col gap-0.5 px-3" ]
                  [ sideMenuHeadline "Getting Started"
                  , sideMenuItem Installation
                  , sideMenuItem JsInterop
                  , spacer
                  , HH.button
                      [ HP.class_ $ ClassName "block w-full text-left px-3 pt-2 pb-1.5 text-sm font-semibold uppercase tracking-wider text-brand hover:opacity-70 transition-opacity cursor-pointer"
                      , HP.type_ HP.ButtonButton
                      , HE.onClick \_ -> st.navigateTo DevelopersGuide
                      ]
                      [ HH.text "Developer's Guide" ]
                  , sideMenuItem SupportedFeatures
                  , sideMenuItem RuntimeRepresentation
                  , sideMenuItem CompilationPipeline
                  , sideMenuItem Optimizations
                  , spacer
                  , HH.div [ HP.class_ $ ClassName "px-3 text-xs leading-relaxed text-fg-muted" ]
                      [ HH.text "MIT licensed"
                      , HH.br_
                      , HH.text "© 2026 Katsujukou Kineya"
                      ]
                  ]
              ]
          , HH.div
              [ HP.class_ $ ClassName "flex-1 min-h-0 overflow-y-auto" ]
              [ HH.div [ HP.class_ $ ClassName "mx-auto max-w-3xl px-8 py-10" ]
                  [ renderRouterView st.currentPage ]
              ]
          ]
      ]

  themeToggle st =
    HH.div [ HP.class_ $ ClassName "flex items-center gap-2" ]
      [ themeIcon "Use light theme" (Base.asset "img/sun-icon.svg") (not st.dark) (st.setDark false)
      , HH.button
          [ HP.class_ $ ClassName "relative w-10 h-5 rounded-full bg-border transition-colors cursor-pointer"
          , HP.type_ HP.ButtonButton
          , HP.attr (AttrName "aria-label") "Toggle dark mode"
          , HE.onClick \_ -> st.setDark (not st.dark)
          ]
          [ HH.span
              [ HP.class_ $ ClassName ("absolute top-1 left-1 w-3 h-3 rounded-full bg-brand shadow-sm transition-transform" <> if st.dark then " translate-x-5" else "") ]
              []
          ]
      , themeIcon "Use dark theme" (Base.asset "img/moon-icon.svg") st.dark (st.setDark true)
      ]

  themeIcon label src active action =
    HH.button
      [ HP.class_ $ ClassName "p-1 -m-1 flex cursor-pointer"
      , HP.type_ HP.ButtonButton
      , HP.attr (AttrName "aria-label") label
      , HE.onClick \_ -> action
      ]
      [ HH.span
          [ HP.class_ $ ClassName ("theme-ico" <> if active then "" else " inactive")
          , HP.style (maskImage src)
          ]
          []
      ]

  maskImage url = "-webkit-mask-image:url(" <> url <> ");mask-image:url(" <> url <> ")"

  -- Horizontal divider between the nav items and the copyright notice.
  spacer = HH.hr [ HP.class_ $ ClassName "my-3 border-0 border-t border-border" ]

  sideMenuHeadline text = HH.div
    [ HP.class_ $ ClassName "px-3 pt-2 pb-1.5 text-sm font-semibold uppercase tracking-wider text-brand" ]
    [ HH.text text ]
  sideMenuItem r = HH.slot_ (Proxy :: _ "side-menu-item") r SideMenuItem.make { routes: route, label: labelOf r, to: r }

  renderRouterView currentPage = case currentPage of
    Nothing -> HH.text "Page not found"
    Just rt -> case rt of
      Home -> HH.slot_ (Proxy :: _ "home") unit Home.make {}
      Installation -> renderMarkdownView Installation Content.installation
      DevelopersGuide -> renderMarkdownView DevelopersGuide Content.developersGuide
      SupportedFeatures -> renderMarkdownView SupportedFeatures Content.supportedFeatures
      RuntimeRepresentation -> renderMarkdownView RuntimeRepresentation Content.runtimeRepresentation
      CompilationPipeline -> renderMarkdownView CompilationPipeline Content.compilationPipeline
      Optimizations -> renderMarkdownView Optimizations Content.optimizations
      JsInterop -> renderMarkdownView JsInterop Content.interop
      Search { q } -> HH.slot_ (Proxy :: _ "search") unit SearchView.make { query: q }

  renderMarkdownView r html = HH.slot_ (Proxy :: _ "router-view") r MarkdownView.make { html }
