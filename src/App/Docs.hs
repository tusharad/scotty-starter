{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

{- |
Module      : App.Docs
Copyright   : (c) 2026 Tushar Adhatrao, Scotty contributors
License     : BSD-3-Clause

Automatic OpenAPI 3.0.3 specification and Swagger UI documentation for Scotty,
mirroring the implementation from scotty-web/scotty PR #438.
-}
module App.Docs
    ( -- * Configuration
      DocsConfig(..)
    , defaultDocsConfig
      -- * Route Documentation
    , RouteDoc(..)
    , defaultRouteDoc
    , ParamDoc(..)
    , ParamIn(..)
    , RouteInfo(..)
      -- * RouteDoc Combinators
    , doc
    , summary
    , description
    , tags
    , paramDoc
    , queryParamDoc
    , headerParamDoc
    , pathParamDoc
    , deprecated
    , operationId
      -- * Generation
    , swaggerUiHtml
    , openApiJson
    , patternToOpenApiPathAndParams
      -- * Scotty Routing Integration
    , docsRoutes
    ) where

import           App.Context                (AppRoute)
import           Control.Applicative        ((<|>))
import qualified Data.Aeson                 as A
import           Data.Aeson                 ((.=))
import qualified Data.Aeson.Key             as Key
import qualified Data.ByteString.Lazy.Char8 as LBS8
import qualified Data.Map.Strict            as Map
import           Data.Maybe                 (catMaybes, fromMaybe)
import           Data.Text                  (Text)
import qualified Data.Text                  as T
import qualified Data.Text.Encoding         as TE
import           Network.HTTP.Types         (StdMethod (..))
import           Web.Scotty.Internal.Types  (RoutePattern (..))
import qualified Web.Scotty.Trans           as S

-- | Configuration for automatically generated Swagger UI and OpenAPI documentation.
data DocsConfig = DocsConfig
    { docsPath          :: !Text       -- ^ Path to serve Swagger UI, default: "/docs"
    , openApiPath       :: !Text       -- ^ Path to serve OpenAPI JSON spec, default: "/openapi.json"
    , docsTitle         :: !Text       -- ^ Title displayed in Swagger UI and OpenAPI spec
    , docsVersion       :: !Text       -- ^ API version string
    , docsDescription   :: !(Maybe Text) -- ^ Optional API description
    , docsSwaggerCssUrl :: !Text       -- ^ URL to Swagger UI stylesheet
    , docsSwaggerJsUrl  :: !Text       -- ^ URL to Swagger UI bundle script
    } deriving (Eq, Show)

-- | Default Swagger UI / OpenAPI configuration.
defaultDocsConfig :: DocsConfig
defaultDocsConfig = DocsConfig
    { docsPath          = "/docs"
    , openApiPath       = "/openapi.json"
    , docsTitle         = "Scotty Starter API"
    , docsVersion       = "0.1.0"
    , docsDescription   = Just "Interactive OpenAPI 3.0 documentation for Scotty Starter, showcasing all Scotty capabilities."
    , docsSwaggerCssUrl = "https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css"
    , docsSwaggerJsUrl  = "https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"
    }

-- | OpenAPI parameter location.
data ParamIn = ParamPath | ParamQuery | ParamHeader | ParamCookie
    deriving (Eq, Show)

-- | Documentation for a parameter.
data ParamDoc = ParamDoc
    { pdName        :: !Text
    , pdIn          :: !ParamIn
    , pdRequired    :: !Bool
    , pdDescription :: !(Maybe Text)
    , pdSchemaType  :: !Text -- ^ e.g. "string", "integer", "boolean"
    } deriving (Eq, Show)

-- | Metadata describing a route in OpenAPI / Swagger UI.
data RouteDoc = RouteDoc
    { rdSummary     :: !(Maybe Text)
    , rdDescription :: !(Maybe Text)
    , rdTags        :: ![Text]
    , rdParameters  :: ![ParamDoc]
    , rdDeprecated  :: !Bool
    , rdOperationId :: !(Maybe Text)
    } deriving (Eq, Show)

-- | Default empty route documentation.
defaultRouteDoc :: RouteDoc
defaultRouteDoc = RouteDoc Nothing Nothing [] [] False Nothing

instance Semigroup RouteDoc where
    d1 <> d2 = RouteDoc
        { rdSummary     = rdSummary d2 <|> rdSummary d1
        , rdDescription = rdDescription d2 <|> rdDescription d1
        , rdTags        = rdTags d1 ++ rdTags d2
        , rdParameters  = rdParameters d1 ++ rdParameters d2
        , rdDeprecated  = rdDeprecated d1 || rdDeprecated d2
        , rdOperationId = rdOperationId d2 <|> rdOperationId d1
        }

instance Monoid RouteDoc where
    mempty = defaultRouteDoc

-- | Recorded route info for OpenAPI generation.
data RouteInfo = RouteInfo
    { riMethod  :: !(Maybe StdMethod)
    , riPattern :: !RoutePattern
    , riDoc     :: !RouteDoc
    }

-- | Build a 'RouteDoc' using a composition of combinators starting from 'defaultRouteDoc'.
doc :: (RouteDoc -> RouteDoc) -> RouteDoc
doc f = f defaultRouteDoc

-- | Set the summary of a route.
summary :: Text -> RouteDoc -> RouteDoc
summary s d = d { rdSummary = Just s }

-- | Set the detailed description of a route.
description :: Text -> RouteDoc -> RouteDoc
description desc d = d { rdDescription = Just desc }

-- | Set tags for grouping routes in Swagger UI.
tags :: [Text] -> RouteDoc -> RouteDoc
tags ts d = d { rdTags = ts }

-- | Add a parameter documentation to a route.
paramDoc :: ParamDoc -> RouteDoc -> RouteDoc
paramDoc p d = d { rdParameters = rdParameters d ++ [p] }

-- | Create a query parameter documentation.
queryParamDoc :: Text -> Text -> Bool -> ParamDoc
queryParamDoc name schemaType isRequired =
  ParamDoc name ParamQuery isRequired Nothing schemaType

-- | Create a header parameter documentation.
headerParamDoc :: Text -> ParamDoc
headerParamDoc name = ParamDoc name ParamHeader False Nothing "string"

-- | Create a path parameter documentation.
pathParamDoc :: Text -> Text -> ParamDoc
pathParamDoc name schemaType = ParamDoc name ParamPath True Nothing schemaType

-- | Mark a route as deprecated in the OpenAPI spec.
deprecated :: RouteDoc -> RouteDoc
deprecated d = d { rdDeprecated = True }

-- | Set a unique operation ID for a route.
operationId :: Text -> RouteDoc -> RouteDoc
operationId opId d = d { rdOperationId = Just opId }

cleanPath :: Text -> Text
cleanPath p
    | T.null p = "/"
    | "/" `T.isPrefixOf` p = p
    | otherwise = "/" <> p

-- | Convert a 'RoutePattern' to an OpenAPI path format (e.g. @"/users/:id"@ to @"/users/{id}"@)
patternToOpenApiPathAndParams :: RoutePattern -> (Text, [ParamDoc])
patternToOpenApiPathAndParams = \case
    Capture pat ->
        let segments = T.split (== '/') pat
            processSeg seg
                | Just (':', name) <- T.uncons seg =
                    ("{" <> name <> "}", [pathParamDoc name "string"])
                | otherwise = (seg, [])
            (newSegs, paramsList) = unzip (map processSeg segments)
            rawPath = T.intercalate "/" newSegs
        in (cleanPath rawPath, concat paramsList)
    Literal pat ->
        (cleanPath pat, [])
    Function _ ->
        ("/custom-route", [])

methodToOpenApiText :: StdMethod -> Text
methodToOpenApiText = \case
    GET     -> "get"
    POST    -> "post"
    PUT     -> "put"
    DELETE  -> "delete"
    PATCH   -> "patch"
    OPTIONS -> "options"
    HEAD    -> "head"
    TRACE   -> "trace"
    CONNECT -> "connect"

paramDocToJson :: ParamDoc -> A.Value
paramDocToJson ParamDoc{..} = A.object $ catMaybes
    [ Just ("name" .= pdName)
    , Just ("in" .= paramInToText pdIn)
    , Just ("required" .= pdRequired)
    , fmap ("description" .=) pdDescription
    , Just ("schema" .= A.object [ "type" .= pdSchemaType ])
    ]

paramInToText :: ParamIn -> Text
paramInToText = \case
    ParamPath   -> "path"
    ParamQuery  -> "query"
    ParamHeader -> "header"
    ParamCookie -> "cookie"

-- | Generate an OpenAPI 3.0.3 compliant JSON specification from the registered routes.
openApiJson :: DocsConfig -> [RouteInfo] -> A.Value
openApiJson cfg rDocs =
    let isDocRoute ri =
            let (p, _) = patternToOpenApiPathAndParams (riPattern ri)
            in p == cleanPath (docsPath cfg) || p == cleanPath (openApiPath cfg)
        userRoutes = filter (not . isDocRoute) rDocs

        routeToOps ri =
            let (pathStr, autoParams) = patternToOpenApiPathAndParams (riPattern ri)
                manualParams = rdParameters (riDoc ri)
                manualNames = [ pdName p | p <- manualParams ]
                unshadowedAuto = filter (\p -> pdName p `notElem` manualNames) autoParams
                allParams = unshadowedAuto ++ manualParams

                methods = case riMethod ri of
                    Just m  -> [methodToOpenApiText m]
                    Nothing -> ["get", "post", "put", "delete", "patch"]

                mkOp m =
                    let opSummary = fromMaybe (T.toUpper m <> " " <> pathStr) (rdSummary (riDoc ri))
                        fields = catMaybes
                            [ Just ("summary" .= opSummary)
                            , fmap ("description" .=) (rdDescription (riDoc ri))
                            , if null (rdTags (riDoc ri)) then Nothing else Just ("tags" .= rdTags (riDoc ri))
                            , fmap ("operationId" .=) (rdOperationId (riDoc ri))
                            , if rdDeprecated (riDoc ri) then Just ("deprecated" .= True) else Nothing
                            , if null allParams then Nothing else Just ("parameters" .= map paramDocToJson allParams)
                            , Just ("responses" .= A.object [ "200" .= A.object [ "description" .= ("Successful Response" :: Text) ] ])
                            ]
                    in (pathStr, m, A.object fields)
            in map mkOp methods

        allOps = concatMap routeToOps userRoutes

        grouped = Map.fromListWith Map.union
            [ (p, Map.singleton m op) | (p, m, op) <- allOps ]

        pathsValue = A.object
            [ Key.fromText p .= A.object [ Key.fromText m .= op | (m, op) <- Map.toList methodMap ]
            | (p, methodMap) <- Map.toList grouped
            ]

        infoFields = catMaybes
            [ Just ("title" .= docsTitle cfg)
            , Just ("version" .= docsVersion cfg)
            , fmap ("description" .=) (docsDescription cfg)
            ]
    in A.object
        [ "openapi" .= ("3.0.3" :: Text)
        , "info" .= A.object infoFields
        , "paths" .= pathsValue
        ]

-- | Generate the self-contained HTML page loading Swagger UI 5.
swaggerUiHtml :: DocsConfig -> LBS8.ByteString
swaggerUiHtml DocsConfig{..} =
    LBS8.fromStrict $ TE.encodeUtf8 $ T.concat
        [ "<!DOCTYPE html>\n"
        , "<html lang=\"en\">\n"
        , "<head>\n"
        , "  <meta charset=\"UTF-8\">\n"
        , "  <title>", docsTitle, " - Swagger UI</title>\n"
        , "  <link rel=\"stylesheet\" type=\"text/css\" href=\"", docsSwaggerCssUrl, "\">\n"
        , "  <style>\n"
        , "    html { box-sizing: border-box; overflow-y: scroll; }\n"
        , "    *, *:before, *:after { box-sizing: inherit; }\n"
        , "    body { margin: 0; background: #0f172a; }\n"
        , "    .swagger-ui .topbar { display: none; }\n"
        , "    .swagger-ui { filter: invert(88%) hue-rotate(180deg); }\n"
        , "    .swagger-ui .highlight-code { filter: invert(100%) hue-rotate(180deg); }\n"
        , "  </style>\n"
        , "</head>\n"
        , "<body>\n"
        , "  <div id=\"swagger-ui\"></div>\n"
        , "  <script src=\"", docsSwaggerJsUrl, "\"></script>\n"
        , "  <script>\n"
        , "    window.onload = function() {\n"
        , "      window.ui = SwaggerUIBundle({\n"
        , "        url: '", openApiPath, "',\n"
        , "        dom_id: '#swagger-ui',\n"
        , "        deepLinking: true,\n"
        , "        presets: [\n"
        , "          SwaggerUIBundle.presets.apis,\n"
        , "          SwaggerUIBundle.SwaggerUIStandalonePreset\n"
        , "        ],\n"
        , "        layout: 'BaseLayout'\n"
        , "      });\n"
        , "    };\n"
        , "  </script>\n"
        , "</body>\n"
        , "</html>\n"
        ]

-- | Scotty route definitions serving Swagger UI (/docs) and OpenAPI JSON (/openapi.json).
docsRoutes :: DocsConfig -> [RouteInfo] -> AppRoute
docsRoutes cfg rDocs = do
  S.get (S.literal (T.unpack (cleanPath (docsPath cfg)))) $ do
    S.setHeader "Content-Type" "text/html; charset=utf-8"
    S.raw $ swaggerUiHtml cfg

  S.get (S.literal (T.unpack (cleanPath (openApiPath cfg)))) $ do
    S.setHeader "Content-Type" "application/json; charset=utf-8"
    S.json $ openApiJson cfg rDocs
