import hw1_common;

[shader("compute")]
[numthreads(8, 8, 1)]
void compute_main(uint2 tid: SV_DispatchThreadID,
                  uniform float3 background,
                  uniform int /*samples_per_axis*/, // ignore for now
                  StructuredBuffer<Shape> shapes,
                  uniform int num_shapes,
                  StructuredBuffer<Circle> circles,
                  StructuredBuffer<Polyline> polylines,
                  StructuredBuffer<QuadraticBezier> /*quadratic_beziers*/, // ignore for now
                  StructuredBuffer<float2> points,
                  RWTexture2D<float4> image)
{
    uint width, height;
    image.GetDimensions(width, height);
    if (tid.x >= width || tid.y >= height)
    {
        return;
    }

    image[tid] = float4(background, 1.0);
    float y = height - tid.y - 0.5;
    float x = tid.x + 0.5;
    for (int i = num_shapes - 1; i >= 0; i--)
    {
        float4 color = shapes[i].fill_rgba;
        float4 stroke_color = shapes[i].stroke_rgba;

        if (shapes[i].type == ShapeType::Circle)
        {
            Circle c = circles[shapes[i].index];
            float d = sqrt(pow(c.center.x - x, 2) + pow(c.center.y - y, 2));
            if (shapes[i].use_fill && d <= c.radius)
            {
                image[tid] = float4(color);
            }
            if (shapes[i].use_stroke && abs(d - c.radius) < shapes[i].stroke_width / 2)
            {
                image[tid] = float4(stroke_color);
            }
        }
        else if (shapes[i].type == ShapeType::Polyline)
        {
            Polyline p = polylines[shapes[i].index];
            float2 q = float2(x, y);
            int n = p.pts_end - p.pts_begin;

            if (shapes[i].use_fill)
            {
                int winding_num = 0;
                for (int k = 0; k < n; k++)
                {
                    float2 p0 = points[p.pts_begin + k];
                    float2 p1 = points[p.pts_begin + (k + 1) % n];
                    if ((p0.y > y) == (p1.y > y))
                    {
                        continue;
                    }
                    float t = (y - p0.y) / (p1.y - p0.y);
                    float s = -x + p0.x + t * (p1.x - p0.x);
                    if (s >= 0)
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
                    image[tid] = float4(color);
                }
            }
            if (shapes[i].use_stroke)
            {
                int edge_count;
                if (p.closed)
                {
                    edge_count = n;
                }
                else
                {
                    edge_count = n - 1;
                }
                for (int k = 0; k < edge_count; k++)
                {

                    float2 p0 = points[p.pts_begin + k];
                    float2 p1 = points[p.pts_begin + (k + 1) % n];
                    float segment_len = length(p1 - p0);
                    if (segment_len > 0)
                    {
                        float l = dot(p1 - p0, q - p0) / segment_len;
                        float2 qp = p0 + l * ((p1 - p0) / segment_len);
                        if (l > 0 && l < segment_len && length(q - qp) < shapes[i].stroke_width / 2)
                        {
                            image[tid] = float4(stroke_color);
                        }
                    }
                }
            }
        }
    }
}
