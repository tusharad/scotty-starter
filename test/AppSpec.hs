{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}

module AppSpec (spec) where

import           App                 (scottyApp')
import           Test.Hspec
import           Test.Hspec.Wai
import           Test.Hspec.Wai.JSON

spec :: Spec
spec = with scottyApp' $ do
  describe "GET /" $ do
    it "responds with 200 OK and HTML content" $ do
      get "/" `shouldRespondWith` 200

  describe "GET /post" $ do
    it "responds with 200 OK and the expected JSON payload" $ do
      get "/post" `shouldRespondWith` [json|{"postId": 1, "postTitle": "Hello from Scotty 0.30!"}|] { matchStatus = 200 }

  describe "GET /login" $ do
    it "responds with 200 OK" $ do
      get "/login" `shouldRespondWith` 200

  describe "GET /non-existent" $ do
    it "responds with 404 Not Found" $ do
      get "/non-existent" `shouldRespondWith` 404

