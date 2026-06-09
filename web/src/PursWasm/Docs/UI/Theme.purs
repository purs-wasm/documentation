module PursWasm.Docs.UI.Theme
  ( readDark
  , applyDark
  ) where

import Data.Unit (Unit)
import Effect (Effect)

-- | Whether the dark theme is currently active (the `.dark` class on <html>).
foreign import readDark :: Effect Boolean

-- | Apply (or remove) the dark theme and persist the choice to localStorage.
foreign import applyDark :: Boolean -> Effect Unit
