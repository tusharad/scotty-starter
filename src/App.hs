{-# LANGUAGE OverloadedStrings #-}

module App
    ( app
    , appWithConfig
    , apiRoutes
    , webUiRoutes
    , makeApp
    , runApp
    , runAppWithPort
    , runAppWithConfig
    , defaultTestApp
    , allRouteDocs
    ) where

import           App.Api.Health                       (healthRouteDocs,
                                                       healthRoutes)
import           App.Api.Posts                        (postsRouteDocs,
                                                       postsRoutes)
import           App.Api.Tour                         (tourRouteDocs,
                                                       tourRoutes)
import           App.Config                           (Config (..),
                                                       Environment (..),
                                                       loadConfig)
import           App.Context                          (AppContext (..),
                                                       AppRoute, initContext,
                                                       runAppM)
import           App.Docs                             (RouteInfo,
                                                       defaultDocsConfig,
                                                       docsRoutes)
import           App.Middleware.Cors                  (corsMiddleware)
import           App.Middleware.ErrorHandler          (appErrorHandler)
import           App.Middleware.RequestId             (requestIdMiddleware)
import           App.Middleware.SecurityHeaders       (securityHeaders)
import           Control.Monad                        (when)
import           Controllers.Home                     (homeRoutes)
import           Network.Wai                          (Application)
import           Network.Wai.Middleware.RequestLogger (logStdoutDev)
import           Network.Wai.Middleware.Static        (addBase, noDots,
                                                       staticPolicy, (>->))
import qualified Web.Scotty.Trans                     as S

-- | Aggregate documentation metadata for all registered application endpoints.
allRouteDocs :: [RouteInfo]
allRouteDocs = healthRouteDocs ++ postsRouteDocs ++ tourRouteDocs

-- | Core REST API routes and OpenAPI documentation.
-- Completely headless and decoupled from any frontend or template engine.
apiRoutes :: AppRoute
apiRoutes = do
  healthRoutes
  postsRoutes
  tourRoutes
  docsRoutes defaultDocsConfig allRouteDocs

-- | Hypermedia presentation layer (HTMX + Blaze HTML5).
-- Mounts static assets and server-rendered HTML partials.
webUiRoutes :: AppRoute
webUiRoutes = do
  S.middleware $ staticPolicy (noDots >-> addBase "static")
  homeRoutes

-- | Build the application routing tree and middleware pipeline based on configuration.
appWithConfig :: Config -> AppRoute
appWithConfig cfg = do
  -- 1. Error boundary
  S.defaultHandler appErrorHandler

  -- 2. OWASP Security Headers (nosniff, SAMEORIGIN, CSP, etc.)
  S.middleware securityHeaders

  -- 3. Distributed tracing correlation ID
  S.middleware requestIdMiddleware

  -- 4. Cross-Origin Resource Sharing (CORS)
  S.middleware (corsMiddleware (cfgCorsOrigins cfg))

  -- 5. Request logging
  S.middleware logStdoutDev

  -- 6. Core headless REST API
  apiRoutes

  -- 7. Optional Hypermedia Web UI (enabled via ENABLE_WEB_UI=true)
  when (cfgEnableWebUI cfg) webUiRoutes

-- | Default application route specification for backward compatibility.
app :: AppRoute
app = do
  S.defaultHandler appErrorHandler
  S.middleware securityHeaders
  S.middleware requestIdMiddleware
  S.middleware (corsMiddleware ["*"])
  S.middleware logStdoutDev
  apiRoutes
  webUiRoutes

-- | Build a WAI Application using the provided AppContext.
makeApp :: AppContext -> IO Application
makeApp ctx = S.scottyAppT S.defaultOptions (runAppM ctx) (appWithConfig (ctxConfig ctx))

-- | Build a default WAI Application for testing with in-memory SQLite.
defaultTestApp :: IO Application
defaultTestApp = do
  cfg <- loadConfig
  let testCfg = cfg
        { cfgEnv          = Test
        , cfgDatabasePath = ":memory:"
        , cfgEnableWebUI  = True
        }
  ctx <- initContext testCfg
  makeApp ctx

-- | Run the application with a given configuration.
runAppWithConfig :: Config -> IO ()
runAppWithConfig cfg = do
  ctx <- initContext cfg
  S.scottyT (cfgPort cfg) (runAppM ctx) (appWithConfig cfg)

-- | Run the application with an explicit port override.
runAppWithPort :: Int -> IO ()
runAppWithPort port = do
  cfg <- loadConfig
  runAppWithConfig cfg { cfgPort = port }

-- | Run the application by loading environment configuration.
runApp :: IO ()
runApp = do
  cfg <- loadConfig
  runAppWithConfig cfg
