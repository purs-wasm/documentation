module PursWasm.Docs.UI.App where

import Prelude

import Data.Array (foldMap)
import Data.Maybe (Maybe(..), maybe)
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
import PursWasm.Docs.UI.Manifest as Manifest
import PursWasm.Docs.UI.Route (Route(..), docRoute, route, routePath)
import PursWasm.Docs.UI.SideMenuItem as SideMenuItem
import PursWasm.Docs.UI.Theme as Theme
import PursWasm.Docs.UI.Views.Home as Home
import PursWasm.Docs.UI.Views.MarkdownView as MarkdownView
import PursWasm.Docs.UI.Views.Search as SearchView
import Type.Proxy (Proxy(..))
import Web.UIEvent.KeyboardEvent as KE

make :: forall q i o m. MonadAff m => H.Component q i o m
make = Hooks.component \_ _ -> Hooks.do
  navigator <- useNavigate route
  query /\ queryId <- Hooks.useState ""
  dark /\ darkId <- Hooks.useState false
  menuOpen /\ menuOpenId <- Hooks.useState false
  searchFocused /\ searchFocusedId <- Hooks.useState false

  useLifecycleEffect do
    navigator.initialize
    liftEffect Theme.readDark >>= Hooks.put darkId
    pure Nothing

  Hooks.pure $ render
    { currentPage: navigator.currentRoute
    , query
    , queryId
    , navigateTo: \r -> do
        Hooks.put menuOpenId false
        navigator.navigateTo r
    , dark
    , setDark: \next -> do
        liftEffect (Theme.applyDark next)
        Hooks.put darkId next
    , menuOpen
    , menuOpenId
    , searchFocused
    , searchFocusedId
    }
  where
  render st =
    HH.div [ HP.class_ $ ClassName "flex flex-col h-screen bg-base text-fg" ]
      [ HH.header [ HP.class_ $ ClassName "relative z-50 shrink-0 bg-header text-brand border-b border-border" ]
          [ HH.div [ HP.class_ $ ClassName "flex items-center justify-between h-14 px-4 sm:px-9 gap-3" ]
              [ HH.div [ HP.class_ $ ClassName "flex items-center gap-3 min-w-0" ]
                  [ HH.button
                      [ HP.class_ $ ClassName "md:hidden p-1 -ml-1 flex cursor-pointer text-brand"
                      , HP.type_ HP.ButtonButton
                      , HP.attr (AttrName "aria-label") "Toggle navigation menu"
                      , HE.onClick \_ -> Hooks.put st.menuOpenId (not st.menuOpen)
                      ]
                      [ HH.span
                          [ HP.class_ $ ClassName "mask-icon w-6 h-6"
                          , HP.style (maskImage (Base.asset "img/menu-icon.svg"))
                          ]
                          []
                      ]
                  , HH.div
                      [ HP.class_ $ ClassName "flex items-center gap-3 font-mono font-semibold tracking-tight text-[20px] whitespace-nowrap cursor-pointer"
                      , HE.onClick \_ -> st.navigateTo Home
                      ]
                      [ HH.img [ HP.src (Base.asset "emblem.svg"), HP.alt "purs-wasm", HP.class_ $ ClassName "w-6 h-6 rounded-sm shrink-0" ]
                      , HH.text "purs-wasm"
                      ]
                  ]
              , HH.div [ HP.class_ $ ClassName "flex items-center gap-4 sm:gap-5" ]
                  [ themeToggle st
                  , HH.div
                      [ HP.class_ $ ClassName $
                          if st.searchFocused then "absolute left-4 right-4 top-3 z-20 w-auto md:relative md:inset-auto md:w-56"
                          else "relative w-9 md:w-56 mr-3"
                      ]
                      [ HH.span
                          [ HP.class_ $ ClassName "mask-icon text-fg-muted w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
                          , HP.style (maskImage (Base.asset "img/search-icon.svg"))
                          ]
                          []
                      , HH.input
                          [ HP.class_ $ ClassName $
                              "w-full pl-9 pr-3 py-1.5 text-sm border border-border bg-base text-fg placeholder:text-fg-muted focus:outline-none focus:border-accent "
                                <> (if st.searchFocused then "rounded-md" else "rounded-full md:rounded-md")
                          , HP.type_ HP.InputText
                          , HP.placeholder "Search docs…"
                          , HP.value st.query
                          , HE.onFocus \_ -> Hooks.put st.searchFocusedId true
                          , HE.onBlur \_ -> Hooks.put st.searchFocusedId false
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
      , HH.main [ HP.class_ $ ClassName "relative flex-1 min-h-0 flex" ]
          [ if st.menuOpen then
              HH.div
                [ HP.class_ $ ClassName "fixed inset-0 top-14 z-30 bg-black/40 md:hidden"
                , HE.onClick \_ -> Hooks.put st.menuOpenId false
                ]
                []
            else HH.text ""
          , HH.aside
              [ HP.class_ $ ClassName $
                  "fixed md:static top-14 bottom-0 left-0 z-40 w-64 shrink-0 min-h-0 overflow-y-auto border-r border-border bg-surface py-6 transition-transform md:translate-x-0 "
                    <> (if st.menuOpen then "translate-x-0" else "-translate-x-full")
              , HE.onClick \_ -> Hooks.put st.menuOpenId false
              ]
              [ HH.nav [ HP.class_ $ ClassName "flex flex-col gap-0.5 px-3" ]
                  ( foldMap (renderSection st) Manifest.sections
                      <>
                        [ HH.div [ HP.class_ $ ClassName "px-3 pt-3 text-xs leading-relaxed text-fg-muted" ]
                            [ HH.text "MIT licensed"
                            , HH.br_
                            , HH.text "© 2026 Katsujukou Kineya"
                            ]
                        ]
                  )
              ]
          , HH.div
              [ HP.class_ $ ClassName "flex-1 min-h-0 overflow-y-auto" ]
              [ HH.div [ HP.class_ $ ClassName "mx-auto max-w-3xl px-4 sm:px-8 py-8 sm:py-10" ]
                  [ renderRouterView st.currentPage ]
              ]
          ]
      ]

  themeToggle st =
    HH.div [ HP.class_ $ ClassName "flex items-center gap-2" ]
      [ HH.span [ HP.class_ $ ClassName "hidden sm:flex" ]
          [ themeIcon "Use light theme" (Base.asset "img/sun-icon.svg") (not st.dark) (st.setDark false) ]
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
      , HH.span [ HP.class_ $ ClassName "hidden sm:flex" ]
          [ themeIcon "Use dark theme" (Base.asset "img/moon-icon.svg") st.dark (st.setDark true) ]
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

  -- Horizontal divider between sections.
  spacer = HH.hr [ HP.class_ $ ClassName "my-3 border-0 border-t border-border" ]

  -- One sidebar section: a clickable headline pointing at the section landing,
  -- followed by its pages, then a divider.
  renderSection st section =
    [ HH.button
        [ HP.class_ $ ClassName "block w-full text-left px-3 pt-2 pb-1.5 text-sm font-semibold uppercase tracking-wider text-brand hover:opacity-70 transition-opacity cursor-pointer"
        , HP.type_ HP.ButtonButton
        , HE.onClick \_ -> st.navigateTo (docRoute section.landing.path)
        ]
        [ HH.text section.title ]
    ]
      <> map (\p -> sideMenuItem p.path p.nav) section.pages
      <> [ spacer ]

  sideMenuItem path label =
    HH.slot_ (Proxy :: _ "side-menu-item") (docRoute path) SideMenuItem.make
      { routes: route, label, to: docRoute path }

  renderRouterView currentPage = case currentPage of
    Nothing -> HH.text "Page not found"
    Just rt -> case rt of
      Home -> HH.slot_ (Proxy :: _ "home") unit Home.make {}
      Search { q } -> HH.slot_ (Proxy :: _ "search") unit SearchView.make { query: q }
      Doc _ ->
        maybe (HH.text "Page not found")
          (\pg -> renderMarkdownView rt pg.html)
          (Manifest.lookupByPath (routePath rt))

  renderMarkdownView r html = HH.slot_ (Proxy :: _ "router-view") r MarkdownView.make { html }
