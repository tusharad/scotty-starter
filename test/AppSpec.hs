{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# OPTIONS_GHC -Wno-dodgy-imports #-}

module AppSpec (spec) where

import           App                 (defaultTestApp, makeApp)
import           App.Config          (Config (..), Environment (..),
                                      loadConfig)
import           App.Context         (initContext)
import           Network.HTTP.Types  (hContentType)
import           Network.Wai         (Application)
import           Network.Wai.Test    (simpleHeaders)
import           Test.Hspec
import           Test.Hspec.Wai      hiding (simpleHeaders)
import           Test.Hspec.Wai.JSON

-- | Test instance with Web UI disabled (headless REST API mode).
headlessTestApp :: IO Application
headlessTestApp = do
  cfg <- loadConfig
  let testCfg = cfg
        { cfgEnv          = Test
        , cfgDatabasePath = ":memory:"
        , cfgEnableWebUI  = False
        }
  ctx <- initContext testCfg
  makeApp ctx

spec :: Spec
spec = do
  describe "Full-Stack Application (Web UI Enabled)" $ with defaultTestApp $ do
    describe "Operational Probes" $ do
      it "GET /healthz responds with 200 OK" $ do
        get "/healthz" `shouldRespondWith` 200

      it "GET /readyz responds with 200 OK and database check ok" $ do
        get "/readyz" `shouldRespondWith` [json|{"status": "ready", "checks": {"app": "ok", "database": "ok"}}|]
          { matchStatus = 200 }

    describe "Modern Middleware Pipeline (Security, RequestID, CORS)" $ do
      it "sets OWASP security headers (X-Content-Type-Options, X-Frame-Options)" $ do
        get "/healthz" `shouldRespondWith` 200
          { matchHeaders = [ "X-Content-Type-Options" <:> "nosniff"
                           , "X-Frame-Options" <:> "SAMEORIGIN"
                           ]
          }

      it "attaches X-Request-ID to all responses" $ do
        resp <- get "/healthz"
        liftIO $ lookup "X-Request-ID" (simpleHeaders resp) `shouldSatisfy` (/= Nothing)

      it "propagates client-supplied X-Request-ID" $ do
        request "GET" "/healthz" [("X-Request-ID", "custom-trace-uuid-42")] ""
          `shouldRespondWith` 200
            { matchHeaders = ["X-Request-ID" <:> "custom-trace-uuid-42"] }

      it "attaches CORS headers to /api/* routes" $ do
        get "/api/posts" `shouldRespondWith` 200
          { matchHeaders = ["Access-Control-Allow-Origin" <:> "*"] }

      it "handles CORS OPTIONS preflight requests on /api/*" $ do
        request "OPTIONS" "/api/posts" [("Origin", "http://localhost:3000")] ""
          `shouldRespondWith` 204
            { matchHeaders = [ "Access-Control-Allow-Origin" <:> "*"
                             , "Access-Control-Allow-Methods" <:> "GET, POST, PUT, DELETE, OPTIONS, HEAD"
                             ]
            }

    describe "Static File Serving" $ do
      it "GET /css/style.css serves compiled CSS" $ do
        get "/css/style.css" `shouldRespondWith` 200

      it "GET /css/pure.min.css serves responsive base CSS" $ do
        get "/css/pure.min.css" `shouldRespondWith` 200

      it "GET /css/grids-responsive.min.css serves responsive grid CSS" $ do
        get "/css/grids-responsive.min.css" `shouldRespondWith` 200

      it "GET /js/htmx.min.js serves self-hosted HTMX library" $ do
        get "/js/htmx.min.js" `shouldRespondWith` 200

    describe "HTML & Hypermedia Views" $ do
      it "GET / serves modernized HTML5 shell with HTMX script" $ do
        get "/" `shouldRespondWith` 200

    describe "Swagger UI & OpenAPI 3.0 Documentation (PR #438)" $ do
      it "GET /docs serves Swagger UI HTML" $ do
        get "/docs" `shouldRespondWith` 200

      it "GET /openapi.json serves valid OpenAPI 3.0 specification" $ do
        get "/openapi.json" `shouldRespondWith` 200

    describe "Pedagogical Scotty 0.30 Tour APIs" $ do
      it "GET /api/tour/path-params/:category/:id captures typed path parameters" $ do
        get "/api/tour/path-params/books/42" `shouldRespondWith` 200

      it "GET /api/tour/query-params parses optional query parameters" $ do
        get "/api/tour/query-params?filter=functional&limit=5&active=true" `shouldRespondWith` 200

      it "POST /api/tour/form-params extracts URL-encoded form data" $ do
        request "POST" "/api/tour/form-params" [(hContentType, "application/x-www-form-urlencoded")] "username=tushar&email=tushar@example.com"
          `shouldRespondWith` 201

      it "POST /api/tour/json-body deserializes typed Aeson payload" $ do
        request "POST" "/api/tour/json-body" [(hContentType, "application/json")] "{\"name\":\"Alonzo\",\"role\":\"Logician\",\"skills\":[\"Calculus\"]}"
          `shouldRespondWith` 201

      it "GET /api/tour/headers-and-cookies inspects headers and issues cookies" $ do
        get "/api/tour/headers-and-cookies" `shouldRespondWith` 200

      it "GET /api/tour/status-codes/418 returns custom status code" $ do
        get "/api/tour/status-codes/418" `shouldRespondWith` 418

      it "GET /api/tour/errors/missing-query triggers RFC 7807 problem details" $ do
        get "/api/tour/errors/missing-query" `shouldRespondWith` 400

      it "GET /api/tour/redirect-to-docs redirects client" $ do
        get "/api/tour/redirect-to-docs" `shouldRespondWith` 302

    describe "HTMX Interactive Partials" $ do
      it "GET /partials/posts/search?q=warp returns HTML post card" $ do
        get "/partials/posts/search?q=warp" `shouldRespondWith` 200

      it "POST /partials/posts creates post via form submission" $ do
        request "POST" "/partials/posts" [(hContentType, "application/x-www-form-urlencoded")] "title=Hypermedia+Post"
          `shouldRespondWith` 201

      it "DELETE /partials/posts/:id removes post and returns empty string" $ do
        request "DELETE" "/partials/posts/4" [] ""
          `shouldRespondWith` 200

      it "POST /partials/counter increments click counter and returns updated button" $ do
        post "/partials/counter" "" `shouldRespondWith` 200

    describe "Database-Backed REST API (JSON)" $ do
      it "GET /api/posts returns seeded posts" $ do
        get "/api/posts" `shouldRespondWith` 200

      it "GET /api/posts?q=warp filters posts by title" $ do
        get "/api/posts?q=warp" `shouldRespondWith` [json|[{"postId": 2, "postTitle": "Haskell in Production: Warp & WAI"}]|]
          { matchStatus = 200 }

      it "GET /api/posts/2 responds with post 2" $ do
        get "/api/posts/2" `shouldRespondWith` [json|{"postId": 2, "postTitle": "Haskell in Production: Warp & WAI"}|]
          { matchStatus = 200 }

      it "GET /api/posts/999 responds with 404 Not Found" $ do
        get "/api/posts/999" `shouldRespondWith` 404

      it "POST /api/posts creates new JSON post" $ do
        request "POST" "/api/posts" [(hContentType, "application/json")] "{\"title\": \"API JSON Post\"}"
          `shouldRespondWith` 201

      it "DELETE /api/posts/999 returns 404 for non-existent post" $ do
        request "DELETE" "/api/posts/999" [] ""
          `shouldRespondWith` 404

      it "POST /api/posts with malformed JSON triggers RFC 7807 error handler" $ do
        request "POST" "/api/posts" [(hContentType, "application/json")] "not a valid json"
          `shouldRespondWith` 400

  describe "Headless Microservice Mode (ENABLE_WEB_UI=false)" $ with headlessTestApp $ do
    it "serves core REST endpoints" $ do
      get "/api/posts" `shouldRespondWith` 200

    it "disables HTML views when web UI is unmounted" $ do
      get "/" `shouldRespondWith` 404

    it "disables static assets when web UI is unmounted" $ do
      get "/css/style.css" `shouldRespondWith` 404
