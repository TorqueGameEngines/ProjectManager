//-----------------------------------------------------------------------------
// Copyright (c) 2012 GarageGames, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//-----------------------------------------------------------------------------

#ifndef _TORQUE_GLSL_
#define _TORQUE_GLSL_
#line 25

float M_HALFPI_F   = 1.57079632679489661923;
float M_PI_F       = 3.14159265358979323846;
float M_2PI_F      = 6.28318530717958647692;
float M_1OVER_PI_F  = 0.31830988618;

/// Calculate fog based on a start and end positions in worldSpace.
float computeSceneFog(  vec3 startPos,
                        vec3 endPos,
                        float fogDensity,
                        float fogDensityOffset,
                        float fogHeightFalloff )
{      
   float f = length( startPos - endPos ) - fogDensityOffset;
   float h = 1.0 - ( endPos.z * fogHeightFalloff );  
   return exp( -fogDensity * f * h );  
}


/// Calculate fog based on a start and end position and a height.
/// Positions do not need to be in worldSpace but height does.
float computeSceneFog( vec3 startPos,
                       vec3 endPos,
                       float height,
                       float fogDensity,
                       float fogDensityOffset,
                       float fogHeightFalloff )
{
   float f = length( startPos - endPos ) - fogDensityOffset;
   float h = 1.0 - ( height * fogHeightFalloff );
   return exp( -fogDensity * f * h );
}


/// Calculate fog based on a distance, height is not used.
float computeSceneFog( float dist, float fogDensity, float fogDensityOffset )
{
   float f = dist - fogDensityOffset;
   return exp( -fogDensity * f );
}


/// Convert a vec4 uv in viewport space to render target space.
vec2 viewportCoordToRenderTarget( vec4 inCoord, vec4 rtParams )
{   
   vec2 outCoord = inCoord.xy / inCoord.w;
   outCoord = ( outCoord * rtParams.zw ) + rtParams.xy;  
   return outCoord;
}


/// Convert a vec2 uv in viewport space to render target space.
vec2 viewportCoordToRenderTarget( vec2 inCoord, vec4 rtParams )
{   
   vec2 outCoord = ( inCoord * rtParams.zw ) + rtParams.xy;  
   return outCoord;
}


/// Convert a vec4 quaternion into a 3x3 matrix.
mat3x3 quatToMat( vec4 quat )
{
   float xs = quat.x * 2.0;
   float ys = quat.y * 2.0;
   float zs = quat.z * 2.0;

   float wx = quat.w * xs;
   float wy = quat.w * ys;
   float wz = quat.w * zs;
   
   float xx = quat.x * xs;
   float xy = quat.x * ys;
   float xz = quat.x * zs;
   
   float yy = quat.y * ys;
   float yz = quat.y * zs;
   float zz = quat.z * zs;
   
   mat3x3 mat;
   
   mat[0][0] = 1.0 - (yy + zz);
   mat[1][0] = xy - wz;
   mat[2][0] = xz + wy;

   mat[0][1] = xy + wz;
   mat[1][1] = 1.0 - (xx + zz);
   mat[2][1] = yz - wx;

   mat[0][2] = xz - wy;
   mat[1][2] = yz + wx;
   mat[2][2] = 1.0 - (xx + yy);   

   return mat;
}


/// The number of additional substeps we take when refining
/// the results of the offset parallax mapping function below.
///
/// You should turn down the number of steps if your needing
/// more performance out of your parallax surfaces.  Increasing
/// the number doesn't yeild much better results and is rarely
/// worth the additional cost.
///
#define PARALLAX_REFINE_STEPS 3

/// Performs fast parallax offset mapping using 
/// multiple refinement steps.
///
/// @param texMap The texture map whos alpha channel we sample the parallax depth.
/// @param texCoord The incoming texture coordinate for sampling the parallax depth.
/// @param negViewTS The negative view vector in tangent space.
/// @param depthScale The parallax factor used to scale the depth result.
///
vec2 parallaxOffset( sampler2D texMap, vec2 texCoord, vec3 negViewTS, float depthScale )
{
   float depth = texture( texMap, texCoord ).a/(PARALLAX_REFINE_STEPS*2);
   vec2 offset = negViewTS.xy * vec2( depth * depthScale )/vec2(PARALLAX_REFINE_STEPS*2);

   for ( int i=0; i < PARALLAX_REFINE_STEPS; i++ )
   {
      depth = ( depth + texture( texMap, texCoord + offset ).a )/(PARALLAX_REFINE_STEPS*2);
      offset = negViewTS.xy * vec2( depth * depthScale )/vec2(PARALLAX_REFINE_STEPS*2);
   }

   return offset;
}

