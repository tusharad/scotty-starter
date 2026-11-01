{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : App.Api.Tour
Copyright   : (c) 2026 Tushar Adhatrao, Scotty contributors
License     : BSD-3-Clause

Pedagogical Scotty API tour demonstrating every core feature of Scotty 0.30:
typed path parameters, optional query parameters, form parsing, JSON decoding,
headers, cookies, status codes, and error handling.
-}
module App.Api.Tour
    ( tourRoutes
    , tourRouteDocs
    ) where

import           App.Context               (AppM, AppRoute)
import           App.Docs                  (RouteInfo (..), defaultRouteDoc,
                                            description, paramDoc,
                                            pathParamDoc, queryParamDoc,
                                            summary, tags)
import           Data.Aeson                (FromJSON, ToJSON, object, (.=))
import           Data.Text                 (Text)
import qualified Data.Text                 as T
import qualified Data.Text.Lazy            as TL
import           GHC.Generics              (Generic)
import           Network.HTTP.Types        (StdMethod (..), mkStatus, status200,
                                            status201)
import           Web.Scotty.Cookie         (getCookie, setSimpleCookie)
import           Web.Scotty.Internal.Types (RoutePattern (..))
import qualified Web.Scotty.Trans          as S

-- ============================================================================
-- Data Models
-- ============================================================================

data TourPayload = TourPayload
  { name     :: !Text
  , role     :: !Text
  , skills   :: ![Text]
  } deriving (Show, Eq, Generic)

instance ToJSON TourPayload
instance FromJSON TourPayload

-- ============================================================================
-- Route Implementations
-- ============================================================================

tourRoutes :: AppRoute
tourRoutes = do

  -- --------------------------------------------------------------------------
  -- 1. Path Parameters: /api/tour/path-params/:category/:id
  -- --------------------------------------------------------------------------
  S.get "/api/tour/path-params/:category/:id" $ do
    category <- S.pathParam "category" :: S.ActionT AppM Text
    itemId   <- S.pathParam "id"       :: S.ActionT AppM Int
    S.status status200
    S.json $ object
      [ "concept"           .= ("Path Parameters (S.pathParam)" :: Text)
      , "extracted_category" .= category
      , "extracted_id"       .= itemId
      , "haskell_code"      .= ("category <- S.pathParam \"category\"\nitemId <- S.pathParam \"id\" :: ActionT m Int" :: Text)
      , "lesson"            .= ("Scotty captures :category and :id from the URL pattern and automatically parses into typed Haskell values." :: Text)
      ]

  -- --------------------------------------------------------------------------
  -- 2. Query Parameters: /api/tour/query-params
  -- --------------------------------------------------------------------------
  S.get "/api/tour/query-params" $ do
    filterVal  <- S.queryParamMaybe "filter"  :: S.ActionT AppM (Maybe Text)
    limitVal   <- S.queryParamMaybe "limit"   :: S.ActionT AppM (Maybe Int)
    activeVal  <- S.queryParamMaybe "active"  :: S.ActionT AppM (Maybe Bool)
    rawQueries <- S.queryParams
    S.status status200
    S.json $ object
      [ "concept"        .= ("Query Parameters (S.queryParamMaybe & S.queryParams)" :: Text)
      , "filter"         .= filterVal
      , "limit"          .= limitVal
      , "active"         .= activeVal
      , "raw_query_pairs" .= rawQueries
      , "haskell_code"   .= ("filterVal <- S.queryParamMaybe \"filter\"\nlimitVal <- S.queryParamMaybe \"limit\" :: ActionT m (Maybe Int)" :: Text)
      , "lesson"         .= ("Use queryParam for required params (throws ScottyException if absent) and queryParamMaybe for optional params." :: Text)
      ]

  -- --------------------------------------------------------------------------
  -- 3. Form Parameters: POST /api/tour/form-params
  -- --------------------------------------------------------------------------
  S.post "/api/tour/form-params" $ do
    uname <- S.formParam "username" :: S.ActionT AppM Text
    email <- S.formParam "email"    :: S.ActionT AppM Text
    news  <- S.formParamMaybe "newsletter" :: S.ActionT AppM (Maybe Bool)
    S.status status201
    S.json $ object
      [ "concept"    .= ("Form Data Parsing (S.formParam)" :: Text)
      , "username"   .= uname
      , "email"      .= email
      , "newsletter" .= news
      , "haskell_code" .= ("uname <- S.formParam \"username\"\nemail <- S.formParam \"email\"" :: Text)
      , "lesson"     .= ("Handles URL-encoded multipart form body submissions seamlessly." :: Text)
      ]

  -- --------------------------------------------------------------------------
  -- 4. JSON Body: POST /api/tour/json-body
  -- --------------------------------------------------------------------------
  S.post "/api/tour/json-body" $ do
    payload <- S.jsonData :: S.ActionT AppM TourPayload
    S.status status201
    S.json $ object
      [ "concept"        .= ("JSON Request Body Parsing (S.jsonData)" :: Text)
      , "parsed_payload" .= payload
      , "haskell_code"   .= ("payload <- S.jsonData :: ActionT m TourPayload" :: Text)
      , "lesson"         .= ("Any data type with an Aeson FromJSON instance can be deserialized directly from the request stream." :: Text)
      ]

  -- --------------------------------------------------------------------------
  -- 5. Headers & Cookies: /api/tour/headers-and-cookies
  -- --------------------------------------------------------------------------
  S.get "/api/tour/headers-and-cookies" $ do
    userAgent <- S.header "User-Agent"
    authHeader <- S.header "Authorization"
    clientCookie <- getCookie "visited"

    -- Set custom response header and cookie
    S.setHeader "X-Scotty-Powered-By" "Scotty 0.30 (Haskell)"
    setSimpleCookie "visited" "true"

    S.status status200
    S.json $ object
      [ "concept"             .= ("Request Headers & Cookies (S.header & Cookie)" :: Text)
      , "received_user_agent" .= fmap TL.toStrict userAgent
      , "received_auth"       .= fmap TL.toStrict authHeader
      , "received_cookie"     .= clientCookie
      , "headers_set"         .= ("X-Scotty-Powered-By: Scotty 0.30 (Haskell)" :: Text)
      , "cookie_set"          .= ("visited=true" :: Text)
      , "haskell_code"        .= ("ua <- S.header \"User-Agent\"\nS.setHeader \"X-Scotty-Powered-By\" \"Scotty 0.30\"\nsetSimpleCookie \"visited\" \"true\"" :: Text)
      ]

  -- --------------------------------------------------------------------------
  -- 6. Custom HTTP Status Codes: /api/tour/status-codes/:code
  -- --------------------------------------------------------------------------
  S.get "/api/tour/status-codes/:code" $ do
    codeInt <- S.pathParam "code" :: S.ActionT AppM Int
    let sc = mkStatus codeInt "Custom Status"
    S.status sc
    if codeInt == 204
      then S.raw ""
      else S.json $ object
        [ "concept"     .= ("Custom HTTP Status Codes (S.status)" :: Text)
        , "status_code" .= codeInt
        , "haskell_code" .= ("S.status (mkStatus " <> T.pack (show codeInt) <> " \"...\")" :: Text)
        ]

  -- --------------------------------------------------------------------------
  -- 7. Error Handling & RFC 7807: /api/tour/errors/:type
  -- --------------------------------------------------------------------------
  S.get "/api/tour/errors/:type" $ do
    errType <- S.pathParam "type" :: S.ActionT AppM Text
    case errType of
      "missing-query" -> do
        -- Triggers QueryParameterNotFound
        _ <- S.queryParam "non_existent_parameter" :: S.ActionT AppM Text
        S.text "Will not reach here"
      "bad-int" -> do
        -- Triggers FailedToParseParameter
        _ <- S.queryParam "numeric_field" :: S.ActionT AppM Int
        S.text "Will not reach here"
      _ -> do
        S.status status200
        S.json $ object
          [ "concept" .= ("RFC 7807 Error Boundaries" :: Text)
          , "try_one" .= ("/api/tour/errors/missing-query" :: Text)
          , "try_two" .= ("/api/tour/errors/bad-int?numeric_field=not-a-number" :: Text)
          ]

  -- --------------------------------------------------------------------------
  -- 8. Redirect Demo: /api/tour/redirect-to-docs
  -- --------------------------------------------------------------------------
  S.get "/api/tour/redirect-to-docs" $ do
    S.redirect "/docs"

