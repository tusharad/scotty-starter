{-# LANGUAGE DeriveAnyClass     #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE DerivingStrategies #-}

module App.Models.Post
    ( Post (..)
    , CreatePostRequest (..)
    ) where

import           Data.Aeson             (FromJSON, ToJSON)
import           Data.Text              (Text)
import           Database.SQLite.Simple (FromRow (..), ToRow (..), field)
import           GHC.Generics           (Generic)

-- | Core Post domain model.
data Post = Post
  { postId    :: !Int
  , postTitle :: !Text
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (FromJSON, ToJSON)

instance FromRow Post where
  fromRow = Post <$> field <*> field

instance ToRow Post where
  toRow (Post i t) = toRow (i, t)

-- | Payload for post creation requests.
newtype CreatePostRequest = CreatePostRequest
  { title :: Text
  } deriving stock (Show, Eq, Generic)
    deriving anyclass (FromJSON, ToJSON)

