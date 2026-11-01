{-# LANGUAGE OverloadedStrings #-}

module App.Middleware.RequestId
    ( requestIdMiddleware
    ) where

import           Data.ByteString          (ByteString)
import qualified Data.ByteString.Char8    as BC
import           Data.IORef               (IORef, atomicModifyIORef', newIORef)
import           Data.Time.Clock.POSIX    (getPOSIXTime)
import           Network.HTTP.Types       (Header)
import           Network.Wai              (Middleware, mapResponseHeaders,
                                           requestHeaders)
import           Numeric                  (showHex)
import           System.IO.Unsafe         (unsafePerformIO)

{-# NOINLINE reqCounter #-}
reqCounter :: IORef Integer
reqCounter = unsafePerformIO (newIORef 1)

-- | Generate a unique correlation request identifier.
generateRequestId :: IO ByteString
generateRequestId = do
  now <- getPOSIXTime
  seqId <- atomicModifyIORef' reqCounter (\c -> (c + 1, c))
  let nanos = round (now * 1_000_000) :: Integer
  let hexStamp = showHex nanos ""
  let hexSeq   = showHex seqId ""
  pure $ BC.pack ("req-" <> hexStamp <> "-" <> hexSeq)

-- | WAI middleware that tracks and sets the X-Request-ID header.
-- Reuses client-provided X-Request-ID if present; generates a new ID otherwise.
requestIdMiddleware :: Middleware
requestIdMiddleware app req respond = do
  let mExisting = lookup "X-Request-ID" (requestHeaders req)
  reqId <- maybe generateRequestId pure mExisting

  let header :: Header
      header = ("X-Request-ID", reqId)

  app req $ \resp ->
    respond (mapResponseHeaders (header :) resp)

