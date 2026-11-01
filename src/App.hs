{-# LANGUAGE OverloadedStrings #-}

module App
    ( app
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
import           App.Middleware.ErrorHandler          (appErrorHandler)
import           Controllers.Home                     (homeRoutes)
import           Network.Wai                          (Application)
import           Network.Wai.Middleware.RequestLogger (logStdoutDev)
import           Network.Wai.Middleware.Static        (addBase, noDots,
                                                       staticPolicy, (>->))
import qualified Web.Scotty.Trans                     as S

-- | Aggregate documentation metadata for all registered application endpoints.
allRouteDocs :: [RouteInfo]
allRouteDocs = healthRouteDocs ++ postsRouteDocs ++ tourRouteDocs

-- | The core Scotty application specification (middleware + routes).
app :: AppRoute
app = do
  S.defaultHandler appErrorHandler
  S.middleware $ staticPolicy (noDots >-> addBase "static")
  S.middleware logStdoutDev
  homeRoutes
  healthRoutes
  postsRoutes
  tourRoutes
  docsRoutes defaultDocsConfig allRouteDocs

-- | Build a WAI Application using the provided AppContext.
makeApp :: AppContext -> IO Application
makeApp ctx = S.scottyAppT S.defaultOptions (runAppM ctx) app

-- | Build a default WAI Application for testing with in-memory SQLite.
defaultTestApp :: IO Application
defaultTestApp = do
  cfg <- loadConfig
  let testCfg = cfg
        { cfgEnv          = Test
        , cfgDatabasePath = ":memory:"
        }
  ctx <- initContext testCfg
  makeApp ctx

-- | Run the application with a given configuration.
runAppWithConfig :: Config -> IO ()
runAppWithConfig cfg = do
  ctx <- initContext cfg
  S.scottyT (cfgPort cfg) (runAppM ctx) app

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
