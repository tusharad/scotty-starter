module Views.Utils
    ( blaze
    , pet
    ) where

import           Control.Monad.IO.Class        (MonadIO)
import           Data.Text                     (Text)
import           Text.Blaze.Html.Renderer.Text (renderHtml)
import           Text.Blaze.Html5              (Html)
import           Text.Blaze.Internal           (preEscapedText)
import qualified Web.Scotty.Trans              as S

pet :: Text -> Html
pet = preEscapedText

blaze :: MonadIO m => Html -> S.ActionT m ()
blaze = S.html . renderHtml
