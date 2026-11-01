{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Api.Posts
    ( Post (..)
    , CreatePostRequest (..)
    , postsRoutes
    ) where

import           App.Context               (AppContext (..), AppM, AppRoute)
import           App.Database              (runDb)
import           Control.Monad.IO.Class    (liftIO)
import           Control.Monad.Trans.Class (lift)
import           Control.Monad.Trans.Reader (ask)
import           Data.Aeson                (FromJSON, ToJSON)
import           Data.Text                 (Text)
import           Database.SQLite.Simple    (FromRow (..), Only (..),
                                            ToRow (..), changes, execute,
                                            field, lastInsertRowId, query,
                                            query_)
import           GHC.Generics              (Generic)
import           Network.HTTP.Types.Status (status200, status201, status404)
import qualified Web.Scotty.Trans          as S

data Post = Post
  { postId    :: !Int
  , postTitle :: !Text
  } deriving (Show, Eq, Generic)

instance ToJSON Post
instance FromJSON Post

instance FromRow Post where
  fromRow = Post <$> field <*> field

instance ToRow Post where
  toRow (Post i t) = toRow (i, t)

data CreatePostRequest = CreatePostRequest
  { title :: !Text
  } deriving (Show, Eq, Generic)

instance ToJSON CreatePostRequest
instance FromJSON CreatePostRequest

postsRoutes :: AppRoute
postsRoutes = do
  -- Legacy backwards-compatible single post route
  S.get "/post" $ do
    ctx <- lift ask
    posts <- liftIO $ runDb (ctxDbPool ctx) $ \conn ->
      query_ conn "SELECT id, title FROM posts ORDER BY id ASC LIMIT 1;" :: IO [Post]
    case posts of
      (p:_) -> S.json p
      []    -> do
        S.status status404
        S.json ("No posts found" :: Text)

  -- GET /api/posts?q=query
  S.get "/api/posts" $ do
    ctx <- lift ask
    mQuery <- S.queryParamMaybe "q" :: S.ActionT AppM (Maybe Text)
    posts <- liftIO $ runDb (ctxDbPool ctx) $ \conn -> case mQuery of
      Just q  -> query conn "SELECT id, title FROM posts WHERE title LIKE ? ORDER BY id ASC;" (Only ("%" <> q <> "%"))
      Nothing -> query_ conn "SELECT id, title FROM posts ORDER BY id ASC;"
    S.status status200
    S.json (posts :: [Post])

  -- GET /api/posts/:id (Modern pathParam)
  S.get "/api/posts/:id" $ do
    ctx <- lift ask
    pid <- S.pathParam "id" :: S.ActionT AppM Int
    posts <- liftIO $ runDb (ctxDbPool ctx) $ \conn ->
      query conn "SELECT id, title FROM posts WHERE id = ? LIMIT 1;" (Only pid) :: IO [Post]
    case posts of
      (p:_) -> do
        S.status status200
        S.json p
      []    -> do
        S.status status404
        S.json ("Post not found" :: Text)

  -- POST /api/posts (Insert into SQLite)
  S.post "/api/posts" $ do
    ctx <- lift ask
    req <- S.jsonData
    newPost <- liftIO $ runDb (ctxDbPool ctx) $ \conn -> do
      execute conn "INSERT INTO posts (title) VALUES (?);" (Only (title req))
      rowId <- lastInsertRowId conn
      pure $ Post (fromIntegral rowId) (title req)
    S.status status201
    S.json newPost

  -- PUT /api/posts/:id (Update post in SQLite)
  S.put "/api/posts/:id" $ do
    ctx <- lift ask
    pid <- S.pathParam "id" :: S.ActionT AppM Int
    req <- S.jsonData
    updated <- liftIO $ runDb (ctxDbPool ctx) $ \conn -> do
      execute conn "UPDATE posts SET title = ? WHERE id = ?;" (title req, pid)
      c <- changes conn
      pure (c > 0)
    if updated
      then do
        S.status status200
        S.json $ Post pid (title req)
      else do
        S.status status404
        S.json ("Post not found" :: Text)

  -- DELETE /api/posts/:id (Delete post from SQLite)
  S.delete "/api/posts/:id" $ do
    ctx <- lift ask
    pid <- S.pathParam "id" :: S.ActionT AppM Int
    deleted <- liftIO $ runDb (ctxDbPool ctx) $ \conn -> do
      execute conn "DELETE FROM posts WHERE id = ?;" (Only pid)
      c <- changes conn
      pure (c > 0)
    if deleted
      then do
        S.status status200
        S.json ("Post deleted" :: Text)
      else do
        S.status status404
        S.json ("Post not found" :: Text)
