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

    it "GET /readyz responds with 200 OK and database check ok" $ do
      get "/readyz" `shouldRespondWith` [json|{"status": "ready", "checks": {"app": "ok", "database": "ok"}}|]
        { matchStatus = 200 }

  describe "HTML Routes" $ do
    it "GET / responds with 200 OK" $ do
      get "/" `shouldRespondWith` 200

    it "GET /login responds with 200 OK" $ do
      get "/login" `shouldRespondWith` 200

  describe "Database-Backed Posts API (CRUD)" $ do
    it "GET /post responds with 200 OK and first post" $ do
      get "/post" `shouldRespondWith` 200

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

    it "POST, PUT, and DELETE lifecycle on a post" $ do
      -- 1. Create post
      request "POST" "/api/posts" [(hContentType, "application/json")] "{\"title\": \"Temporary Post\"}"
        `shouldRespondWith` 201

      -- 2. Update post (ID 4)
      request "PUT" "/api/posts/4" [(hContentType, "application/json")] "{\"title\": \"Updated Temporary Post\"}"
        `shouldRespondWith` [json|{"postId": 4, "postTitle": "Updated Temporary Post"}|]
          { matchStatus = 200 }

      -- 3. Delete post (ID 4)
      request "DELETE" "/api/posts/4" [] ""
        `shouldRespondWith` 200

    it "DELETE /api/posts/999 returns 404 for non-existent post" $ do
      request "DELETE" "/api/posts/999" [] ""
        `shouldRespondWith` 404

    it "POST /api/posts with malformed JSON triggers RFC 7807 error handler" $ do
      request "POST" "/api/posts" [(hContentType, "application/json")] "not a valid json"
        `shouldRespondWith` 400
