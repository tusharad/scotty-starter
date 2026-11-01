{-# LANGUAGE OverloadedStrings #-}

module App.Database.Migrations
    ( runMigrations
    ) where

import           Control.Monad          (forM_, when)
import           Data.String            (fromString)
import           Database.SQLite.Simple (Connection, Only (..), execute_,
                                         query_, withTransaction)

data Migration = Migration
  { migVersion :: !Int
  , migName    :: !String
  , migUp      :: ![String]
  , migSeed    :: ![String]
  }

migrations :: [Migration]
migrations =
  [ Migration
      { migVersion = 1
      , migName    = "001_create_posts_table"
      , migUp      =
          [ "CREATE TABLE IF NOT EXISTS posts ("
         ++ "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
         ++ "  title TEXT NOT NULL,"
         ++ "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
         ++ ");"
          ]
      , migSeed    =
          [ "INSERT INTO posts (title) VALUES ('Getting Started with Scotty 0.30');"
          , "INSERT INTO posts (title) VALUES ('Haskell in Production: Warp & WAI');"
          , "INSERT INTO posts (title) VALUES ('Type-Safe Routing and Middleware');"
          ]
      }
  ]

-- | Run all pending migrations in order within a transaction.
runMigrations :: Connection -> IO ()
runMigrations conn = withTransaction conn $ do
  execute_ conn
    "CREATE TABLE IF NOT EXISTS schema_migrations (\
    \  version INTEGER PRIMARY KEY,\
    \  name TEXT NOT NULL,\
    \  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\
    \);"

  appliedRows <- query_ conn "SELECT version FROM schema_migrations ORDER BY version ASC;"
  let appliedVersions = map fromOnly appliedRows :: [Int]

  forM_ migrations $ \mig -> do
    let v = migVersion mig
    when (v `notElem` appliedVersions) $ do
      forM_ (migUp mig) $ \upSql -> execute_ conn (fromString upSql)
      forM_ (migSeed mig) $ \seedSql -> execute_ conn (fromString seedSql)
      execute_ conn (fromString ("INSERT INTO schema_migrations (version, name) VALUES (" ++ show v ++ ", '" ++ migName mig ++ "');"))
