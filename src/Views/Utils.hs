module Views.Utils
    ( blaze
    , pet
    ) where

import           Data.Text                     (Text)
import           Text.Blaze.Html.Renderer.Text (renderHtml)
import           Text.Blaze.Html5              (Html)
import           Text.Blaze.Internal           (preEscapedText)
import           Web.Scotty                    (ActionM, html)

pet :: Text -> Html
pet = preEscapedText

blaze :: Html -> ActionM ()
blaze = html . renderHtml
