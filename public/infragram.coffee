# This file is part of infragram-js.
#
# infragram-js is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# infragram-js is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with infragram-js.  If not, see <http://www.gnu.org/licenses/>.

image = null
mode = "raw"
r_exp = ""
g_exp = ""
b_exp = ""
m_exp = "" #monochrome

class JsImage
        constructor: (@data, @width, @height, @channels) ->

        copyToImageData: (imgData) ->
                imgData.data.set(@data)

        extrema: ->
                n = @width * @height
                mins = (@data[i] for i in [0...@channels])
                maxs = (@data[i] for i in [0...@channels])
                j = 0
                for i in [0...n]
                        for c in [0...@channels]
                                if @data[j] > maxs[c]
                                        maxs[c] = @data[j]
                                if @data[j] < mins[c]
                                        mins[c] = @data[j]
                                j++
                return [mins, maxs]
        
histogram = (array, [min,max], nbins) ->
        bins = (0 for i in [0...nbins])
        d = (max - min) / nbins
        for a in array
                i = Math.floor((a - min) / d)
                if 0 <= i < nbins
                        bins[i]++
        return bins

segmented_colormap = (segments) -> (x) ->
        [y0, y1] = [0, 0]
        [x0, x1] = [segments[0][0], 1]
        if x < x0
                return y0
        
        for [xstart, y0, y1],i in segments
                x0 = xstart
                if i == segments.length - 1
                        x1 = 1
                        break
                x1 = segments[i+1][0]
                if xstart <= x < x1
                        break

        result = []
        for i in [0...y0.length]
                result[i] = (x-x0) / (x1 - x0) * (y1[i] - y0[i]) + y0[i]
        return result
                        
get_channels = (img) ->
        n = img.width * img.height;
        r = new Float32Array(n);
        g = new Float32Array(n);
        b = new Float32Array(n);
        for i in [0...n]
                r[i] = img.data[4*i + 0];
                g[i] = img.data[4*i + 1];
                b[i] = img.data[4*i + 2];
        mkImage = (d) -> new JsImage(d, img.width, img.height, 1);
        return [mkImage(r), mkImage(g), mkImage(b)];

ndvi = (nir, vis) ->
        n = nir.width * nir.height;
        d = new Float64Array(n);
        for i in [0...n]
                d[i] = (nir.data[i] - vis.data[i]) / (nir.data[i] + vis.data[i]);
        return new JsImage(d, nir.width, nir.height, 1);

# Apply the given colormap to a single-channel image
jsColorify = (img, colormap) -> 
        $('#btn-colorize').addClass('active')
        n = img.width * img.height;
        data = new Uint8ClampedArray(4*n);
        j = 0;
        for i in [0...n]
                [r,g,b] = colormap(img.data[i]);
                data[j++] = r;
                data[j++] = g;
                data[j++] = b;
                data[j++] = 255;
        cimg = new JsImage();
        cimg.width = img.width;
        cimg.height = img.height;
        cimg.data = data;
        return new JsImage(data, img.width, img.height, 4);

# This returns values between 0 and 255, inclusive
infragrammar = (img) ->
        $('#btn-colorize').removeClass('active')
        n = img.width * img.height;
        r = new Float32Array(n);
        g = new Float32Array(n);
        b = new Float32Array(n);
        o = new Float32Array(4*n);
        for i in [0...n]
                r[i] = img.data[4*i + 0]/255;
                g[i] = img.data[4*i + 1]/255;
                b[i] = img.data[4*i + 2]/255;
                o[4*i + 0] = 255*r_exp(r[i],g[i],b[i]);
                o[4*i + 1] = 255*g_exp(r[i],g[i],b[i]);
                o[4*i + 2] = 255*b_exp(r[i],g[i],b[i]);
                o[4*i + 3] = 255
        return new JsImage(o, img.width, img.height, 4);

# This returns values between 0 and 1, inclusive
infragrammar_mono = (img) ->
        n = img.width * img.height;
        r = new Float32Array(n);
        g = new Float32Array(n);
        b = new Float32Array(n);
        o = new Float32Array(n);
        for i in [0...n]
                r[i] = img.data[4*i + 0]/255.0;
                g[i] = img.data[4*i + 1]/255.0;
                b[i] = img.data[4*i + 2]/255.0;
                o[i] = r_exp(r[i],g[i],b[i]);
        return new JsImage(o, img.width, img.height, 1);

