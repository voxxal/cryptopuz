port module Effect exposing
    ( Effect, none, batch
    , fromCmd
    , pushRoute, replaceRoute, loadExternalUrl
    , map, toCmd
    , save, confetti
    )

{-|

@docs Effect, none, batch
@docs fromCmd
@docs pushRoute, replaceRoute, loadExternalUrl

@docs map, toCmd

-}

import Browser.Navigation
import Dict exposing (Dict)
import Json.Encode as E
import Route exposing (Route)
import Route.Path
import Route.Query
import Task
import Url exposing (Url)


type Effect msg
    = None
    | Batch (List (Effect msg))
    | Cmd (Cmd msg)
    | PushUrl String
    | ReplaceUrl String
    | LoadExternalUrl String
    | SaveToLocalStorage { key : String, value : E.Value }
    | Confetti


none : Effect msg
none =
    None


batch : List (Effect msg) -> Effect msg
batch =
    Batch


fromCmd : Cmd msg -> Effect msg
fromCmd =
    Cmd


pushRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
pushRoute route =
    PushUrl (Route.toString route)


replaceRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
replaceRoute route =
    ReplaceUrl (Route.toString route)


loadExternalUrl : String -> Effect msg
loadExternalUrl =
    LoadExternalUrl



-- LOCAL STORAGE


port saveToLocalStorage : { key : String, value : E.Value } -> Cmd msg


save : String -> E.Value -> Effect msg
save key value =
    SaveToLocalStorage { key = key, value = value }



-- CONFETTI


port launchConfetti : () -> Cmd msg


confetti : Effect msg
confetti =
    Confetti



-- TRANSFORMING EFFECTS


map : (msg1 -> msg2) -> Effect msg1 -> Effect msg2
map fn effect =
    case effect of
        None ->
            None

        Batch list ->
            Batch (List.map (map fn) list)

        Cmd cmd ->
            Cmd (Cmd.map fn cmd)

        PushUrl url ->
            PushUrl url

        ReplaceUrl url ->
            ReplaceUrl url

        LoadExternalUrl url ->
            LoadExternalUrl url

        SaveToLocalStorage options ->
            SaveToLocalStorage options

        Confetti ->
            Confetti


{-| ( Used by Elm Land internally )
-}
toCmd :
    { key : Browser.Navigation.Key
    , fromSharedMsg : sharedMsg -> mainMsg
    , fromPageMsg : msg -> mainMsg
    }
    -> Effect msg
    -> Cmd mainMsg
toCmd options effect =
    case effect of
        None ->
            Cmd.none

        Cmd cmd ->
            Cmd.map options.fromPageMsg cmd

        Batch list ->
            Cmd.batch (List.map (toCmd options) list)

        PushUrl url ->
            Browser.Navigation.pushUrl options.key url

        ReplaceUrl url ->
            Browser.Navigation.replaceUrl options.key url

        LoadExternalUrl url ->
            Browser.Navigation.load url

        SaveToLocalStorage keyValueRecord ->
            saveToLocalStorage keyValueRecord

        Confetti ->
            launchConfetti ()
