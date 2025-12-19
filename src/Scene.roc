
module [
    Sphere, Ray, intersect_sphere, HitInfo
]

import Math
import Obj

Vec3 : Math.Vec3

Sphere : {
    pos: Vec3,
    radius: F32
}

Ray : {
    start: Vec3,
    dir: Vec3
}

HitInfo : {
    dist : F32,
    position : Math.Vec3,
    normal : Math.Vec3,
}

## Returns the distance from ray.start to the intersection point closer to ray.start
##
## Returns `Num.nan_f32`, if no intersection is found 
##
## I just prompted an AI to give me a ray-sphere intersection function 
## and this is what it gave me.
##
## I have very little idea about what this function does geometrically
intersect_sphere : Ray, Sphere -> F32
intersect_sphere = |ray, sphere|
    ray_to_sphere = Math.vec_sub(sphere.pos, ray.start)
    tca = Math.vec_dot(ray_to_sphere, ray.dir)

    d2 = Math.vec_dot(ray_to_sphere, ray_to_sphere) - tca * tca
    radius2 = sphere.radius * sphere.radius

    sphere_behind_ray = tca < 0
    ray_misses_sphere = d2 > radius2
    if sphere_behind_ray || ray_misses_sphere then
        Num.nan_f32
    else
        thc = Num.sqrt(radius2 - d2)
        # t0 = tca - thc
        # t1 = tca + thc
        tca - thc

intersect_mesh : Ray, Obj.Mesh -> Result HitInfo [NoHit, OutOfBounds]
intersect_mesh = |ray, mesh|
    # Map faces to hit infos
    hits = mesh.faces
        |> List.map_try(|face|
            v1 = List.get(mesh.vertices, Num.to_u64(face.i1.v))?
            v2 = List.get(mesh.vertices, Num.to_u64(face.i2.v))?
            v3 = List.get(mesh.vertices, Num.to_u64(face.i3.v))?
            # Ray-triangle intersection (Möller–Trumbore algorithm)
            edge1 = Math.vec_sub(v2, v1)
            edge2 = Math.vec_sub(v3, v1)
            h = Math.vec_cross(ray.dir, edge2)
            a = Math.vec_dot(edge1, h)
            if Num.abs(a) < 1e-8 then
                Ok []
            else
                f = 1.0 / a
                s = Math.vec_sub(ray.start, v1)
                u = f * Math.vec_dot(s, h)
                if u < 0.0 || u > 1.0 then
                    Ok []
                else
                    q = Math.vec_cross(s, edge1)
                    v = f * Math.vec_dot(ray.dir, q)
                    if v < 0.0 || u + v > 1.0 then
                        Ok []
                    else
                        t = f * Math.vec_dot(edge2, q)
                        if t > 1e-8 then
                            position = Math.vec_add(ray.start, Math.vec_scale(ray.dir, t))
                            normal = Math.vec_normalize(Math.vec_cross(edge1, edge2))
                            Ok [{ dist: t, position, normal }]
                        else
                            Ok []
        )?
        |> List.join

    # Find closest hit
    closest = hits
        |> List.walk(Err {}, |acc, curr|
            when acc is
                Err _ -> Ok curr
                Ok best ->
                    if curr.dist < best.dist then
                        Ok curr
                    else
                        Ok best
        )
    when closest is
        Ok hit -> Ok hit
        Err _ -> Err NoHit