render = (img) ->
        e = $("#image")[0];
        e.width = img.width
        e.height = img.height
        ctx = e.getContext("2d");
        d = ctx.getImageData(0, 0, img.width, img.height);
        img.copyToImageData(d);
        ctx.putImageData(d, 0, 0);

greyscale_colormap = segmented_colormap(
        [ [0, [0,0,0], [255,255,255]],
          [1, [255,255,255], [255,255,255]] ])

colormap1 = segmented_colormap(
        [ [   0, [0,0,255],   [38,195,195]],
          [ 0.5, [0,150,0],  [255,255,0]],
          [0.75, [255,255,0], [255,50,50]] ])

colormap2 = segmented_colormap(
        [ [   0, [0,0,255],   [0,0,255]],
          [ 0.1, [0,0,255],   [38,195,195]],
          [ 0.5, [0,150,0],  [255,255,0]],
          [ 0.7, [255,255,0],  [255,50,50]],
          [0.9, [255,50,50], [255,50,50]] ])

colormap_fastie = segmented_colormap(
        [ [   0,   [255,255,255],   [0,0,0]],
          [ 0.167, [0,0,0],         [255,255,255]],
          [ 0.33,  [255,255,255],   [0,0,0]],
          [ 0.5,   [0,0,0],         [140,140,255]],
          [ 0.55,  [140,140,255],   [0,255,0]],
          [ 0.63,  [0,255,0],       [255,255,0]],
          [ 0.75,  [255,255,0],     [255,0,0]],
          [ 0.95,  [255,0,0],       [255,0,255]] ])

colormap = colormap1

update_colorbar = (min,max) =>        
        $('#colorbar-container')[0].style.display = 'inline-block'
        e = $('#colorbar')[0]
        ctx = e.getContext("2d");
        d = ctx.getImageData(0, 0, e.width, e.height);
        for i in [0...e.width]
                for j in [0...e.height]
                        [r,g,b] = colormap(i / e.width)
                        k = 4 * (i + j*e.width)
                        d.data[k+0] = r
                        d.data[k+1] = g
                        d.data[k+2] = b
                        d.data[k+3] = 255
        ctx.putImageData(d, 0, 0)
        $("#colorbar-min")[0].textContent = min.toFixed(2)
        $("#colorbar-max")[0].textContent = max.toFixed(2)

update = (img) ->
        if $('#colorbar-container')[0]
            $('#colorbar-container')[0].style.display = 'none'
        if mode == "ndvi"
            [r,g,b] = get_channels(img)
            ndvi_img = ndvi(r,b)
            # this isn't correct for NDVI; we want values from -1 to 1:
            # [[min],[max]] = ndvi_img.extrema()
            min = -1
            max = 1
            normalize = (x) -> (x - min) / (max - min)
            result = jsColorify(ndvi_img, (x) -> colormap(normalize(x)))
            update_colorbar(min, max)
        else if mode == "raw"
            result = new JsImage(img.data, img.width, img.height, 4);
        else if mode == "nir"
            [r,g,b] = get_channels(img)
            result = jsColorify(r, (x) -> [x, x, x])
        else
            result = infragrammar(img)
        render(result)

save_expressions = (r,g,b) ->
        r = r.replace(/X/g,$('#slider').val()/100)
        g = g.replace(/X/g,$('#slider').val()/100)
        b = b.replace(/X/g,$('#slider').val()/100)
        r = "R" if r == ""
        g = "G" if g == ""
        b = "B" if b == ""
        eval("r_exp = function(R,G,B){var r=R,g=G,b=B;return "+r+";}")
        eval("g_exp = function(R,G,B){var r=R,g=G,b=B;return "+g+";}")
        eval("b_exp = function(R,G,B){var r=R,g=G,b=B;return "+b+";}")