/// Same as parallaxOffset but for dxtnm where depth is stored in the red channel instead of the alpha
vec2 parallaxOffsetDxtnm(sampler2D texMap, vec2 texCoord, vec3 negViewTS, float depthScale)
{
   float depth = texture(texMap, texCoord).r/(PARALLAX_REFINE_STEPS*2);
   vec2 offset = negViewTS.xy * vec2(depth * depthScale)/vec2(PARALLAX_REFINE_STEPS*2);

   for (int i = 0; i < PARALLAX_REFINE_STEPS; i++)
   {
      depth = (depth + texture(texMap, texCoord + offset).r)/(PARALLAX_REFINE_STEPS*2);
      offset = negViewTS.xy * vec2(depth * depthScale)/vec2(PARALLAX_REFINE_STEPS*2);
   }

   return offset;
}

/// Same as the above but for arrays
vec2 parallaxOffset( sampler2DArray texMap, vec3 texCoord, vec3 negViewTS, float depthScale )
{
   float depth = texture( texMap, texCoord ).a/(PARALLAX_REFINE_STEPS*2);
   vec2 offset = negViewTS.xy * vec2( depth * depthScale )/vec2(PARALLAX_REFINE_STEPS*2);

   for ( int i=0; i < PARALLAX_REFINE_STEPS; i++ )
   {
      depth = ( depth + texture( texMap, texCoord + vec3(offset, 0.0) ).a )/(PARALLAX_REFINE_STEPS*2);
      offset = negViewTS.xy * vec2( depth * depthScale )/vec2(PARALLAX_REFINE_STEPS*2);
   }

   return offset;
}

vec2 parallaxOffsetDxtnm(sampler2DArray texMap, vec3 texCoord, vec3 negViewTS, float depthScale)
{
   float depth = texture(texMap, texCoord).r/(PARALLAX_REFINE_STEPS*2);
   vec2 offset = negViewTS.xy * vec2(depth * depthScale)/vec2(PARALLAX_REFINE_STEPS*2);

   for (int i = 0; i < PARALLAX_REFINE_STEPS; i++)
   {
      depth = (depth + texture(texMap, texCoord + vec3(offset, 0.0)).r)/(PARALLAX_REFINE_STEPS*2);
      offset = negViewTS.xy * vec2(depth * depthScale)/vec2(PARALLAX_REFINE_STEPS*2);
   }

   return offset;
}

/// The maximum value for 10bit per component integer HDR encoding.
const float HDR_RGB10_MAX = 4.0;

/// Encodes an HDR color for storage into a target.
vec3 hdrEncode( vec3 _sample )
{
   #if defined( TORQUE_HDR_RGB10 ) 

      return _sample / HDR_RGB10_MAX;

   #else

      // No encoding.
      return _sample;

   #endif
}

/// Encodes an HDR color for storage into a target.
vec4 hdrEncode( vec4 _sample )
{
   return vec4( hdrEncode( _sample.rgb ), _sample.a );
}

/// Decodes an HDR color from a target.
vec3 hdrDecode( vec3 _sample )
{
   #if defined( TORQUE_HDR_RGB10 )

      return _sample * HDR_RGB10_MAX;

   #else

      // No encoding.
      return _sample;

   #endif
}

/// Decodes an HDR color from a target.
vec4 hdrDecode( vec4 _sample )
{
   return vec4( hdrDecode( _sample.rgb ), _sample.a );
}

/// Returns the luminance for an HDR pixel.
float hdrLuminance( vec3 _sample )
{
   // There are quite a few different ways to
   // calculate luminance from an rgb value.
   //
   // If you want to use a different technique
   // then plug it in here.
   //

   ////////////////////////////////////////////////////////////////////////////
   //
   // Max component luminance.
   //
   //float lum = max( _sample.r, max( _sample.g, _sample.b ) );

   ////////////////////////////////////////////////////////////////////////////
   // The perceptual relative luminance.
   //
   // See http://en.wikipedia.org/wiki/Luminance_(relative)
   //
   const vec3 RELATIVE_LUMINANCE = vec3( 0.2126, 0.7152, 0.0722 );
   float lum = dot( _sample, RELATIVE_LUMINANCE );
  
   ////////////////////////////////////////////////////////////////////////////
   //
   // The average component luminance.
   //
   //const vec3 AVERAGE_LUMINANCE = vec3( 0.3333, 0.3333, 0.3333 );
   //float lum = dot( _sample, AVERAGE_LUMINANCE );

   return lum;
}

#ifdef TORQUE_PIXEL_SHADER
/// Called from the visibility feature to do screen
/// door transparency for fading of objects.
void fizzle(vec2 vpos, float visibility)
{
   // NOTE: The magic values below are what give us 
   // the nice even pattern during the fizzle.
   //
   // These values can be changed to get different 
   // patterns... some better than others.
   //
   // Horizontal Blinds - { vpos.x, 0.916, vpos.y, 0 }
   // Vertical Lines - { vpos.x, 12.9898, vpos.y, 78.233 }
   //
   // I'm sure there are many more patterns here to 
   // discover for different effects.
   
   mat2x2 m = mat2x2( vpos.x, 0.916, vpos.y, 0.350 );
   if( (visibility - fract( determinant( m ) )) < 0 )
      discard;
}
#endif //TORQUE_PIXEL_SHADER

