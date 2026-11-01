{-# LANGUAGE OverloadedStrings #-}

module App
    ( app
    , makeApp
    , runApp
    , runAppWithPort
    , runAppWithConfig
    , defaultTestApp
    ) where

import           App.Api.Health                       (healthRoutes)
import           App.Api.Posts                        (postsRoutes)
import           App.Config                           (Config (..),
                                                       Environment (..),
                                                       loadConfig)
import           App.Context                          (AppContext (..),
                                                       AppRoute, initContext,
                                                       runAppM)
import           App.Middleware.ErrorHandler          (appErrorHandler)
import           Controllers.Home                     (home, login)
import           Network.Wai                          (Application)
import           Network.Wai.Middleware.RequestLogger (logStdoutDev)
import           Network.Wai.Middleware.Static        (addBase, noDots,
                                                       staticPolicy, (>->))
import qualified Web.Scotty.Trans                     as S

-- | The core Scotty application specification (middleware + routes).
app :: AppRoute
app = do
  S.defaultHandler appErrorHandler
  S.middleware $ staticPolicy (noDots >-> addBase "static/images")
  S.middleware logStdoutDev
  home
  login
  healthRoutes
  postsRoutes

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
