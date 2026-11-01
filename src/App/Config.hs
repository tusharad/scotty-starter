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

-- | Application environment.
data Environment
  = Development
  | Production
  | Test
  deriving (Show, Eq, Read)

-- | Application configuration settings.
data Config = Config
  { cfgPort        :: !Int
  , cfgEnv         :: !Environment
  , cfgLogLevel    :: !Text
  , cfgDatabaseUrl :: !(Maybe Text)
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

-- | Load configuration from environment variables with fallback defaults.
loadConfig :: IO Config
loadConfig = do
  portEnv <- lookupEnv "PORT"
  envStr  <- lookupEnv "SCOTTY_ENV" >>= maybe (lookupEnv "ENV") (pure . Just)
  logLvl  <- lookupEnv "LOG_LEVEL"
  dbUrl   <- lookupEnv "DATABASE_URL"

  let port = fromMaybe 3000 (portEnv >>= readMaybe)
      env  = parseEnvironment envStr
      logLevel = maybe "DEBUG" T.pack logLvl
      databaseUrl = fmap T.pack dbUrl

  pure Config
    { cfgPort        = port
    , cfgEnv         = env
    , cfgLogLevel    = logLevel
    , cfgDatabaseUrl = databaseUrl
    }

