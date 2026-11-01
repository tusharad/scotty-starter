{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Views.Layout
Copyright   : (c) 2026 Tushar Adhatrao, Scotty contributors
License     : BSD-3-Clause

Master HTML5 layout for the modern Haskell Web Engineering Studio.
Integrates Pure.css responsive base and custom dark slate/amber theme.
-}
module Views.Layout
    ( defaultLayout
    ) where

import           Prelude                     hiding (div, head, id, span)
import           Text.Blaze.Html5            (Html, a, body, div, docTypeHtml,
                                               footer, head, header, link, meta,
                                               p, script, span, title, (!))
import           Text.Blaze.Html5.Attributes (charset, class_, content, href,
                                               name, rel, src, target)

-- | Clean, responsive engineering studio layout with self-hosted styles, HTMX, and live telemetry.
defaultLayout :: Html -> Html -> Html
defaultLayout pageTitle pageBody = docTypeHtml $ do
  head $ do
    meta ! charset "utf-8"
    meta ! name "viewport" ! content "width=device-width, initial-scale=1, maximum-scale=5"
    meta ! name "description" ! content "Scotty Starter 2.0 - Production-Ready Haskell Web Application Starter"
    title pageTitle
    link ! rel "icon" ! href "/favicon.ico"
    link ! rel "stylesheet" ! href "/css/pure.min.css"
    link ! rel "stylesheet" ! href "/css/grids-responsive.min.css"
    link ! rel "stylesheet" ! href "/css/style.css"
    script ! src "/js/htmx.min.js" $ mempty
    script $
      "document.addEventListener('htmx:beforeSwap', function(evt) {\n"
      <> "  evt.detail.shouldSwap = true;\n"
      <> "  evt.detail.isError = false;\n"
      <> "});\n"
      <> "document.addEventListener('htmx:afterOnLoad', function(evt) {\n"
      <> "  var target = evt.detail.target;\n"
      <> "  if (target && target.classList.contains('console-output')) {\n"
      <> "    try {\n"
      <> "      var parsed = JSON.parse(target.textContent);\n"
      <> "      target.textContent = JSON.stringify(parsed, null, 2);\n"
      <> "    } catch(e) {}\n"
      <> "  }\n"
      <> "});\n"
      <> "function switchTourTab(tabId) {\n"
      <> "  var navItems = document.querySelectorAll('.studio-nav-item');\n"
      <> "  var panes = document.querySelectorAll('.tour-pane');\n"
      <> "  for (var i = 0; i < navItems.length; i++) {\n"
      <> "    navItems[i].classList.remove('active');\n"
      <> "  }\n"
      <> "  for (var j = 0; j < panes.length; j++) {\n"
      <> "    panes[j].classList.remove('active');\n"
      <> "  }\n"
      <> "  var activeBtn = document.querySelector('[data-tab=\"' + tabId + '\"]');\n"
      <> "  var activePane = document.getElementById('pane-' + tabId);\n"
      <> "  if (activeBtn) activeBtn.classList.add('active');\n"
      <> "  if (activePane) activePane.classList.add('active');\n"
      <> "}\n"
  body $ do
    header ! class_ "topbar" $ do
      div ! class_ "topbar-inner" $ do
        div ! class_ "brand-wrapper" $ do
          a ! class_ "brand-badge" ! href "/" $ do
            span ! class_ "lambda-glyph" $ "λ"
            span "SCOTTY // STARTER"
            span ! class_ "version-pill" $ "v0.2.0"
          div ! class_ "status-pill" $ do
            span ! class_ "pulse-dot" $ mempty
            span "ONLINE :3000"
        div ! class_ "nav-cluster" $ do
          a ! class_ "nav-btn swagger-btn" ! href "/docs" $ "⚡ Swagger UI"
          a ! class_ "nav-btn" ! href "/openapi.json" $ "📜 OpenAPI JSON"
          a ! class_ "nav-btn" ! href "/healthz" $ "🏥 Health"
          a ! class_ "nav-btn" ! href "https://github.com/scotty-web/scotty" ! target "_blank" $ "Scotty 0.30 ↗"

    pageBody

    footer $ do
      p "SCOTTY STARTER 2.0 • HASKELL WEB ENGINEERING STUDIO • GHC 9.10 • SCOTTY 0.30 • WARP • SQLITE • HTMX 2.0"
