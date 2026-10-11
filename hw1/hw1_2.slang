import hw1_common;

[shader("compute")]
[numthreads(8, 8, 1)]
void compute_main(uint2 tid: SV_DispatchThreadID,
                  StructuredBuffer<float2> polyline,
                  uniform int num_polyline,
                  uniform bool is_closed,
                  uniform bool use_fill_color,
                  uniform float3 fill_color,
                  uniform bool use_stroke_color,
                  uniform float3 stroke_color,
                  uniform float stroke_width,
                  RWTexture2D<float4> image)
{
    uint width, height;
    image.GetDimensions(width, height);
    if (tid.x >= width || tid.y >= height)
    {
        return;
    }

    image[tid] = float4(1.0);
    float y = height - tid.y - 0.5;
    float x = tid.x + 0.5;
    int winding_num = 0;
    for (int i = 0; i < num_polyline; i++)
    {
        float2 p0 = polyline[i];
        float2 p1 = polyline[(i + 1) % num_polyline];
        if ((p0.y > y) == (p1.y > y))
        {
            continue;
        }
        float t = (y - p0.y) / (p1.y - p0.y);
        float s = -x + p0.x + t * (p1.x - p0.x);
        if (s > x)
        {
            if (p1.y > p0.y)
            {
                winding_num += 1;
            }
            else
            {
                winding_num -= 1;
            }
        }
    }
    if (winding_num != 0)
    {
        if (is_closed)
        {
            image[tid] = float4(fill_color, 1.0);
        }
        else
        {
            image[tid] = float4(stroke_color, 1.0);
        }
    }

    // hint: use % operation. Say we have an array of 5 vector points (v), v(4) is the last point and then we do v(5 % v.size) which goes back to v(0)
}
