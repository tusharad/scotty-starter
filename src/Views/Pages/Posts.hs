{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Views.Pages.Posts
Copyright   : (c) 2026 Tushar Adhatrao, Scotty contributors
License     : BSD-3-Clause

HTML components for interactive SQLite post management and HTMX state.
-}
module Views.Pages.Posts
    ( postCard
    , postsList
    , counterCard
    ) where

import           App.Api.Posts               (Post (..))
import           Data.String                 (fromString)
import           Prelude                     hiding (div, id, span)
import           Text.Blaze.Html5            (Html, button, customAttribute,
                                               div, p, span, toHtml, (!))
import           Text.Blaze.Html5.Attributes (class_, id)

-- | Reusable post item card with inline HTMX delete.
postCard :: Post -> Html
postCard (Post pid ptitle) =
  div ! class_ "post-card" ! id (fromString ("post-" ++ show pid)) $ do
    div ! class_ "post-info" $ do
      span ! class_ "post-id-chip" $ toHtml ("#" ++ show pid)
      span ! class_ "post-title" $ toHtml ptitle
    button ! class_ "btn-del"
           ! customAttribute "hx-delete" (fromString ("/partials/posts/" ++ show pid))
           ! customAttribute "hx-target" (fromString ("#post-" ++ show pid))
           ! customAttribute "hx-swap" "outerHTML"
           ! customAttribute "hx-confirm" "Delete this record from SQLite database?"
           $ "Delete"

-- | Render list of post cards or empty fallback.
postsList :: [Post] -> Html
postsList [] = p ! customAttribute "style" "color: var(--text-muted); padding: 1rem 0; font-family: var(--font-mono); font-size: 0.85rem;" $ "No records currently stored in SQLite database."
postsList ps = mapM_ postCard ps

-- | Interactive HTMX counter partial demonstrating server-side atomic state updates.
counterCard :: Int -> Html
counterCard count =
  button ! class_ "btn-secondary"
         ! id "counter-btn"
         ! customAttribute "hx-post" "/partials/counter"
         ! customAttribute "hx-target" "#counter-btn"
         ! customAttribute "hx-swap" "outerHTML"
         $ toHtml ("Server Clicks: " ++ show count ++ " ⚡")
