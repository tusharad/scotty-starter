{-# LANGUAGE OverloadedStrings #-}

module App.Config
    ( Environment (..)
    , Config (..)
    , loadConfig
    ) where

import           Data.Maybe         (fromMaybe)
import           Data.Text          (Text)
import qualified Data.Text          as T
import           System.Environment (lookupEnv)
import           Text.Read          (readMaybe)

-- | Application execution environment.
data Environment
  = Development
  | Production
  | Test
  deriving (Show, Eq, Read)

-- | Strongly-typed application configuration loaded from environment.
data Config = Config
  { cfgPort         :: !Int
  , cfgEnv          :: !Environment
  , cfgLogLevel     :: !Text
  , cfgDatabasePath :: !FilePath
  , cfgDatabaseUrl  :: !(Maybe Text)
  , cfgEnableWebUI  :: !Bool
  , cfgCorsOrigins  :: ![Text]
  } deriving (Show, Eq)

-- | Parse environment name safely from text.
parseEnvironment :: Maybe String -> Environment
parseEnvironment (Just "production")  = Production
parseEnvironment (Just "prod")        = Production
parseEnvironment (Just "test")        = Test
parseEnvironment (Just "development") = Development
parseEnvironment (Just "dev")         = Development
parseEnvironment (Just str)           = fromMaybe Development (readMaybe str)
parseEnvironment Nothing              = Development

-- | Parse boolean flag from environment variable string.
parseBool :: Maybe String -> Bool -> Bool
parseBool (Just "false") _ = False
parseBool (Just "0")     _ = False
parseBool (Just "off")   _ = False
parseBool (Just "no")    _ = False
parseBool (Just "true")  _ = True
parseBool (Just "1")     _ = True
parseBool (Just "on")    _ = True
parseBool (Just "yes")   _ = True
parseBool _              d = d

-- | Load configuration from environment variables with sensible defaults.
loadConfig :: IO Config
loadConfig = do
  portEnv    <- lookupEnv "PORT"
  envStr     <- lookupEnv "SCOTTY_ENV" >>= maybe (lookupEnv "ENV") (pure . Just)
  logLvl     <- lookupEnv "LOG_LEVEL"
  dbPath     <- lookupEnv "DATABASE_PATH"
  dbUrl      <- lookupEnv "DATABASE_URL"
  enableWeb  <- lookupEnv "ENABLE_WEB_UI"
  corsEnv    <- lookupEnv "CORS_ORIGINS"

  let port = fromMaybe 3000 (portEnv >>= readMaybe)
      env  = parseEnvironment envStr
      logLevel = maybe "INFO" T.pack logLvl
      databasePath = case dbPath of
        Just p  -> p
        Nothing -> if env == Test then ":memory:" else "scotty.db"
      databaseUrl = fmap T.pack dbUrl
      webUiEnabled = parseBool enableWeb True
      corsOrigins = case corsEnv of
        Just s  -> map T.strip (T.splitOn "," (T.pack s))
        Nothing -> ["*"]

  pure Config
    { cfgPort         = port
    , cfgEnv          = env
    , cfgLogLevel     = logLevel
    , cfgDatabasePath = databasePath
    , cfgDatabaseUrl  = databaseUrl
    , cfgEnableWebUI  = webUiEnabled
    , cfgCorsOrigins  = corsOrigins
    }
