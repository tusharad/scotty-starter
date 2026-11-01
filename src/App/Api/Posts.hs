{-# LANGUAGE OverloadedStrings #-}

module App.Api.Posts
    ( Post (..)
    , CreatePostRequest (..)
    , postsRoutes
    , postsRouteDocs
    ) where

import           App.Context               (AppM, AppRoute)
import qualified App.Database.Queries      as Q
import           App.Docs                  (RouteInfo (..), defaultRouteDoc,
                                             description, paramDoc,
                                             pathParamDoc, queryParamDoc,
                                             summary, tags)
import           App.Models.Post           (CreatePostRequest (..), Post (..))
import           Control.Monad.IO.Class    (liftIO)
import           Control.Monad.Trans.Class (lift)
import           Control.Monad.Trans.Reader (ask)
import           Data.Text                 (Text)
import           Network.HTTP.Types        (StdMethod (..))
import           Network.HTTP.Types.Status (status200, status201, status404)
import           Web.Scotty.Internal.Types (RoutePattern (..))
import qualified Web.Scotty.Trans          as S

postsRoutes :: AppRoute
postsRoutes = do
  -- GET /api/posts?q=query
  S.get "/api/posts" $ do
    ctx <- lift ask
    mQuery <- S.queryParamMaybe "q" :: S.ActionT AppM (Maybe Text)
    posts <- liftIO $ maybe (Q.listPosts ctx) (Q.searchPosts ctx) mQuery
    S.status status200
    S.json posts

  -- GET /api/posts/:id (Modern pathParam)
  S.get "/api/posts/:id" $ do
    ctx <- lift ask
    pid <- S.pathParam "id" :: S.ActionT AppM Int
    mPost <- liftIO $ Q.getPostById ctx pid
    case mPost of
      Just p -> do
        S.status status200
        S.json p
      Nothing -> do
        S.status status404
        S.json ("Post not found" :: Text)

  -- POST /api/posts (Insert into SQLite)
  S.post "/api/posts" $ do
    ctx <- lift ask
    req <- S.jsonData
    newPost <- liftIO $ Q.createPost ctx (title req)
    S.status status201
    S.json newPost

  -- PUT /api/posts/:id (Update post in SQLite)
  S.put "/api/posts/:id" $ do
    ctx <- lift ask
    pid <- S.pathParam "id" :: S.ActionT AppM Int
    req <- S.jsonData
    updated <- liftIO $ Q.updatePost ctx pid (title req)
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
    deleted <- liftIO $ Q.deletePost ctx pid
    if deleted
      then do
        S.status status200
        S.json ("Post deleted" :: Text)
      else do
        S.status status404
        S.json ("Post not found" :: Text)

-- | Route documentation for Swagger UI / OpenAPI.
postsRouteDocs :: [RouteInfo]
postsRouteDocs =
  [ RouteInfo
      (Just GET)
      (Literal "/api/posts")
      ( summary "List all posts"
      . description "Retrieve posts ordered by newest first, optionally filtering by title."
      . tags ["Posts"]
      . paramDoc (queryParamDoc "q" "Filter posts by title substring" False)
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just GET)
      (Capture "/api/posts/:id")
      ( summary "Get post by ID"
      . description "Retrieve a single post by its integer identifier."
      . tags ["Posts"]
      . paramDoc (pathParamDoc "id" "Post numeric ID")
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just POST)
      (Literal "/api/posts")
      ( summary "Create a new post"
      . description "Create a new post with JSON body: { \"title\": \"...\" }"
      . tags ["Posts"]
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just PUT)
      (Capture "/api/posts/:id")
      ( summary "Update a post"
      . description "Update an existing post title by ID."
      . tags ["Posts"]
      . paramDoc (pathParamDoc "id" "Post numeric ID")
      $ defaultRouteDoc
      )
  , RouteInfo
      (Just DELETE)
      (Capture "/api/posts/:id")
      ( summary "Delete a post"
      . description "Delete an existing post by ID."
      . tags ["Posts"]
      . paramDoc (pathParamDoc "id" "Post numeric ID")
      $ defaultRouteDoc
      )
  ]
