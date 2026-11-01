{-# LANGUAGE OverloadedStrings #-}

module App.Middleware.Cors
    ( corsMiddleware
    ) where

import           Data.ByteString          (ByteString)
import qualified Data.ByteString.Char8    as BC
import           Data.Text                (Text)
import qualified Data.Text.Encoding       as TE
import           Network.HTTP.Types       (Header, methodOptions, status204)
import           Network.Wai              (Middleware, mapResponseHeaders,
                                           rawPathInfo, requestHeaders,
                                           requestMethod, responseLBS)

-- | Configurable CORS middleware supporting preflight OPTIONS requests.
corsMiddleware :: [Text] -> Middleware
corsMiddleware allowedOrigins app req respond
  | requestMethod req == methodOptions && isApiRequest =
      respond (responseLBS status204 (corsHeaders <> [("Content-Length", "0")]) "")
  | isApiRequest =
      app req $ \resp ->
        respond (mapResponseHeaders (corsHeaders <>) resp)
  | otherwise =
      app req respond
  where
    isApiRequest = "/api/" `BC.isPrefixOf` rawPathInfo req

    originHeader = lookup "Origin" (requestHeaders req)

    effectiveOrigin :: ByteString
    effectiveOrigin = case allowedOrigins of
      ["*"] -> "*"
      _     -> case originHeader of
        Just o  | TE.decodeUtf8With (\_ _ -> Just ' ') o `elem` allowedOrigins -> o
        _       -> "*"

    corsHeaders :: [Header]
    corsHeaders =
      [ ("Access-Control-Allow-Origin", effectiveOrigin)
      , ("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, HEAD")
      , ("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Request-ID, Accept, Cookie, HX-Request, HX-Target, HX-Current-URL")
      , ("Access-Control-Max-Age", "86400")
      ]

