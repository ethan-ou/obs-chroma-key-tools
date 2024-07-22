# OBS Chroma Key Tools

A bunch of shaders to get better results from chroma keys in OBS. This includes:

- `chroma-key`: an all-inclusive chroma keyer with edge blur, matte refinement and despill based on color difference keyers such as the famous IBK keyer and Fusion's Delta Keyer.
- `despill`: reduce green, blue or any other color spill from your subject after keying.
- `edge-color`: add a color to the edge of your key to blend a subject with the background.
- `edge-shrink`: shrink the edge of a key.

> The despill code is almost entirely from a [pull request](https://github.com/janpaul123/obs-studio/blob/063fdc0306dfae24d8c084a44e895f30517472a4/plugins/obs-filters/data/chroma_key_filter.effect) made by @janpaul123 to obs-studio. All credit should be his.

## Usage

1. Install [obs-shaderfilter](https://obsproject.com/forum/resources/obs-shaderfilter.1736/) to allow custom shaders to be added to your video sources.
2. Download the shader files and place them wherever you'd like.
3. Add a user-defined shader in the video effect filters. Then load in the file you'd like to use.

![](/images/settings.png)

## Example

**Original Image:**
![](/images/original.png)

**Chroma Key:**
![](/images/obs-chroma-key.png)

**Chroma Key + Key Colour Spill Reduction:**
![](/images/obs-chroma-key-despill.png)

**Chroma Key with Shader:**
![](/images/despill-shader.png)