-- ============================================================================
-- OpenAPI Documentation Registry
-- ============================================================================

tourRouteDocs :: [RouteInfo]
tourRouteDocs =
  [ RouteInfo
      (Just GET)
      (Capture "/api/tour/path-params/:category/:id")
      ( summary "Extract typed path parameters"
      . description "Demonstrates capturing URL path variables into typed Haskell variables using S.pathParam."
      . tags ["01: Path Parameters"]
      . paramDoc (pathParamDoc "category" "string")
      . paramDoc (pathParamDoc "id" "integer")
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just GET)
      (Literal "/api/tour/query-params")
      ( summary "Extract and parse query parameters"
      . description "Demonstrates required queryParam, optional queryParamMaybe, and raw queryParams list."
      . tags ["02: Query Parameters"]
      . paramDoc (queryParamDoc "filter" "string" False)
      . paramDoc (queryParamDoc "limit" "integer" False)
      . paramDoc (queryParamDoc "active" "boolean" False)
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just POST)
      (Literal "/api/tour/form-params")
      ( summary "Parse URL-encoded form submissions"
      . description "Demonstrates extracting multipart form fields via S.formParam."
      . tags ["03: Request Bodies & Forms"]
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just POST)
      (Literal "/api/tour/json-body")
      ( summary "Deserialize JSON request bodies"
      . description "Demonstrates typed deserialization using Aeson FromJSON and S.jsonData."
      . tags ["03: Request Bodies & Forms"]
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just GET)
      (Literal "/api/tour/headers-and-cookies")
      ( summary "Read and set HTTP headers and cookies"
      . description "Demonstrates inspecting client headers, reading cookies, setting custom response headers, and setting cookies."
      . tags ["04: Headers & Cookies"]
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just GET)
      (Capture "/api/tour/status-codes/:code")
      ( summary "Return arbitrary HTTP status codes"
      . description "Demonstrates dynamically setting HTTP response statuses like 201 Created, 204 No Content, 418 Teapot."
      . tags ["05: Status Codes & Responses"]
      . paramDoc (pathParamDoc "code" "integer")
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just GET)
      (Capture "/api/tour/errors/:type")
      ( summary "Demonstrate Scotty error handling & RFC 7807"
      . description "Triggers ScottyExceptions (missing query, unparseable parameter) to demonstrate centralized error handlers."
      . tags ["06: Error Handling"]
      . paramDoc (pathParamDoc "type" "string")
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just GET)
      (Literal "/api/tour/redirect-to-docs")
      ( summary "HTTP redirection demo"
      . description "Demonstrates redirecting clients to Swagger UI (/docs) via S.redirect."
      . tags ["05: Status Codes & Responses"]
      $ defaultRouteDoc
      )
  ]
