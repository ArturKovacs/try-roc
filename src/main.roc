app [main!] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br" }

import pf.Stdout
import pf.File
import Math
import Scene

# imports [ Math.Math.Vec3 ]

image_width = 800
image_height = 600

main! = |_args|
    numbers =
        List.range({ start: At 0, end: Before 5 })
        |> List.map(|value| value * 2)

    dbg numbers

    # dbg final_image

    Stdout.line!("")?

    converted_image = {
        width: image_width,
        height: image_height,
        pixels: final_image
        |> List.join_map(
            |color_vec3|
                r = Num.to_u8(Num.floor(color_vec3.x * 255))
                g = Num.to_u8(Num.floor(color_vec3.y * 255))
                b = Num.to_u8(Num.floor(color_vec3.z * 255))
                [r, g, b],
        ),
    }
    _ =
        when save_bmp!(converted_image, "output.bmp") is
            Err _ -> Err {}
            Ok _ -> Ok {}

    Ok {}

# joined = numbers
#     |> List.map(|n| Num.to_str(n))
#     |> Str.join_with(", ")
#
# Stdout.line!("${joined}")

Image : {
    width : U32,
    height : U32,
    pixels : List U8,
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
        [
            # BMP Header
            [0x42],
            [0x4D], # Signature 'BM'
            to_u8s_le(Num.to_u32(file_size)), # File size
            [0x00],
            [0x00], # Reserved1
            [0x00],
            [0x00], # Reserved2
            to_u8s_le(Num.to_u32(header_size + info_header_size)), # Pixel data offset
        ]
        |> List.join

    info_header =
        [
            # DIB Header (BITMAPINFOHEADER)
            to_u8s_le(Num.to_u32(info_header_size)), # Header size
            to_u8s_le(Num.to_u32(image.width)), # Image width
            to_u8s_le(Num.to_u32(image.height)), # Image height
            [0x01],
            [0x00], # Planes
            [0x18],
            [0x00], # Bits per pixel (24)
            [0x00],
            [0x00],
            [0x00],
            [0x00], # Compression (none)
            to_u8s_le(Num.to_u32(pixel_data_size)), # Image size
            [0x13],
            [0x0B],
            [0x00],
            [0x00], # X pixels per meter (2835)
            [0x13],
            [0x0B],
            [0x00],
            [0x00], # Y pixels per meter (2835)
            [0x00],
            [0x00],
            [0x00],
            [0x00], # Total colors
            [0x00],
            [0x00],
            [0x00],
            [0x00], # Important colors
        ]
        |> List.join

    pixel_data =
        List.range({ start: At 0, end: Before image.height })
        |> List.join_map(
            |y|
                row_start = y * image.width * 3
                row_pixels =
                    List.range({ start: At 0, end: Before image.width })
                    |> List.join_map(
                        |x|
                            pixel_index = row_start + x * 3
                            r = Result.with_default(image.pixels |> List.get(Num.to_u64(pixel_index)), 0)
                            g = Result.with_default(image.pixels |> List.get(Num.to_u64(pixel_index) + 1), 0)
                            b = Result.with_default(image.pixels |> List.get(Num.to_u64(pixel_index) + 2), 0)
                            [b, g, r], # BMP uses BGR format
                    )
                padding_size = row_size - (image.width * 3)
                padding = List.repeat(0x00, Num.to_u64(padding_size))
                List.concat(row_pixels, padding),
        )

    file_bytes = header |> List.concat(info_header) |> List.concat(pixel_data)

    write_result = File.write_bytes!(file_bytes, path)

    when write_result is
        Ok _ -> Ok {}
        Err e ->
            dbg e
            Err {}

final_image : List Math.Vec3
final_image =
    List.range({ start: At 0, end: Before image_height })
    |> List.map(
        |y|
            List.range({ start: At 0, end: Before image_width })
            |> List.map(|x| get_pixel_color_at(x, y)),
    )
    |> List.join

get_closest_hit : Scene.Ray -> Result { dist : F32, position: Math.Vec3, normal: Math.Vec3, sphere : Scene.Sphere } {}
get_closest_hit = |ray|
    result =
        spheres
        |> List.join_map(
            |sphere|
                dist = Scene.intersect(ray, sphere)
                if !Num.is_nan(dist) then
                    position = Math.vec_add(ray.start, Math.vec_scale(ray.dir, dist))
                    normal = Math.vec_normalize(Math.vec_sub(position, sphere.pos))
                    [{ dist, position, normal, sphere }]
                else
                    []
        )
        |> List.walk(Err {}, |acc, curr|
            when acc is
                Err _ -> Ok curr
                Ok best ->
                    if curr.dist < best.dist then
                        Ok curr
                    else
                        Ok best
        )
        # |> List.sort_with(|a, b| Num.compare(a.dist, b.dist)) # closest first
        # |> List.first

    when result is
        Ok hit -> Ok hit
        Err _ -> Err {}

background_color = {
    x: 0.1,
    y: 0.1,
    z: 0.1,
}

get_pixel_color_at : U32, U32 -> Math.Vec3
get_pixel_color_at = |x, y|
    y_flipped = image_height - 1 - y

    camera_ray = get_camera_ray(x, y_flipped)
    scene_hit = get_closest_hit(camera_ray)
    when scene_hit is
        Ok hit ->
            { dist, normal, position, sphere } = hit
            # Simple normal-based coloring
            
            {
                x: (normal.x + 1) * 0.5,
                y: (normal.y + 1) * 0.5,
                z: (normal.z + 1) * 0.5,
            }

        Err _ ->
            background_color


get_camera_ray : U32, U32 -> Scene.Ray
get_camera_ray = |px, py|
    aspect_ratio = Num.to_f32(image_width) / Num.to_f32(image_height)
    fov_rad = cam_fov * 0.5 * Num.pi / 180

    pxf = Num.to_f32(px)
    pyf = Num.to_f32(py)

    # Image plane coordinates in range [-1, 1]
    x = (2 * ((pxf + 0.5) / image_width) - 1) * Num.tan(fov_rad) * aspect_ratio
    y = (1 - 2 * ((pyf + 0.5) / image_height)) * Num.tan(fov_rad)

    # Camera basis
    forward = cam_forward
    right = Math.vec_cross(forward, cam_up)
    up = Math.vec_cross(right, forward)

    # Compute ray direction
    dir_unnorm = Math.vec_add(Math.vec_add(Math.vec_scale(right, x), Math.vec_scale(up, y)), forward)
    dir = Math.vec_normalize(dir_unnorm)

    { start: cam_pos, dir }

cam_pos = {
    x: 0,
    y: 5,
    z: -10,
}
cam_forward = {
    x: 0,
    y: 0,
    z: 1,
}
cam_up = {
    x: 0,
    y: 1,
    z: 0,
}
cam_fov = 90f32

spheres : List Scene.Sphere
spheres = [
    {
        pos: { x: 0, y: -1000, z: 0 },
        radius: 1000,
    },
    {
        pos: { x: 0, y: 2, z: 4 },
        radius: 4,
    }
]

get_frac : Frac a -> Frac a
get_frac = |num|
    num - Num.to_frac(Num.floor(num))

