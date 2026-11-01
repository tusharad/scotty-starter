{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}

module AppSpec (spec) where

import           App                 (defaultTestApp)
import           Network.HTTP.Types  (hContentType)
import           Test.Hspec
import           Test.Hspec.Wai
import           Test.Hspec.Wai.JSON

spec :: Spec
spec = with defaultTestApp $ do
  describe "Operational Probes" $ do
    it "GET /healthz responds with 200 OK" $ do
      get "/healthz" `shouldRespondWith` 200

    it "GET /readyz responds with 200 OK and status ready" $ do
      get "/readyz" `shouldRespondWith` [json|{"status": "ready", "checks": {"app": "ok"}}|]
        { matchStatus = 200 }

  describe "HTML Routes" $ do
    it "GET / responds with 200 OK" $ do
      get "/" `shouldRespondWith` 200

    it "GET /login responds with 200 OK" $ do
      get "/login" `shouldRespondWith` 200

  describe "Posts API" $ do
    it "GET /post responds with 200 OK" $ do
      get "/post" `shouldRespondWith` 200

    it "GET /api/posts returns list of posts" $ do
      get "/api/posts" `shouldRespondWith` 200

    it "GET /api/posts?q=warp filters posts by title" $ do
      get "/api/posts?q=warp" `shouldRespondWith` [json|[{"postId": 2, "postTitle": "Haskell in Production: Warp & WAI"}]|]
        { matchStatus = 200 }

    it "GET /api/posts/:id responds with specific post" $ do
      get "/api/posts/1" `shouldRespondWith` [json|{"postId": 1, "postTitle": "Getting Started with Scotty 0.30"}|]
        { matchStatus = 200 }

    it "GET /api/posts/999 responds with 404 Not Found" $ do
      get "/api/posts/999" `shouldRespondWith` 404

    it "POST /api/posts creates a new post" $ do
      request "POST" "/api/posts" [(hContentType, "application/json")] "{\"title\": \"Building with HTMX and Scotty\"}"
        `shouldRespondWith` 201

    it "POST /api/posts with malformed JSON triggers RFC 7807 error handler" $ do
      request "POST" "/api/posts" [(hContentType, "application/json")] "not a valid json"
        `shouldRespondWith` 400
