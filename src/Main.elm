module Main exposing (..)

import BadDecoder exposing (..)
import Http
import Html exposing (Html, div, text)
import Html.Attributes as HA
import Browser
import Renderer
import Time exposing (Posix)

type alias Model =
    { now: Posix
    , start: Maybe Posix
    , frame: Maybe (Int, Info)
    , skipped: Int
    , requested: Int
    }

type Msg
    = Received Int (Result Http.Error Info)
    | SetTime Posix

main : Program () Model Msg
main = Browser.element
    { init = \() -> init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

init : (Model, Cmd Msg)
init = Tuple.pair
    { now = Time.millisToPosix 0
    , start = Nothing
    , frame = Nothing
    , skipped = 0
    , requested = 0
    }
    Cmd.none

view : Model -> Html Msg
view model =
    div []
        [ div [] 
            <| List.singleton 
            <| text 
            <| let
                    shown : Int
                    shown = model.frame
                        |> Maybe.map Tuple.first
                        |> Maybe.withDefault 0
                    
                    current : Int
                    current = currentFrame model
                
                in "frame: " ++ String.fromInt shown ++ " / " ++ String.fromInt current
                    ++ " (" ++ String.fromInt (current - shown) ++ " frames behind)"
        , div [] <| List.singleton <| text <| "skipped: " ++ String.fromInt model.skipped
        , case model.frame of
            Just (_, info) ->
                Renderer.render info
            Nothing -> Html.text "loading..."
        , Html.audio
            [ HA.src "bad-apple.mp3"
            , HA.controls True
            , HA.autoplay True
            ] []
        ]
    

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Received index (Ok info) ->
            case model.frame of
                Nothing ->
                    Tuple.pair
                        { model
                        | frame = Just (index, info)
                        }
                        Cmd.none
                Just (old, _) ->
                    if old < index
                    then Tuple.pair
                        { model
                        | frame = Just (index, info)
                        }
                        Cmd.none
                    else Tuple.pair
                        { model
                        | skipped = model.skipped + 1
                        }
                        Cmd.none
        Received _ (Err info) ->
            always (model, Cmd.none)
            <| Debug.log "receive error" info
        SetTime now ->
            let
                newModel : Model
                newModel = 
                    { model
                    | now = now
                    , start = Just <| Maybe.withDefault now model.start
                    }

                nextFrame : Int
                nextFrame = currentFrame newModel
            in Tuple.pair
                { newModel
                | requested = max newModel.requested nextFrame
                }
                <| if newModel.requested >= nextFrame then
                        Cmd.none
                    else Http.get
                        { url = "frames/frame-" ++ String.fromInt nextFrame ++ ".bmp"
                        , expect = Http.expectBytes (Received nextFrame) decodeFile
                        }

currentFrame : Model -> Int
currentFrame model =
    model.start
    |> Maybe.withDefault model.now
    |> (\x -> Time.posixToMillis model.now - Time.posixToMillis x)
    |> (*) 24 -- here you need to insert the original fps of the source video
    |> (\x -> x // 1000)
    |> (+) 1
    |> min 7777 -- here you need to insert the total number of frames

subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 25 SetTime