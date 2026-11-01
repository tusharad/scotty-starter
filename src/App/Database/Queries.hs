{-# LANGUAGE OverloadedStrings #-}

module App.Database.Queries
    ( listPosts
    , searchPosts
    , getPostById
    , getFirstPost
    , createPost
    , updatePost
    , deletePost
    ) where

import           App.Context            (AppContext (..))
import           App.Database           (runDb)
import           App.Models.Post        (Post (..))
import           Data.Maybe             (listToMaybe)
import           Data.Text              (Text)
import           Database.SQLite.Simple (Only (..), changes, execute,
                                         lastInsertRowId, query, query_)

-- | Retrieve all posts ordered by newest first.
listPosts :: AppContext -> IO [Post]
listPosts ctx = runDb (ctxDbPool ctx) $ \conn ->
  query_ conn "SELECT id, title FROM posts ORDER BY id DESC;"

-- | Retrieve the first post (legacy endpoint support).
getFirstPost :: AppContext -> IO (Maybe Post)
getFirstPost ctx = runDb (ctxDbPool ctx) $ \conn ->
  listToMaybe <$> query_ conn "SELECT id, title FROM posts ORDER BY id ASC LIMIT 1;"

-- | Search posts by title substring case-insensitively.
searchPosts :: AppContext -> Text -> IO [Post]
searchPosts ctx q = runDb (ctxDbPool ctx) $ \conn ->
  query conn "SELECT id, title FROM posts WHERE title LIKE ? ORDER BY id DESC;" (Only ("%" <> q <> "%"))

-- | Find a single post by its primary key ID.
getPostById :: AppContext -> Int -> IO (Maybe Post)
getPostById ctx pid = runDb (ctxDbPool ctx) $ \conn ->
  listToMaybe <$> query conn "SELECT id, title FROM posts WHERE id = ? LIMIT 1;" (Only pid)

-- | Insert a new post record and return the created entity with generated ID.
createPost :: AppContext -> Text -> IO Post
createPost ctx titleText = runDb (ctxDbPool ctx) $ \conn -> do
  execute conn "INSERT INTO posts (title) VALUES (?);" (Only titleText)
  newId <- lastInsertRowId conn
  pure (Post (fromIntegral newId) titleText)

-- | Update the title of an existing post record.
updatePost :: AppContext -> Int -> Text -> IO Bool
updatePost ctx pid newTitle = runDb (ctxDbPool ctx) $ \conn -> do
  execute conn "UPDATE posts SET title = ? WHERE id = ?;" (newTitle, pid)
  (> 0) <$> changes conn

-- | Delete a post record by its ID, returning True if a record was removed.
deletePost :: AppContext -> Int -> IO Bool
deletePost ctx pid = runDb (ctxDbPool ctx) $ \conn -> do
  execute conn "DELETE FROM posts WHERE id = ?;" (Only pid)
  (> 0) <$> changes conn
