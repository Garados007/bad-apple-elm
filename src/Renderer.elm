module Renderer exposing (render)

import BadDecoder exposing (Info)
import Array
import Html exposing (Html)
import Html.Attributes as HA

-- we can move this definition to Main.elm. I have kept it separate because I used it in my test case.
-- Currently I use static styling. Later I will maybe add css capabilities.
render : Info -> Html msg
render { data } =
    Html.div [ HA.class "render", HA.style "display" "flex", HA.style "flex-direction" "column-reverse" ]
    <| List.map
        ( Html.div [ HA.class "row", HA.style "display" "flex" ]
            << List.map
                (\ { r, g, b } ->
                    Html.div 
                        [ HA.class "cell"
                        , HA.style "width"  "8px"
                        , HA.style "height" "8px"
                        , HA.style "background-color"
                            <| "rgb(" ++ String.fromInt r ++ ", "
                            ++ String.fromInt g ++ ", "
                            ++ String.fromInt b ++ ")"
                        ] []
                )
            << Array.toList
        )
    <| Array.toList data