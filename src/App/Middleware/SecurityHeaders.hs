{-# LANGUAGE OverloadedStrings #-}

module App.Middleware.SecurityHeaders
    ( securityHeaders
    ) where

import           Network.HTTP.Types (Header)
import           Network.Wai        (Middleware, mapResponseHeaders)

-- | OWASP Recommended HTTP Security Headers.
defaultSecurityHeaders :: [Header]
defaultSecurityHeaders =
  [ ("X-Content-Type-Options", "nosniff")
  , ("X-Frame-Options", "SAMEORIGIN")
  , ("X-XSS-Protection", "1; mode=block")
  , ("Referrer-Policy", "strict-origin-when-cross-origin")
  , ("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
  , ( "Content-Security-Policy"
    , "default-src 'self'; " <>
      "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " <>
      "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " <>
      "img-src 'self' data:; " <>
      "font-src 'self' data:; " <>
      "connect-src 'self';"
    )
  ]

-- | WAI Middleware that appends standard security headers to every response.
securityHeaders :: Middleware
securityHeaders app req respond =
  app req $ \resp ->
    respond (mapResponseHeaders (defaultSecurityHeaders <>) resp)