save_expressions_hsv = (h,s,v) ->
        h = h.replace(/X/g,$('#slider').val()/100)
        s = s.replace(/X/g,$('#slider').val()/100)
        v = v.replace(/X/g,$('#slider').val()/100)
        h = "H" if h == ""
        s = "S" if s == ""
        v = "V" if v == ""
        eval("r_exp = function(R,G,B){var h=H,s=S,v=V,hsv = rgb2hsv(R, G, B), H = hsv[0], S = hsv[1], V = hsv[2]; return hsv2rgb("+h+","+s+","+v+")[0];}")
        eval("g_exp = function(R,G,B){var h=H,s=S,v=V,hsv = rgb2hsv(R, G, B), H = hsv[0], S = hsv[1], V = hsv[2]; return hsv2rgb("+h+","+s+","+v+")[1];}")
        eval("b_exp = function(R,G,B){var h=H,s=S,v=V,hsv = rgb2hsv(R, G, B), H = hsv[0], S = hsv[1], V = hsv[2]; return hsv2rgb("+h+","+s+","+v+")[2];}")

# modified from:
# http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c

hsv2rgb = (h,s,v) ->
        data = [];
        if s is 0 
                rgb = [v,v,v];
        else
                i = Math.floor(h * 6);
                f = h * 6 - i;
                p = v * (1 - s);
                q = v * (1 - f * s);
                t = v * (1 - (1 - f) * s);
                data = [v*(1-s), v*(1-s*(h-i)), v*(1-s*(1-(h-i)))];
                switch i
                  when 0 then rgb = [v, t, p];
                  when 1 then rgb = [q, v, p];
                  when 2 then rgb = [p, v, t];
                  when 3 then rgb = [p, q, v];
                  when 4 then rgb = [t, p, v];
                  else rgb = [v, p, q];
        return rgb

rgb2hsv = (r, g, b) ->
    max = Math.max(r, g, b)
    min = Math.min(r, g, b)
    h = s = v = max

    d = max - min
    s = if max == 0 then 0 else d / max

    if max == min
        h = 0 # achromatic
    else
        switch max
            when r then h = (g - b) / d + (if g < b then 6 else 0)
            when g then h = (b - r) / d + 2
            when b then h = (r - g) / d + 4
        h /= 6

    return [h, s, v]

set_mode = (new_mode) ->
    mode = new_mode
    update(image)

    if mode == "ndvi"
        $("#colormaps-group")[0].style.display = "inline-block"
    else
        $("#colormaps-group")[0].style.display = "none" if ($("#colormaps-group").size() > 0)

jsUpdateImage = (img) ->
    imgCanvas = document.getElementById("image")
    ctx = imgCanvas.getContext("2d")
    width = img.videoWidth or img.width
    height = img.videoHeight or img.height
    ctx.drawImage(img, 0, 0, width, height, 0, 0, imgCanvas.width, imgCanvas.height)
    image = ctx.getImageData(0, 0, imgCanvas.width, imgCanvas.height)
    set_mode(mode)

jsHandleOnClickRaw  = ()     ->    set_mode("raw")
jsHandleOnClickNdvi = ()     ->    set_mode("ndvi")
jsRunInfragrammar   = (mode) ->    set_mode(mode)

jsGetCurrentImage = () ->
    e = $("#image")[0];
    ctx = e.getContext("2d");
    return ctx.canvas.toDataURL("image/jpeg")

jsHandleOnSubmitInfraHsv = () ->
    save_expressions_hsv($('#h_exp').val(), $('#s_exp').val(), $('#v_exp').val())
    set_mode("infragrammar_hsv")

jsHandleOnSubmitInfra = () ->
    save_expressions($('#r_exp').val(), $('#g_exp').val(), $('#b_exp').val())
    set_mode("infragrammar")

jsHandleOnSubmitInfraMono = () ->
    save_expressions($('#m_exp').val(), $('#m_exp').val(), $('#m_exp').val())
    set_mode("infragrammar_mono")

jsHandleOnClickGrey = () ->
    colormap = greyscale_colormap
    update(image)

jsHandleOnSlide = (event) ->
    if mode == "infragrammar"
        save_expressions($('#r_exp').val(), $('#g_exp').val(), $('#b_exp').val())
    else if mode == "infragrammar_hsv"
        save_expressions_hsv($('#h_exp').val(), $('#s_exp').val(), $('#v_exp').val())
    else
        save_expressions($('#m_exp').val(), $('#m_exp').val(), $('#m_exp').val())
    update(image)
