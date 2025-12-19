module [load_obj!, Mesh, FaceIndices, FaceIndex]

import pf.File
import pf.Path
import pf.InternalIOErr

import Math

# Indices for a single vertex in a face
# v : vertex index (starting at 0)
# n : normal index (starting at 0)
FaceIndex : {
    v : U32,
    n: U32
}

FaceIndices : {
    i1 : FaceIndex,
    i2 : FaceIndex,
    i3 : FaceIndex,
}

Mesh : {
    vertices : List Math.Vec3,
    faces : List FaceIndices,
}


ParsedLine : [Position Math.Vec3, Indices FaceIndices]

parse_face_index : Str -> Result FaceIndex [OutOfBounds, InvalidNumStr]
parse_face_index = |token|
    parts = Str.split_on(token, "/")
    v_index = Str.to_u32( Str.trim( List.get(parts, 0)? ) )?
    n_index = Str.to_u32( Str.trim( List.get(parts, 2)? ) )?
    Ok { v: v_index - 1, n: n_index - 1 }

load_obj! : Str => Result Mesh [OutOfBounds, InvalidNumStr, FileReadErr Path.Path InternalIOErr.IOErr, FileReadUtf8Err Path.Path _]
load_obj! = |file_path|
    obj_contents = File.read_utf8!(file_path)?
    lines = Str.split_on(obj_contents, "\n")
    parsed_lines : List ParsedLine
    parsed_lines = lines 
        |> List.keep_oks(|line|
            tokens = Str.split_on(line, " ") |> List.keep_if(|t| Str.trim(t) != "")
            first = List.first(tokens)?
            when Str.trim(first) is
                "v" ->
                    x = Str.to_f32( Str.trim(tokens |> List.get(1)?) )?
                    y = Str.to_f32( Str.trim(tokens |> List.get(2)?) )?
                    z = Str.to_f32( Str.trim(tokens |> List.get(3)?) )?
                    Ok (Position { x, y, z })
                "f" ->
                    index1 = parse_face_index( Str.trim( List.get(tokens, 1)? ) )?
                    index2 = parse_face_index( Str.trim( List.get(tokens, 2)? ) )?
                    index3 = parse_face_index( Str.trim( List.get(tokens, 3)? ) )?
                    Ok (Indices { 
                        i1: index1, 
                        i2: index2, 
                        i3: index3
                    })
                _ ->
                    Err UnexpectedSpecifier
        )
    vertices = parsed_lines
        |> List.keep_oks(|line|
            when line is
                Position p -> Ok p
                _ -> Err {}
        )
    faces = parsed_lines
        |> List.keep_oks(|line|
            when line is
                Indices i -> Ok i
                _ -> Err {}
        )
    Ok { vertices, faces }