/// Basic assert macro.  If the condition fails, then the shader will output color.
/// @param condition This should be a bvec[2-4].  If any items is false, condition is considered to fail.
/// @param color The color that should be outputted if the condition fails.
/// @note This macro will only work in the void main() method of a pixel shader.
#define assert(condition, color) { if(!any(condition)) { OUT_col = color; return; } }

// Deferred Shading: Material Info Flag Check
bool getFlag(float flags, float num)
{
   float process = round(flags * 255);
   float squareNum = pow(2.0, num);
   return (mod(process, pow(2.0, squareNum)) >= squareNum); 
}

// RGB -> HSL
vec3 rgbToHSL(vec3 col)
{
	float cmax, cmin, h, s, l;
	cmax = max(col.r, max(col.g, col.b));
	cmin = min(col.r, min(col.g, col.b));
	l = min(1.0, (cmax + cmin) / 2.0);

    if (cmax == cmin) {
    h = s = 0.0; /* achromatic */
    }
    else 
	{
        float cdelta = cmax - cmin;
        s = l > 0.5 ? cdelta / (2.0 - cmax - cmin) : cdelta / (cmax + cmin);
        if (cmax == col.r) {
          h = (col.g - col.b) / cdelta + (col.g < col.b ? 6.0 : 0.0);
        }
        else if (cmax == col.g) {
          h = (col.b - col.r) / cdelta + 2.0;
        }
        else {
          h = (col.r - col.b) / cdelta + 4.0;
        }
    }
    h /= 6.0;

	
	return vec3(h,s,l);
}

// HSL -> RGB
vec3 hslToRGB(vec3 hsl)
{
	float nr, ng, nb, chroma, h, s, l;
	h = hsl.r;
	s = hsl.g;
	l = hsl.b;
	
	nr = abs(h * 6.0 - 3.0) - 1.0;
	ng = 2.0 - abs(h * 6.0 - 2.0);
	nb = 2.0 - abs(h * 6.0 - 4.0);
	
	nr = clamp(nr, 0.0, 1.0);
	nb = clamp(nb, 0.0, 1.0);
	ng = clamp(ng, 0.0, 1.0);

	chroma = (1.0 - abs(2.0 * l - 1.0)) * s;
	
	return vec3((nr - 0.5) * chroma + l, (ng - 0.5) * chroma + l, (nb - 0.5) * chroma + l);
}

// Sample in linear space. Decodes gamma.
float toLinear(float col)
{
	if(col < 0.04045)
	{
		return (col < 0.0) ? 0.0 : col * (1.0 / 12.92);
	}
	
	return pow(abs(col + 0.055) * (1.0 / 1.055), 2.4);
}
vec4 toLinear(vec4 tex)
{
   return vec4(toLinear(tex.r),toLinear(tex.g),toLinear(tex.b), tex.a);
}

vec3 toLinear(vec3 tex)
{
   return vec3(toLinear(tex.r),toLinear(tex.g),toLinear(tex.b));
}

// Encodes gamma.
float toGamma(float col)
{
	if(col < 0.0031308)
	{
		return (col < 0.0) ? 0.0 : col * 12.92;
	}
	
	return 1.055 * pow(abs(col), 1.0 / 2.4) - 0.055;
}

vec4 toGamma(vec4 tex)
{
   return vec4(toGamma(tex.r), toGamma(tex.g), toGamma(tex.b), tex.a);
}

vec3 toGamma(vec3 tex)
{
   return vec3(toGamma(tex.r), toGamma(tex.g), toGamma(tex.b));
}

vec3 PBRFresnel(vec3 albedo, vec3 indirect, float metalness, float fresnel)
{
   vec3 diffuseColor = albedo - (albedo * metalness);
   vec3 reflectColor = mix(indirect*albedo, indirect, fresnel);

   return diffuseColor + reflectColor;
}

vec3 simpleFresnel(vec3 diffuseColor, vec3 reflectColor, float metalness, float angle, float bias, float power)
{
   float fresnelTerm = bias + (1.0 - bias) * pow(abs(1.0 - max(angle, 0)), power);

   fresnelTerm *= metalness;

   return mix(diffuseColor, reflectColor, fresnelTerm);
}

//get direction for a cube face
vec3 getCubeDir(int face, vec2 uv)
{
	vec2 debiased = uv * 2.0f - 1.0f;

	vec3 dir = vec3(0);

	switch (face)
	{
		case 0: dir = vec3(1, -debiased.y, -debiased.x); 
			break;

		case 1: dir = vec3(-1, -debiased.y, debiased.x); 
			break;

		case 2: dir = vec3(debiased.x, 1, debiased.y); 
			break;

		case 3: dir = vec3(debiased.x, -1, -debiased.y); 
			break;

		case 4: dir = vec3(debiased.x, -debiased.y, 1); 
			break;

		case 5: dir = vec3(-debiased.x, -debiased.y, -1); 
			break;
	};

	return normalize(dir);
}

#define sqr(a)		((a)*(a))
#endif // _TORQUE_GLSL_
