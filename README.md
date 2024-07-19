# OBS Chroma Key Despill Shader

A shader to reduce any colour spill from a chroma key background.

> This code is almost entirely from a [pull request to obs-studio](https://github.com/janpaul123/obs-studio/blob/063fdc0306dfae24d8c084a44e895f30517472a4/plugins/obs-filters/data/chroma_key_filter.effect) made by @janpaul123. All credit should be his.

## Usage

1. Install [obs-shaderfilter](https://obsproject.com/forum/resources/obs-shaderfilter.1736/) to allow custom shaders to be added to your video sources.
2. Add two effect filters: a **Chroma Key filter** and a **User-defined shader**.
3. Set the Chroma Key to your taste with the Key Colour Spill Reduction to 0.
4. For the User-defined shader, download the despill shader and load it as a text file.
5. Tweak settings to your liking.

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
