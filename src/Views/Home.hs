{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Views.Home
Copyright   : (c) 2026 Tushar Adhatrao, Scotty contributors
License     : BSD-3-Clause

Modern, mobile-responsive Haskell Web Engineering Studio homepage.
Provides rapid project scaffolding guidance and an interactive Scotty 0.30 feature tour.
-}
module Views.Home (homeView) where

import           App.Api.Posts               (Post (..))
import           Control.Monad.IO.Class      (MonadIO)
import           Prelude                     hiding (div, id, span)
import           Text.Blaze.Html5            (Html, a, aside, button,
                                               customAttribute, div, form, h1,
                                               h2, h3, input, main, p, pre,
                                               span, strong, (!))
import           Text.Blaze.Html5.Attributes (autocomplete, class_, href, id,
                                               name, onclick, placeholder, type_)
import           Views.Layout                (defaultLayout)
import           Views.Pages.Posts           (counterCard, postsList)
import           Views.Utils                 (blaze)
import qualified Web.Scotty.Trans            as S

-- ----------------------------------------------------------------------------
-- Syntax Highlighting Helpers
-- ----------------------------------------------------------------------------
kw, fn, ty, str, num, cm :: Html -> Html
kw  = span ! class_ "syn-kw"
fn  = span ! class_ "syn-fn"
ty  = span ! class_ "syn-type"
str = span ! class_ "syn-str"
num = span ! class_ "syn-num"
cm  = span ! class_ "syn-cm"

