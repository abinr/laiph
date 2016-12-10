module PhoenixChannel exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import WebSocket as Socket


type alias Channel =
    { server : String }


type alias ChannelMessage =
    { topic : String
    , event : String
    , body : Encode.Value
    }


init : String -> Channel
init server =
    Channel (server ++ "/socket/websocket")


type Msg
    = Event ( String, String )
    | Error String


join : String -> String -> Channel -> Cmd a
join topic body channel =
    let
        joinEvent =
            ChannelMessage topic "phx_join" (Encode.string body)
    in
        Socket.send channel.server (encodeEvent joinEvent)


send : String -> String -> Channel -> Cmd a
send event chatMsg channel =
    let
        newMsg =
            ChannelMessage "gozp:lobby" event (Encode.string chatMsg)
    in
        Socket.send channel.server (encodeEvent newMsg)


subscriptions : Channel -> Sub Msg
subscriptions channel =
    Socket.listen channel.server event


event : String -> Msg
event rawEvent =
    case decodeEvent (Debug.log "" rawEvent) of
        Ok eventId ->
            Event ( eventId, rawEvent )

        Err error ->
            Error error


encodeEvent : ChannelMessage -> String
encodeEvent { topic, event, body } =
    Encode.object
        [ ( "topic", Encode.string topic )
        , ( "event", Encode.string event )
        , ( "payload", Encode.object [ ( "body", body ) ] )
        , ( "ref", Encode.string "0" )
        ]
        |> Encode.encode 0
        |> Debug.log "channel send"


decodeEvent : String -> Result String String
decodeEvent rawEvent =
    Decode.decodeString decodeEventId rawEvent


decodeEventId : Decode.Decoder String
decodeEventId =
    Decode.at [ "event" ] Decode.string
