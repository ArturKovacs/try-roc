
module [
    Vec3, vec_add, vec_sub, vec_scale, vec_div, vec_dot, vec_cross, vec_length, vec_normalize
]

Vec3 : {
    x : F32,
    y : F32,
    z : F32,
}

vec_add : Vec3, Vec3 -> Vec3
vec_add = |a, b|
    {
        x: a.x + b.x,
        y: a.y + b.y,
        z: a.z + b.z,
    }

vec_sub : Vec3, Vec3 -> Vec3
vec_sub = |a, b|
    {
        x: a.x - b.x,
        y: a.y - b.y,
        z: a.z - b.z,
    }

vec_scale : Vec3, F32 -> Vec3
vec_scale = |a, s|
    {
        x: a.x * s,
        y: a.y * s,
        z: a.z * s,
    }

vec_div : Vec3, F32 -> Vec3
vec_div = |a, s|
    {
        x: a.x / s,
        y: a.y / s,
        z: a.z / s,
    }

vec_dot : Vec3, Vec3 -> F32
vec_dot = |a, b|
    a.x * b.x + a.y * b.y + a.z * b.z

vec_cross : Vec3, Vec3 -> Vec3
vec_cross = |a, b|
    {
        x: a.y * b.z - a.z * b.y,
        y: a.z * b.x - a.x * b.z,
        z: a.x * b.y - a.y * b.x
    }

vec_length : Vec3 -> F32
vec_length = |a|
    Num.sqrt(vec_dot(a, a))

vec_normalize : Vec3 -> Vec3
vec_normalize = |a|
    vec_div(a, vec_length(a))

