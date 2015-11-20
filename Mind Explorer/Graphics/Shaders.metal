//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  METAL SHADERS FILE

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

struct VertexIn{
    packed_float3 position;
    packed_float4 colour;
};

struct VertexOut{
    float4 position [[position]];
    float4 colour;
};

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};


// CREATE VERTEX SHADER
vertex VertexOut basic_vertex(
                              const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms&  uniforms    [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {
    
    float4x4 mv_Matrix = uniforms.modelMatrix;
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    VertexIn VertexIn = vertex_array[vid];
    
    VertexOut VertexOut;
    VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);
    //VertexOut.colour = VertexIn.colour;
    float origin[3] = {0.0f, 1.0f, -1.0f};
    float xDist = pow(origin[0] - VertexIn.position[0],2);
    float yDist = pow(origin[1] - VertexIn.position[1],2);
    float zDist = pow(origin[2] - VertexIn.position[2],2);
    float maxDist = sqrt(3 * pow(float(3),2));
    float dist = 0.3 + sqrt(xDist + yDist + zDist) / maxDist;
    
    VertexOut.colour = float4(VertexIn.colour[0] * dist,
                              VertexIn.colour[1] * dist,
                              VertexIn.colour[2] * dist,
                              VertexIn.colour[3]);
    
    return VertexOut;
}

// CREATE FRAGMENT SHADER (to calculate pixel colour between vertices)
fragment half4 basic_fragment(VertexOut interpolated [[stage_in]]) {
    return half4(interpolated.colour[0], interpolated.colour[1], interpolated.colour[2], interpolated.colour[3]);
}