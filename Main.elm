module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import PhoenixChannel as Channel
import Json.Decode as Decode


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { channel : Channel.Channel
    , width : String
    , height : String
    , cells : List (List Bool)
    , error : String
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            Model (Channel.init "ws://localhost:8015")
                ""
                ""
                []
                ""
    in
        ( model, Channel.join "life:game" "" model.channel )


type Msg
    = NoOp
    | Board String
    | Error String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "update" msg of
        NoOp ->
            ( model, Cmd.none )

        Board raw ->
            case Decode.decodeString decodeCells raw of
                Ok cells_ ->
                    ( { model | cells = cells_ }, Cmd.none )

                Err error ->
                    ( { model | error = error }, Cmd.none )

        Error error ->
            ( { model | error = error }, Cmd.none )


decodeCells : Decode.Decoder (List (List Bool))
decodeCells =
    Decode.at [ "payload", "cells" ] (Decode.list (Decode.list Decode.bool))


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map routeEvent (Channel.subscriptions model.channel)


routeEvent : Channel.Msg -> Msg
routeEvent chMsg =
    case chMsg of
        Channel.Event ( id, raw ) ->
            case id of
                "board" ->
                    Board raw

                _ ->
                    NoOp

        Channel.Error error ->
            Error error


view : Model -> Html Msg
view model =
    div [ id "board" ] (List.map cellRow model.cells)


cellRow : List Bool -> Html Msg
cellRow row =
    div [ class "cellRow" ] (List.map cellView row)


cellView : Bool -> Html Msg
cellView isAlive =
    div
        [ classList
            [ ( "cell", True )
            , ( "live", isAlive )
            , ( "dead", not isAlive )
            ]
        ]
        []
