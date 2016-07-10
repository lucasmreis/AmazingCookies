module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import WebSocket
import Scout


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


scoutEventsServer : String
scoutEventsServer =
    "ws://localhost:8083/websocket"



-- MODEL


type alias Model =
    { totalCookies : Int
    , events : List Scout.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model 0 [], Cmd.none )



-- UPDATE


type Msg
    = EventReceived String


maybeUpdateCookies : String -> Model -> Model
maybeUpdateCookies eventString model =
    case Scout.decodeEvent eventString of
        Just ev ->
            case ev.event of
                Scout.Sold n ->
                    { totalCookies = model.totalCookies + n
                    , events = ev :: model.events }

                _ ->
                    { model | events = ev :: model.events }

        Nothing ->
            model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EventReceived eventString ->
            maybeUpdateCookies eventString model ! []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen scoutEventsServer EventReceived



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text ("Cookies sold: " ++ (toString model.totalCookies)) ]
        , div [] (List.map viewEvent model.events)
        ]


viewEvent : Scout.Model -> Html Msg
viewEvent event =
    div [] [ text (Scout.eventToString event) ]