-- | Render the modern Haskell Engineering Studio layout.
homeView :: MonadIO m => [Post] -> S.ActionT m ()
homeView initialPosts = blaze $ defaultLayout "Scotty Starter 2.0 // Haskell Web Engineering Studio" $ do
  main ! class_ "workbench-container" $ do

    -- ------------------------------------------------------------------------
    -- Masthead: Hero Intro & Tech Specs
    -- ------------------------------------------------------------------------
    div ! class_ "masthead" $ do
      h1 ! class_ "masthead-title" $ "Scotty Web Application Starter"
      p ! class_ "masthead-sub" $
        "A modern, high-performance, battery-included web starter kit for Haskell. Designed for rapid scaffolding, featuring type-safe routing, connection pooling, SQLite migrations, automated OpenAPI 3.0, and reactive HTMX hypermedia."
      div ! class_ "spec-strip" $ do
        span ! class_ "spec-chip" $ do strong "GHC "; "9.10.3"
        span ! class_ "spec-chip" $ do strong "Scotty "; "0.30"
        span ! class_ "spec-chip" $ do strong "Engine "; "Warp (-threaded -N)"
        span ! class_ "spec-chip" $ do strong "OpenAPI "; "3.0 (PR #438)"
        span ! class_ "spec-chip" $ do strong "DB "; "SQLite3 + Pool"
        span ! class_ "spec-chip" $ do strong "UI "; "HTMX 2.0"
        span ! class_ "spec-chip" $ do strong "Errors "; "RFC 7807"

    -- ------------------------------------------------------------------------
    -- Scaffolding & Quickstart Guide
    -- ------------------------------------------------------------------------
    div ! class_ "scaffold-grid" $ do
      -- CLI Cheatsheet (Fixed line-by-line terminal output)
      div ! class_ "scaffold-card" $ do
        h3 ! class_ "scaffold-card-title" $ do
          span ! class_ "lambda-glyph" $ "⚡"
          span "Developer CLI Workflow"
        p ! class_ "scaffold-card-desc" $ "Essential commands to run, test, and develop your project."
        pre ! class_ "cli-cheatsheet" $ do
          span ! class_ "comment" $ "# 1. Run server on http://localhost:3000\n"
          span ! class_ "cmd" $ "$ cabal run scotty-starter\n\n"
          span ! class_ "comment" $ "# 2. Run automated test suite (28 tests)\n"
          span ! class_ "cmd" $ "$ cabal test --test-show-details=direct\n\n"
          span ! class_ "comment" $ "# 3. Live reload on code changes\n"
          span ! class_ "cmd" $ "$ make watch\n\n"
          span ! class_ "comment" $ "# 4. Open interactive REPL\n"
          span ! class_ "cmd" $ "$ cabal repl"

      -- Architecture Blueprint (Clean mobile-friendly tree)
      div ! class_ "scaffold-card" $ do
        h3 ! class_ "scaffold-card-title" $ do
          span ! class_ "lambda-glyph" $ "📁"
          span "Project Layout Blueprint"
        p ! class_ "scaffold-card-desc" $ "Where to scaffold your routes, models, and views."
        pre ! class_ "tree-list" $ do
          "scotty-starter/\n"
          "├── " >> strong "src/App.hs" >> "\n"
          "│   └── " >> (span ! class_ "tag" $ "App wiring & middlewares\n")
          "├── " >> strong "src/App/Api/" >> "\n"
          "│   └── " >> (span ! class_ "tag" $ "REST routes (Health, Posts, Tour)\n")
          "├── " >> strong "src/App/Config.hs" >> "\n"
          "│   └── " >> (span ! class_ "tag" $ "Typed environment config\n")
          "├── " >> strong "src/App/Database/" >> "\n"
          "│   └── " >> (span ! class_ "tag" $ "SQLite pool & migrations\n")
          "├── " >> strong "src/App/Docs.hs" >> "\n"
          "│   └── " >> (span ! class_ "tag" $ "OpenAPI 3.0 & Swagger UI\n")
          "└── " >> strong "src/Views/" >> "\n"
          "    └── " >> (span ! class_ "tag" $ "Blaze HTML5 & HTMX views")

    -- ------------------------------------------------------------------------
    -- Swagger & OpenAPI Callout Banner (PR #438 Showcase)
    -- ------------------------------------------------------------------------
    div ! class_ "swagger-banner" $ do
      div ! class_ "swagger-banner-content" $ do
        h3 $ do span "⚡"; " Built-in Swagger UI & OpenAPI 3.0 (PR #438)"
        p "Every endpoint is declared with type-safe metadata combinators. Explore the interactive documentation via Swagger UI or consume the raw OpenAPI 3.0 specification."
      div ! class_ "swagger-banner-actions" $ do
        a ! class_ "btn-primary" ! href "/docs" $ "Launch Swagger UI (/docs) ↗"
        a ! class_ "btn-secondary" ! href "/openapi.json" $ "View OpenAPI JSON"

    -- ------------------------------------------------------------------------
    -- Section 1: Interactive Scotty 0.30 Feature Studio
    -- ------------------------------------------------------------------------
    div ! class_ "section-header" $ do
      span ! class_ "section-num" $ "§ 01"
      h2 ! class_ "section-title" $ "Interactive Scotty 0.30 Feature Studio"
    p ! class_ "section-desc" $
      "Select a topic below to inspect the syntax-highlighted Haskell implementation, adjust request parameters, and trigger real-time server responses."

    div ! class_ "studio-container" $ do

      -- Studio Sidebar Navigation / Mobile Swipeable Tab Strip
      aside ! class_ "studio-sidebar" $ do
        button ! class_ "studio-nav-item active"
               ! customAttribute "data-tab" "path-params"
               ! onclick "switchTourTab('path-params')" $ do
          span ! class_ "nav-label" $ do
            span ! class_ "nav-index" $ "01"
            span "Path Parameters"
          span ! class_ "method-badge get" $ "GET"

        button ! class_ "studio-nav-item"
               ! customAttribute "data-tab" "query-params"
               ! onclick "switchTourTab('query-params')" $ do
          span ! class_ "nav-label" $ do
            span ! class_ "nav-index" $ "02"
            span "Query Parameters"
          span ! class_ "method-badge get" $ "GET"

        button ! class_ "studio-nav-item"
               ! customAttribute "data-tab" "json-body"
               ! onclick "switchTourTab('json-body')" $ do
          span ! class_ "nav-label" $ do
            span ! class_ "nav-index" $ "03"
            span "JSON Request Body"
          span ! class_ "method-badge post" $ "POST"

        button ! class_ "studio-nav-item"
               ! customAttribute "data-tab" "form-params"
               ! onclick "switchTourTab('form-params')" $ do
          span ! class_ "nav-label" $ do
            span ! class_ "nav-index" $ "04"
            span "Form Submissions"
          span ! class_ "method-badge post" $ "POST"

        button ! class_ "studio-nav-item"
               ! customAttribute "data-tab" "headers-cookies"
               ! onclick "switchTourTab('headers-cookies')" $ do
          span ! class_ "nav-label" $ do
            span ! class_ "nav-index" $ "05"
            span "Headers & Cookies"
          span ! class_ "method-badge get" $ "GET"

        button ! class_ "studio-nav-item"
               ! customAttribute "data-tab" "status-codes"
               ! onclick "switchTourTab('status-codes')" $ do
          span ! class_ "nav-label" $ do
            span ! class_ "nav-index" $ "06"
            span "HTTP Status Codes"
          span ! class_ "method-badge get" $ "GET"

        button ! class_ "studio-nav-item"
               ! customAttribute "data-tab" "error-handling"
               ! onclick "switchTourTab('error-handling')" $ do
          span ! class_ "nav-label" $ do
            span ! class_ "nav-index" $ "07"
            span "RFC 7807 Errors"
          span ! class_ "method-badge err" $ "ERR"

        button ! class_ "studio-nav-item"
               ! customAttribute "data-tab" "redirection"
               ! onclick "switchTourTab('redirection')" $ do
          span ! class_ "nav-label" $ do
            span ! class_ "nav-index" $ "08"
            span "Redirection"
          span ! class_ "method-badge redir" $ "302"

      -- Studio Main Stage
      div ! class_ "studio-stage" $ do

        -- --------------------------------------------------------------------
        -- Pane 1: Path Parameters
        -- --------------------------------------------------------------------
        div ! id "pane-path-params" ! class_ "tour-pane active" $ do
          div ! class_ "pane-header" $ do
            div ! class_ "pane-route" $ do
              span ! class_ "method-badge get" $ "GET"
              span "/api/tour/path-params/:category/:id"
            h3 ! class_ "pane-title" $ "Typed URL Path Parameters"
            p ! class_ "pane-description" $
              "Scotty captures URL pattern variables designated with a colon (e.g. :category, :id) and parses them automatically into Haskell types (Text, Int, UUID). If parsing fails, Scotty throws a parse error handled centrally."

          div ! class_ "studio-work-area" $ do
            div ! class_ "code-window" $ do
              div ! class_ "window-bar" $ do
                div ! class_ "window-dots" $ do
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                span "src/App/Api/Tour.hs"
                span "Scotty 0.30 DSL"
              pre ! class_ "code-snippet" $ do
                fn "S.get" >> " " >> str "\"/api/tour/path-params/:category/:id\"" >> " " >> kw "$" >> " " >> kw "do" >> "\n"
                "  category " >> kw "<-" >> " " >> fn "S.pathParam" >> " " >> str "\"category\"" >> " " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " " >> ty "Text" >> "\n"
                "  itemId   " >> kw "<-" >> " " >> fn "S.pathParam" >> " " >> str "\"id\"" >> "       " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " " >> ty "Int" >> "\n\n"
                "  " >> fn "S.status" >> " " >> fn "status200" >> "\n"
                "  " >> fn "S.json" >> " " >> kw "$" >> " " >> fn "object" >> "\n"
                "    [ " >> str "\"concept\"" >> "  " >> fn ".=" >> " (" >> str "\"Path Parameters\"" >> " " >> kw "::" >> " " >> ty "Text" >> ")\n"
                "    , " >> str "\"category\"" >> " " >> fn ".=" >> " category\n"
                "    , " >> str "\"id\"" >> "       " >> fn ".=" >> " itemId\n"
                "    ]"

            div ! class_ "test-panel" $ do
              div ! class_ "control-box" $ do
                span ! class_ "control-box-title" $ "Test Presets"
                div ! class_ "preset-buttons" $ do
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/path-params/books/42"
                         ! customAttribute "hx-target" "#console-path" $ "GET /books/42"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/path-params/haskell/2026"
                         ! customAttribute "hx-target" "#console-path" $ "GET /haskell/2026"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/path-params/fp-starters/7"
                         ! customAttribute "hx-target" "#console-path" $ "GET /fp-starters/7"
              div ! class_ "console-box" $ do
                div ! class_ "console-bar" $ do
                  span "SERVER RESPONSE"
                  span "JSON"
                pre ! id "console-path" ! class_ "console-output" $ "Select a preset above to execute S.pathParam query..."

        -- --------------------------------------------------------------------
        -- Pane 2: Query Parameters
        -- --------------------------------------------------------------------
        div ! id "pane-query-params" ! class_ "tour-pane" $ do
          div ! class_ "pane-header" $ do
            div ! class_ "pane-route" $ do
              span ! class_ "method-badge get" $ "GET"
              span "/api/tour/query-params?filter=...&limit=..."
            h3 ! class_ "pane-title" $ "Optional & Required Query Parameters"
            p ! class_ "pane-description" $
              "Scotty provides S.queryParam for required parameters (throwing QueryParameterNotFound if absent), S.queryParamMaybe for optional parameters (returning Maybe a), and S.queryParams for raw key-value pairs."

          div ! class_ "studio-work-area" $ do
            div ! class_ "code-window" $ do
              div ! class_ "window-bar" $ do
                div ! class_ "window-dots" $ do
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                span "src/App/Api/Tour.hs"
                span "Scotty 0.30 DSL"
              pre ! class_ "code-snippet" $ do
                fn "S.get" >> " " >> str "\"/api/tour/query-params\"" >> " " >> kw "$" >> " " >> kw "do" >> "\n"
                "  filterVal  " >> kw "<-" >> " " >> fn "S.queryParamMaybe" >> " " >> str "\"filter\"" >> " " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " (" >> ty "Maybe" >> " " >> ty "Text" >> ")\n"
                "  limitVal   " >> kw "<-" >> " " >> fn "S.queryParamMaybe" >> " " >> str "\"limit\"" >> "  " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " (" >> ty "Maybe" >> " " >> ty "Int" >> ")\n"
                "  rawQueries " >> kw "<-" >> " " >> fn "S.queryParams" >> "\n\n"
                "  " >> fn "S.status" >> " " >> fn "status200" >> "\n"
                "  " >> fn "S.json" >> " " >> kw "$" >> " " >> fn "object" >> "\n"
                "    [ " >> str "\"concept\"" >> "     " >> fn ".=" >> " (" >> str "\"Query Parameters\"" >> " " >> kw "::" >> " " >> ty "Text" >> ")\n"
                "    , " >> str "\"filter\"" >> "      " >> fn ".=" >> " filterVal\n"
                "    , " >> str "\"limit\"" >> "       " >> fn ".=" >> " limitVal\n"
                "    , " >> str "\"raw_queries\"" >> " " >> fn ".=" >> " rawQueries\n"
                "    ]"

            div ! class_ "test-panel" $ do
              div ! class_ "control-box" $ do
                span ! class_ "control-box-title" $ "Test Presets"
                div ! class_ "preset-buttons" $ do
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/query-params?filter=functional&limit=5&active=true"
                         ! customAttribute "hx-target" "#console-query" $ "?filter=functional&limit=5&active=true"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/query-params?filter=haskell&limit=2"
                         ! customAttribute "hx-target" "#console-query" $ "?filter=haskell&limit=2"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/query-params"
                         ! customAttribute "hx-target" "#console-query" $ "Default (No query params)"
              div ! class_ "console-box" $ do
                div ! class_ "console-bar" $ do
                  span "SERVER RESPONSE"
                  span "JSON"
                pre ! id "console-query" ! class_ "console-output" $ "Select a preset above to test query parameter parsing..."

        -- --------------------------------------------------------------------
        -- Pane 3: JSON Request Body
        -- --------------------------------------------------------------------
        div ! id "pane-json-body" ! class_ "tour-pane" $ do
          div ! class_ "pane-header" $ do
            div ! class_ "pane-route" $ do
              span ! class_ "method-badge post" $ "POST"
              span "/api/tour/json-body"
            h3 ! class_ "pane-title" $ "Typed JSON Deserialization via Aeson"
            p ! class_ "pane-description" $
              "Using S.jsonData, Scotty streams and deserializes incoming JSON payloads directly into strongly-typed Haskell data records. Malformed JSON automatically triggers the centralized RFC 7807 error handler."

          div ! class_ "studio-work-area" $ do
            div ! class_ "code-window" $ do
              div ! class_ "window-bar" $ do
                div ! class_ "window-dots" $ do
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                span "src/App/Api/Tour.hs"
                span "Scotty 0.30 DSL"
              pre ! class_ "code-snippet" $ do
                kw "data" >> " " >> ty "TourPayload" >> " " >> kw "=" >> " " >> ty "TourPayload" >> "\n"
                "  { name   " >> kw "::" >> " " >> kw "!" >> ty "Text" >> "\n"
                "  , role   " >> kw "::" >> " " >> kw "!" >> ty "Text" >> "\n"
                "  , skills " >> kw "::" >> " " >> kw "![" >> ty "Text" >> "]\n"
                "  } " >> kw "deriving" >> " (" >> ty "Generic" >> ", " >> ty "FromJSON" >> ", " >> ty "ToJSON" >> ")\n\n"
                fn "S.post" >> " " >> str "\"/api/tour/json-body\"" >> " " >> kw "$" >> " " >> kw "do" >> "\n"
                "  payload " >> kw "<-" >> " " >> fn "S.jsonData" >> " " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " " >> ty "TourPayload" >> "\n"
                "  " >> fn "S.status" >> " " >> fn "status201" >> "\n"
                "  " >> fn "S.json" >> " " >> kw "$" >> " " >> fn "object" >> "\n"
                "    [ " >> str "\"concept\"" >> " " >> fn ".=" >> " (" >> str "\"JSON Deserialization\"" >> " " >> kw "::" >> " " >> ty "Text" >> ")\n"
                "    , " >> str "\"parsed\"" >> "  " >> fn ".=" >> " payload\n"
                "    ]"

            div ! class_ "test-panel" $ do
              div ! class_ "control-box" $ do
                span ! class_ "control-box-title" $ "Test Payloads"
                div ! class_ "preset-buttons" $ do
                  button ! class_ "btn-primary"
                         ! onclick "fetch('/api/tour/json-body', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({name: 'Alonzo Church', role: 'Logician', skills: ['Lambda Calculus', 'Type Theory']})}).then(r => r.json()).then(d => { document.getElementById('console-json').textContent = JSON.stringify(d, null, 2); })"
                         $ "POST Alonzo Church"
                  button ! class_ "btn-secondary"
                         ! onclick "fetch('/api/tour/json-body', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({name: 'Ada Lovelace', role: 'Architect', skills: ['Analytical Engine', 'Concurrency']})}).then(r => r.json()).then(d => { document.getElementById('console-json').textContent = JSON.stringify(d, null, 2); })"
                         $ "POST Ada Lovelace"
              div ! class_ "console-box" $ do
                div ! class_ "console-bar" $ do
                  span "SERVER RESPONSE"
                  span "JSON"
                pre ! id "console-json" ! class_ "console-output" $ "Click a payload button to POST typed JSON to S.jsonData..."

        -- --------------------------------------------------------------------
        -- Pane 4: Form Submissions
        -- --------------------------------------------------------------------
        div ! id "pane-form-params" ! class_ "tour-pane" $ do
          div ! class_ "pane-header" $ do
            div ! class_ "pane-route" $ do
              span ! class_ "method-badge post" $ "POST"
              span "/api/tour/form-params"
            h3 ! class_ "pane-title" $ "URL-Encoded Multipart Form Processing"
            p ! class_ "pane-description" $
              "Scotty handles standard HTML form body submissions seamlessly using S.formParam and S.formParamMaybe, converting form fields into typed Haskell variables."

          div ! class_ "studio-work-area" $ do
            div ! class_ "code-window" $ do
              div ! class_ "window-bar" $ do
                div ! class_ "window-dots" $ do
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                span "src/App/Api/Tour.hs"
                span "Scotty 0.30 DSL"
              pre ! class_ "code-snippet" $ do
                fn "S.post" >> " " >> str "\"/api/tour/form-params\"" >> " " >> kw "$" >> " " >> kw "do" >> "\n"
                "  uname " >> kw "<-" >> " " >> fn "S.formParam" >> " " >> str "\"username\"" >> "   " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " " >> ty "Text" >> "\n"
                "  email " >> kw "<-" >> " " >> fn "S.formParam" >> " " >> str "\"email\"" >> "      " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " " >> ty "Text" >> "\n"
                "  news  " >> kw "<-" >> " " >> fn "S.formParamMaybe" >> " " >> str "\"newsletter\"" >> " " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " (" >> ty "Maybe" >> " " >> ty "Bool" >> ")\n\n"
                "  " >> fn "S.status" >> " " >> fn "status201" >> "\n"
                "  " >> fn "S.json" >> " " >> kw "$" >> " " >> fn "object" >> "\n"
                "    [ " >> str "\"concept\"" >> "    " >> fn ".=" >> " (" >> str "\"Form Data Parsing\"" >> " " >> kw "::" >> " " >> ty "Text" >> ")\n"
                "    , " >> str "\"username\"" >> "   " >> fn ".=" >> " uname\n"
                "    , " >> str "\"email\"" >> "      " >> fn ".=" >> " email\n"
                "    , " >> str "\"newsletter\"" >> " " >> fn ".=" >> " news\n"
                "    ]"

            div ! class_ "test-panel" $ do
              div ! class_ "control-box" $ do
                span ! class_ "control-box-title" $ "Interactive Form"
                form ! class_ "form-row"
                     ! customAttribute "hx-post" "/api/tour/form-params"
                     ! customAttribute "hx-target" "#console-form" $ do
                  input ! type_ "text" ! name "username" ! class_ "form-input" ! placeholder "Username" ! customAttribute "value" "simon_pj"
                  input ! type_ "email" ! name "email" ! class_ "form-input" ! placeholder "Email" ! customAttribute "value" "simon@ghc.dev"
                  button ! type_ "submit" ! class_ "btn-primary" $ "Submit Form"
              div ! class_ "console-box" $ do
                div ! class_ "console-bar" $ do
                  span "SERVER RESPONSE"
                  span "JSON"
                pre ! id "console-form" ! class_ "console-output" $ "Submit the form above to inspect S.formParam extraction..."

        -- --------------------------------------------------------------------
        -- Pane 5: Headers & Cookies
        -- --------------------------------------------------------------------
        div ! id "pane-headers-cookies" ! class_ "tour-pane" $ do
          div ! class_ "pane-header" $ do
            div ! class_ "pane-route" $ do
              span ! class_ "method-badge get" $ "GET"
              span "/api/tour/headers-and-cookies"
            h3 ! class_ "pane-title" $ "Request Headers & Cookie Management"
            p ! class_ "pane-description" $
              "Read incoming request headers (S.header), inspect client cookies (getCookie), set custom response headers (S.setHeader), and set cookies with ease."

          div ! class_ "studio-work-area" $ do
            div ! class_ "code-window" $ do
              div ! class_ "window-bar" $ do
                div ! class_ "window-dots" $ do
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                span "src/App/Api/Tour.hs"
                span "Scotty 0.30 DSL"
              pre ! class_ "code-snippet" $ do
                fn "S.get" >> " " >> str "\"/api/tour/headers-and-cookies\"" >> " " >> kw "$" >> " " >> kw "do" >> "\n"
                "  ua <- " >> fn "S.header" >> " " >> str "\"User-Agent\"" >> "\n"
                "  c  <- " >> fn "getCookie" >> " " >> str "\"visited\"" >> "\n\n"
                "  " >> cm "-- Set custom response header and cookie\n"
                "  " >> fn "S.setHeader" >> " " >> str "\"X-Scotty-Powered-By\"" >> " " >> str "\"Scotty 0.30 (Haskell)\"" >> "\n"
                "  " >> fn "setSimpleCookie" >> " " >> str "\"visited\"" >> " " >> str "\"true\"" >> "\n\n"
                "  " >> fn "S.status" >> " " >> fn "status200" >> "\n"
                "  " >> fn "S.json" >> " " >> kw "$" >> " " >> fn "object" >> "\n"
                "    [ " >> str "\"concept\"" >> "    " >> fn ".=" >> " (" >> str "\"Headers & Cookies\"" >> " " >> kw "::" >> " " >> ty "Text" >> ")\n"
                "    , " >> str "\"user_agent\"" >> " " >> fn ".=" >> " (" >> fn "fmap" >> " " >> fn "TL.toStrict" >> " ua)\n"
                "    , " >> str "\"cookie\"" >> "     " >> fn ".=" >> " c\n"
                "    ]"

            div ! class_ "test-panel" $ do
              div ! class_ "control-box" $ do
                span ! class_ "control-box-title" $ "Test Controls"
                div ! class_ "preset-buttons" $ do
                  button ! class_ "btn-primary"
                         ! customAttribute "hx-get" "/api/tour/headers-and-cookies"
                         ! customAttribute "hx-target" "#console-headers" $ "Send Request & Issue Cookie"
              div ! class_ "console-box" $ do
                div ! class_ "console-bar" $ do
                  span "SERVER RESPONSE"
                  span "JSON"
                pre ! id "console-headers" ! class_ "console-output" $ "Click above to read client headers and set response cookie..."

        -- --------------------------------------------------------------------
        -- Pane 6: HTTP Status Codes
        -- --------------------------------------------------------------------
        div ! id "pane-status-codes" ! class_ "tour-pane" $ do
          div ! class_ "pane-header" $ do
            div ! class_ "pane-route" $ do
              span ! class_ "method-badge get" $ "GET"
              span "/api/tour/status-codes/:code"
            h3 ! class_ "pane-title" $ "Dynamic HTTP Response Status Codes"
            p ! class_ "pane-description" $
              "Scotty allows returning any valid HTTP status code dynamically via S.status and Network.HTTP.Types.Status.mkStatus."

          div ! class_ "studio-work-area" $ do
            div ! class_ "code-window" $ do
              div ! class_ "window-bar" $ do
                div ! class_ "window-dots" $ do
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                span "src/App/Api/Tour.hs"
                span "Scotty 0.30 DSL"
              pre ! class_ "code-snippet" $ do
                fn "S.get" >> " " >> str "\"/api/tour/status-codes/:code\"" >> " " >> kw "$" >> " " >> kw "do" >> "\n"
                "  codeInt " >> kw "<-" >> " " >> fn "S.pathParam" >> " " >> str "\"code\"" >> " " >> kw "::" >> " " >> ty "ActionT" >> " " >> ty "AppM" >> " " >> ty "Int" >> "\n"
                "  " >> kw "let" >> " sc = " >> fn "mkStatus" >> " codeInt " >> str "\"Custom Status\"" >> "\n\n"
                "  " >> fn "S.status" >> " sc\n"
                "  " >> kw "if" >> " codeInt " >> kw "==" >> " " >> num "204" >> "\n"
                "    " >> kw "then" >> " " >> fn "S.raw" >> " " >> str "\"\"" >> "\n"
                "    " >> kw "else" >> " " >> fn "S.json" >> " " >> kw "$" >> " " >> fn "object" >> "\n"
                "      [ " >> str "\"concept\"" >> "     " >> fn ".=" >> " (" >> str "\"Status Codes\"" >> " " >> kw "::" >> " " >> ty "Text" >> ")\n"
                "      , " >> str "\"status_code\"" >> " " >> fn ".=" >> " codeInt\n"
                "      ]"

            div ! class_ "test-panel" $ do
              div ! class_ "control-box" $ do
                span ! class_ "control-box-title" $ "Select Status Code"
                div ! class_ "preset-buttons" $ do
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/status-codes/200"
                         ! customAttribute "hx-target" "#console-status" $ "200 OK"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/status-codes/201"
                         ! customAttribute "hx-target" "#console-status" $ "201 Created"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/status-codes/204"
                         ! customAttribute "hx-target" "#console-status" $ "204 No Content"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/status-codes/400"
                         ! customAttribute "hx-target" "#console-status" $ "400 Bad Request"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/status-codes/404"
                         ! customAttribute "hx-target" "#console-status" $ "404 Not Found"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/status-codes/418"
                         ! customAttribute "hx-target" "#console-status" $ "418 I'm a Teapot"
              div ! class_ "console-box" $ do
                div ! class_ "console-bar" $ do
                  span "SERVER RESPONSE"
                  span "STATUS TEST"
                pre ! id "console-status" ! class_ "console-output" $ "Select a status code to test S.status dispatch..."

        -- --------------------------------------------------------------------
        -- Pane 7: Error Handling & RFC 7807
        -- --------------------------------------------------------------------
        div ! id "pane-error-handling" ! class_ "tour-pane" $ do
          div ! class_ "pane-header" $ do
            div ! class_ "pane-route" $ do
              span ! class_ "method-badge err" $ "ERR"
              span "/api/tour/errors/:type"
            h3 ! class_ "pane-title" $ "Centralized Error Boundaries & RFC 7807"
            p ! class_ "pane-description" $
              "Scotty provides S.defaultHandler to catch unhandled exceptions. In Scotty Starter 2.0, this converts errors into standard RFC 7807 Problem Details (application/problem+json) with titles, status codes, and diagnostics."

          div ! class_ "studio-work-area" $ do
            div ! class_ "code-window" $ do
              div ! class_ "window-bar" $ do
                div ! class_ "window-dots" $ do
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                span "src/App/Middleware/ErrorHandler.hs"
                span "Scotty 0.30 DSL"
              pre ! class_ "code-snippet" $ do
                ty "appErrorHandler" >> " " >> kw "::" >> " " >> ty "ScottyException" >> " " >> kw "->" >> " " >> ty "ActionT" >> " m ()\n"
                ty "appErrorHandler" >> " " >> kw "=" >> " " >> kw "\\case" >> "\n"
                "  " >> ty "QueryParameterNotFound" >> " p " >> kw "->" >> "\n"
                "    " >> fn "rfc7807" >> " " >> fn "status400" >> " " >> str "\"Missing Query Parameter\"" >> " (" >> str "\"Missing: \"" >> " " >> fn "<>" >> " p)\n"
                "  " >> ty "FailedToParseParameter" >> " p " >> kw "->" >> "\n"
                "    " >> fn "rfc7807" >> " " >> fn "status400" >> " " >> str "\"Parameter Parse Failure\"" >> " (" >> str "\"Cannot parse: \"" >> " " >> fn "<>" >> " p)\n"
                "  other " >> kw "->" >> "\n"
                "    " >> fn "rfc7807" >> " " >> fn "status500" >> " " >> str "\"Internal Server Error\"" >> " (" >> fn "T.pack" >> " (" >> fn "show" >> " other))"

            div ! class_ "test-panel" $ do
              div ! class_ "control-box" $ do
                span ! class_ "control-box-title" $ "Trigger Errors Deliberately"
                div ! class_ "preset-buttons" $ do
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/errors/missing-query"
                         ! customAttribute "hx-target" "#console-errors" $ "Trigger Missing Query"
                  button ! class_ "btn-preset"
                         ! customAttribute "hx-get" "/api/tour/errors/bad-int?numeric_field=not_an_int"
                         ! customAttribute "hx-target" "#console-errors" $ "Trigger Bad Int Parse"
              div ! class_ "console-box" $ do
                div ! class_ "console-bar" $ do
                  span "SERVER RESPONSE"
                  span "RFC 7807"
                pre ! id "console-errors" ! class_ "console-output" $ "Trigger an exception to inspect the RFC 7807 Problem Details payload..."

        -- --------------------------------------------------------------------
        -- Pane 8: Redirection
        -- --------------------------------------------------------------------
        div ! id "pane-redirection" ! class_ "tour-pane" $ do
          div ! class_ "pane-header" $ do
            div ! class_ "pane-route" $ do
              span ! class_ "method-badge redir" $ "302"
              span "/api/tour/redirect-to-docs"
            h3 ! class_ "pane-title" $ "HTTP Redirection via S.redirect"
            p ! class_ "pane-description" $
              "Scotty provides S.redirect to issue 302 Found HTTP redirects to internal or external URLs."

          div ! class_ "studio-work-area" $ do
            div ! class_ "code-window" $ do
              div ! class_ "window-bar" $ do
                div ! class_ "window-dots" $ do
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                  span ! class_ "window-dot" $ mempty
                span "src/App/Api/Tour.hs"
                span "Scotty 0.30 DSL"
              pre ! class_ "code-snippet" $ do
                fn "S.get" >> " " >> str "\"/api/tour/redirect-to-docs\"" >> " " >> kw "$" >> " " >> kw "do" >> "\n"
                "  " >> cm "-- Issues HTTP 302 Found with Location: /docs\n"
                "  " >> fn "S.redirect" >> " " >> str "\"/docs\""

            div ! class_ "test-panel" $ do
              div ! class_ "control-box" $ do
                span ! class_ "control-box-title" $ "Execute Redirection"
                div ! class_ "preset-buttons" $ do
                  a ! class_ "btn-primary" ! href "/api/tour/redirect-to-docs" $ "Execute S.redirect to /docs ↗"
              div ! class_ "console-box" $ do
                div ! class_ "console-bar" $ do
                  span "NOTES"
                  span "302 FOUND"
                pre ! class_ "console-output" $ "Clicking the button above navigates to /api/tour/redirect-to-docs, which dispatches S.redirect \"/docs\"."

    -- ------------------------------------------------------------------------
    -- Section 2: Persistent SQLite Database & Reactive Hypermedia
    -- ------------------------------------------------------------------------
    div ! class_ "section-header" $ do
      span ! class_ "section-num" $ "§ 02"
      h2 ! class_ "section-title" $ "Database Persistence & Reactive Hypermedia"
    p ! class_ "section-desc" $
      "Pooled SQLite access (resource-pool) combined with HTMX hypermedia. Real-time search, inline record creation, and optimistic deletion without single-page framework overhead."

    div ! class_ "database-section" $ do
      div ! class_ "db-toolbar" $ do
        -- Real-time Search Input
        input ! type_ "search"
              ! name "q"
              ! class_ "form-input"
              ! placeholder "Search SQLite database in real-time..."
              ! autocomplete "off"
              ! customAttribute "hx-get" "/partials/posts/search"
              ! customAttribute "hx-trigger" "keyup changed delay:150ms, search"
              ! customAttribute "hx-target" "#posts-container"

        -- Inline Create Post Form
        form ! class_ "form-row"
             ! customAttribute "hx-post" "/partials/posts"
             ! customAttribute "hx-target" "#posts-container"
             ! customAttribute "hx-swap" "afterbegin"
             ! customAttribute "hx-on::after-request" "if(event.detail.successful) this.reset()" $ do
          input ! type_ "text"
                ! name "title"
                ! class_ "form-input"
                ! placeholder "New post title..."
                ! customAttribute "required" "true"
          button ! type_ "submit" ! class_ "btn-primary" $ "+ Add Post"
          counterCard 0

      -- Dynamic Posts Container
      div ! id "posts-container" ! class_ "posts-list" $ do
        postsList initialPosts
