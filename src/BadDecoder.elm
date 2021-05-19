module BadDecoder exposing
    ( Info
    , decodeFile
    )

-- for file in $(ls *.png); do convert $file -type truecolor -thumbnail 85x64 $(basename $file .png).bmp; done

import Array exposing (Array)
import Bytes.Decode as BD exposing (Decoder)
import Bytes exposing (Endianness(..))
import Task exposing (succeed)
import Bytes exposing (width)

type alias Color =
    { r: Int
    , g: Int
    , b: Int
    }

type alias Info =
    { width: Int
    , height: Int
    , data: Array (Array Color)
    }

array : Int -> Decoder a -> Decoder (Array a)
array length decoder =
    let
        step : Array a -> Decoder (BD.Step (Array a) (Array a))
        step result =
            if Array.length result >= length then
                BD.succeed <| BD.Done result
            else
                BD.map
                    (\x -> BD.Loop <| Array.push x result)
                    decoder
    in BD.loop
        Array.empty
        step

-- this decodes the size of the image (should always be 85x64) and jumps directly to the data block
decodeSize : Decoder (Int, Int)
decodeSize =
    BD.andThen
        (\(offset, x) ->
            BD.map
                (always x)
            <| BD.bytes
            <| offset - 26
        )
    <| BD.andThen
        (\offset ->
            BD.map
                (Tuple.pair offset)
            <| BD.map2
                Tuple.pair
                (BD.unsignedInt32 LE)
                (BD.unsignedInt32 LE)
        )
    <| BD.andThen
        (\x ->
            BD.map
                (always x)
            <| BD.bytes 4
        )
    <| BD.andThen
        (always
            <| BD.unsignedInt32 LE -- bfOffBits
        )
    <| BD.bytes 10

-- This decodes the 32bit color and use only the r, g and b values. We can use only one of them but
-- the keep them separate is easier to detect distortion
decodeColor : Decoder Color
decodeColor =
    BD.map4
        (\b g r _ -> Color r g b)
        BD.unsignedInt8
        BD.unsignedInt8
        BD.unsignedInt8
        BD.unsignedInt8
    

decodeFile : Decoder Info
decodeFile =
    BD.andThen
        (\(width, height) ->
            BD.map
                (Info width height)
            <| array height
            <| array width
            <| decodeColor
        )
    <| decodeSize
