app [main!] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br" }

import pf.Stdout
import pf.File

image_width = 8
image_height = 6

Vec3 : {
    x : F32,
    y : F32,
    z : F32,
}

main! = |_args|
    numbers = List.range({ start: At 0, end: Before 5 })
        |> List.map(|value| value * 2)

    final_image : List Vec3
    final_image = List.range({ start: At 0, end: Before (image_width * image_height) })
        |> List.map(|value| { x: Num.to_f32(value) / 5.0, y: 0.0, z: 0.0 })

    dbg numbers

    dbg final_image

    Stdout.line!("")?

    pixels = final_image
        |> List.join_map(|color_vec3|
            r = Num.to_u8(Num.floor(color_vec3.x * 255))
            g = Num.to_u8(Num.floor(color_vec3.y * 255))
            b = Num.to_u8(Num.floor(color_vec3.z * 255))
            [r, g, b]
        )

    converted_image = {
        width: image_width,
        height: image_height,
        pixels,
    }
    _ = when save_bmp!(converted_image, "output.bmp") is
        Err _ -> Err {}
        Ok _ -> Ok {}

    Ok {}

    # joined = numbers
    #     |> List.map(|n| Num.to_str(n))
    #     |> Str.join_with(", ")
    # 
    # Stdout.line!("${joined}")

Image : {
    width: U32,
    height: U32,
    pixels: List U8
}

## Converts a U32 to a list of 4 U8s in little-endian order
to_u8s_le : U32 -> List U8
to_u8s_le = |value|
    [
        Num.to_u8(Num.bitwise_and(value, 0xFF)),
        Num.to_u8(Num.bitwise_and(Num.shift_right_by(value, 8), 0xFF)),
        Num.to_u8(Num.bitwise_and(Num.shift_right_by(value, 16), 0xFF)),
        Num.to_u8(Num.bitwise_and(Num.shift_right_by(value, 24), 0xFF))
    ]

save_bmp! : Image, Str -> Result {} {}
save_bmp! = |image, path|
    header_size = 14
    info_header_size = 40
    row_size = Num.floor(Num.to_f32(image.width * 3 + 3) / 4) * 4
    pixel_data_size = row_size * image.height
    file_size = header_size + info_header_size + pixel_data_size

    header = 
        [ # BMP Header
            [0x42], [0x4D],                          # Signature 'BM'
            to_u8s_le(Num.to_u32(file_size)), # File size
            [0x00], [0x00],                          # Reserved1
            [0x00], [0x00],                          # Reserved2
            to_u8s_le(Num.to_u32(header_size + info_header_size)) # Pixel data offset
        ]
        |> List.join

    info_header =
        [ # DIB Header (BITMAPINFOHEADER)
            to_u8s_le(Num.to_u32(info_header_size)), # Header size
            to_u8s_le(Num.to_u32(image.width)),      # Image width
            to_u8s_le(Num.to_u32(image.height)),     # Image height
            [0x01], [0x00],                                  # Planes
            [0x18], [0x00],                                  # Bits per pixel (24)
            [0x00], [0x00], [0x00], [0x00],                      # Compression (none)
            to_u8s_le(Num.to_u32(pixel_data_size)),  # Image size
            [0x13], [0x0B], [0x00], [0x00],                      # X pixels per meter (2835)
            [0x13], [0x0B], [0x00], [0x00],                      # Y pixels per meter (2835)
            [0x00], [0x00], [0x00], [0x00],                      # Total colors
            [0x00], [0x00], [0x00], [0x00]                       # Important colors
        ]
        |> List.join

    pixel_data = 
        List.range({ start: At 0, end: Before image.height })
        |> List.join_map(|y|
            row_start = y * image.width * 3
            row_pixels = 
                List.range({ start: At 0, end: Before image.width })
                |> List.join_map(|x|
                    pixel_index = row_start + x * 3
                    r = Result.with_default(image.pixels |> List.get(Num.to_u64(pixel_index)), 0)
                    g = Result.with_default(image.pixels |> List.get(Num.to_u64(pixel_index) + 1), 0)
                    b = Result.with_default(image.pixels |> List.get(Num.to_u64(pixel_index) + 2), 0)
                    [b, g, r] # BMP uses BGR format
                )
            padding_size = row_size - (image.width * 3)
            padding = List.repeat(0x00, Num.to_u64(padding_size))
            List.concat(row_pixels, padding)
        )
    
    file_bytes = header |> List.concat(info_header) |> List.concat(pixel_data)

    write_result = File.write_bytes!(file_bytes, path)

    when write_result is
        Ok _ -> Ok {}
        Err e ->
            dbg e
            Err {}
            



    # {
    #     x: (Num.to_f32(x) / 100) |> get_frac,
    #     y: (Num.to_f32(y) / 100) |> get_frac,
    #     z: 0
    # }
