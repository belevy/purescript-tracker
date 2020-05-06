module Tracker
  ( trackLifeCycle, trackLifeCycleFlow
  , trackAction, trackActionFlow
  , trackApiCall, trackApiCallFlow
  , trackException, trackExceptionFlow
  , trackScreen, trackScreenFlow
  , trackContext, trackContextFlow
  , maskCvv, maskVpa, maskCardNumber
  ) where

import Data.Array (last)
import Data.Maybe (fromMaybe)
import Data.String (length, split, take, Pattern(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Foreign (Foreign)
import Prelude (Unit, pure, show, unit, (<<<), (<>), ($), (-))
import Presto.Core.Types.Language.Flow (Flow, doAff)
import Tracker.Labels (Label)
import Tracker.Types (Category, Level, Subcategory)

foreign import getValue :: String -> Foreign -> Foreign
foreign import _trackLifeCycle :: String -> String -> String -> Foreign -> Effect Unit
foreign import _trackAction    :: String -> String -> String -> Foreign -> Effect Unit
foreign import _trackApiCall   :: String -> String -> String -> Int -> Int -> Int -> String -> String -> String -> String -> Effect Unit
foreign import _trackException :: String -> String -> String -> String -> String -> String -> Effect Unit
foreign import _trackScreenWithLabel :: String -> String -> String -> String -> String -> Effect Unit
foreign import _trackContext   :: String -> String -> String -> Foreign -> Effect Unit

-- Interfaces for Effect

-- | trackLifeCycle [Category: Lifecycle], args: subcategory, level, label, key, value
trackLifeCycle :: Subcategory -> Level -> Label -> String -> Foreign -> Effect Unit
trackLifeCycle sub level label key value = _trackLifeCycle (show sub) (show level) (show label) (getValue key value)

-- | trackAction [Category: Action], args:  subcategory, level, label, key, value
trackAction :: Subcategory -> Level -> Label -> String -> Foreign -> Effect Unit
trackAction sub level label key value = _trackAction (show sub) (show level) (show label) (getValue key value)

-- | trackApiCall [Category: Api_call]
-- | args:  subcategory, level, label, start_time, end_time, status_code, response, url, payload, method
trackApiCall :: Subcategory -> Level -> Label -> Int -> Int -> Int -> String -> String -> String -> String -> Effect Unit
trackApiCall sub level label = _trackApiCall (show sub) (show level) (show label)

-- | trackException, args: category, subcategory, level, label, message, stacktrace
trackException :: Category -> Subcategory -> Level -> Label -> String -> String -> Effect Unit
trackException category sub level label = _trackException (show category) (show sub) (show level) (show label)

-- | trackScreen [Category: Screen], args: subcategory, level, label, presentation_type, name
trackScreen :: Subcategory -> Level -> Label -> String -> String -> Effect Unit
trackScreen sub level label = _trackScreenWithLabel (show sub) (show level) (show label)

-- | trackContext [Category: Context], args: subcategory, level, label, value
trackContext :: Subcategory -> Level -> Label -> Foreign -> Effect Unit
trackContext sub level label = _trackContext (show sub) (show level) (show label)

-- Interfaces for Flow
-- | Take same args as their Effect interface

trackLifeCycleFlow :: Subcategory -> Level -> Label -> String -> Foreign -> Flow Unit
trackLifeCycleFlow sub level label key = effectToFlow <<< trackLifeCycle sub level label key

trackActionFlow    :: Subcategory -> Level -> Label -> String -> Foreign -> Flow Unit
trackActionFlow sub level label key = effectToFlow <<< trackAction sub level label key

trackApiCallFlow :: Subcategory -> Level -> Label -> Int -> Int -> Int -> String -> String -> String -> String -> Flow Unit
trackApiCallFlow sub level label startTime endTime statusC response url payload = effectToFlow <<< trackApiCall sub level label startTime endTime statusC response url payload

trackExceptionFlow :: Category -> Subcategory -> Level -> Label -> String -> String -> Flow Unit
trackExceptionFlow category sub level label msg = effectToFlow <<< trackException category sub level label msg

trackScreenFlow :: Subcategory -> Level -> Label -> String -> String -> Flow Unit
trackScreenFlow sub level label pt = effectToFlow <<< trackScreen sub level label pt

trackContextFlow :: Subcategory -> Level -> Label -> Foreign -> Flow Unit
trackContextFlow sub level label = effectToFlow <<< trackContext sub level label

-- Masking Functions

maskCardNumber :: String -> String
maskCardNumber cn = take 6 cn <> getMask (length cn - 6)

maskCvv :: String -> String
maskCvv = getMask <<< length

maskVpa :: String -> String
maskVpa vpa = "@" <> fromMaybe "" (last $ split (Pattern "@") vpa)

-- Util Functions

effectToFlow :: Effect Unit -> Flow Unit
effectToFlow = doAff <<< liftEffect

getMask :: Int -> String
getMask 0 = ""
getMask n = "X" <> getMask (n - 1)

main :: Effect Unit
main = pure unit
