{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}

module App.Middleware.ErrorHandler
    ( ProblemDetails (..)
    , appErrorHandler
    ) where

import           Control.Exception            (SomeException, fromException)
import           Control.Monad.Catch          (Handler (..))
import           Control.Monad.IO.Class       (MonadIO)
import           Data.Aeson                   (ToJSON (..), object, (.=))
import           Data.Text                    (Text)
import qualified Data.Text                    as T
import           GHC.Generics                 (Generic)
import           Network.HTTP.Types.Status    (status400, status413, status500)
import           Web.Scotty.Internal.Types    (ActionT, ErrorHandler,
                                               ScottyException (..))
import qualified Web.Scotty.Trans             as S

-- | RFC 7807 Problem Details for HTTP APIs
data ProblemDetails = ProblemDetails
  { problemType   :: !Text
  , problemTitle  :: !Text
  , problemStatus :: !Int
  , problemDetail :: !Text
  } deriving (Show, Generic)

instance ToJSON ProblemDetails where
  toJSON p = object
    [ "type"   .= problemType p
    , "title"  .= problemTitle p
    , "status" .= problemStatus p
    , "detail" .= problemDetail p
    ]

-- | Centralized error handler that returns RFC 7807 JSON responses.
appErrorHandler :: MonadIO m => ErrorHandler m
appErrorHandler = Handler $ \(ex :: SomeException) -> do
  case fromException ex of
    Just scottyEx -> handleScottyException scottyEx
    Nothing       -> handleGenericException ex

handleScottyException :: MonadIO m => ScottyException -> ActionT m ()
handleScottyException ex = case ex of
  PathParameterNotFound param -> do
    S.status status400
    S.json $ ProblemDetails "about:blank" "Bad Request" 400 ("Missing path parameter: " <> param)
  QueryParameterNotFound param -> do
    S.status status400
    S.json $ ProblemDetails "about:blank" "Bad Request" 400 ("Missing query parameter: " <> param)
  FormFieldNotFound param -> do
    S.status status400
    S.json $ ProblemDetails "about:blank" "Bad Request" 400 ("Missing form field: " <> param)
  FailedToParseParameter param val err -> do
    S.status status400
    S.json $ ProblemDetails "about:blank" "Bad Request" 400 ("Failed to parse parameter '" <> param <> "' with value '" <> val <> "': " <> err)
  MalformedJSON _ msg -> do
    S.status status400
    S.json $ ProblemDetails "about:blank" "Bad Request" 400 ("Malformed JSON payload: " <> msg)
  FailedToParseJSON _ msg -> do
    S.status status400
    S.json $ ProblemDetails "about:blank" "Bad Request" 400 ("Failed to decode JSON: " <> msg)
  RequestTooLarge -> do
    S.status status413
    S.json $ ProblemDetails "about:blank" "Payload Too Large" 413 "Request body exceeds configured limit"
  _ -> do
    S.status status500
    S.json $ ProblemDetails "about:blank" "Internal Server Error" 500 (T.pack $ show ex)

handleGenericException :: MonadIO m => SomeException -> ActionT m ()
handleGenericException ex = do
  S.status status500
  S.json $ ProblemDetails "about:blank" "Internal Server Error" 500 (T.pack $ show ex)

