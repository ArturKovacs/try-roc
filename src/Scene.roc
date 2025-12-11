
module [
    Sphere, Ray, intersect
]

import Math

Vec3 : Math.Vec3

Sphere : {
    pos: Vec3,
    radius: F32
}

Ray : {
    start: Vec3,
    dir: Vec3
}

## Returns the distance from ray.start to the intersection point closer to ray.start
##
## Returns `Num.nan_f32`, if no intersection is found 
##
## I just prompted an AI to give me a ray-sphere intersection function 
## and this is what it gave me.
##
## I have very little idea about what this function does geometrically
intersect : Ray, Sphere -> F32
intersect = |ray, sphere|
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
