/**
 * psd2html.js - v@1.0.0 r18
 * update: 2013-03-06
 * Author: Yusuke Hirao [http://www.yusukehirao.com]
 * Github: https://github.com/YusukeHirao/psd2html
 * License: Licensed under the MIT License
 */

/* Included Libraries * -- ----- ----- ----- ----- ----- ----- *

+ Sugar Library vedge
	Freely distributable and licensed under the MIT-style license.
	Copyright (c) 2013 Andrew Plummer
	http://sugarjs.com/

 * ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- */

"use strict";

var $dialog, ControlUI, DialogUI, Math, NAMESPACE, VERSION, WindowUI, clearInterval, clearTimeout, close, copy, createDocument, currentHeight, currentWidth, enlargeForSelect, exec, extract, fileNameCounter, fileNames, getBounds, getLayerPath, getMetrics, global, hideLayerWithoutSelf, isNaN, isSelect, nameCounter, offsetX, offsetY, originalHeight, originalWidth, output, outputCSS, outputJSON, outputLESS, paste, restoreDimension, saveFolder, saveGIF, saveJPEG, savePNG, selectAllLayers, setInterval, setTimeout, showLayer, structures, varDump, __hasProp = {}.hasOwnProperty, __extends = function(e, t) {
    function n() {
        this.constructor = e;
    }
    for (var i in t) __hasProp.call(t, i) && (e[i] = t[i]);
    return n.prototype = t.prototype, e.prototype = new n(), e.__super__ = t.prototype, 
    e;
};

NAMESPACE = "psd2html", VERSION = "1.0.0", global = this, Math = global.Math, setTimeout = global.setTimeout, 
clearTimeout = global.clearTimeout, setInterval = global.setInterval, clearInterval = global.clearInterval, 
isNaN = global.isNaN, ControlUI = function() {
    function e(e, t, n, i, o, r, a) {
        this.$window = e, this.type = t, this.width = null != n ? n : 100, this.height = null != i ? i : 20, 
        this.left = null != o ? o : 0, this.top = null != r ? r : 0, null == a && (a = []), 
        this.window = this.$window.window, this.context = this.window.add.apply(this.window, [ this.type, [ this.left, this.top, this.width + this.left, this.height + this.top ] ].concat(a));
    }
    return e.prototype.close = function(e) {
        return this.window.close(e);
    }, e.prototype.val = function(e) {
        var t, n;
        switch (this.type) {
          case "edittext":
          case "statictext":
            t = "text";
            break;

          default:
            t = "value";
        }
        return null != e ? this.context[t] = n = "" + e : n = this.context[t], n;
    }, e.prototype.on = function(e, t) {
        var n;
        return e = e.toLowerCase().replace(/^on/i, "").replace(/^./, function(e) {
            return e.toUpperCase();
        }), n = this, this.context["on" + e] = function() {
            return t.apply(n, arguments);
        }, this;
    }, e;
}(), WindowUI = function() {
    function e(e, t, n, i, o, r) {
        var a, l, s, c;
        this.type = e, this.name = null != t ? t : "ダイアログボックス", this.width = null != n ? n : 100, 
        this.height = null != i ? i : 100, this.window = new Window(this.type, this.name, [ 0, 0, this.width, this.height ], o), 
        this.window.center(), this.controls = [], this.onOK = function() {}, this.onCancel = function() {}, 
        s = 100, a = 20, l = 10, this.addButton("OK", s, a, this.width - s - l, this.height - a - l, {
            click: function() {
                return this.$window.onOK.apply(this, arguments);
            }
        }), this.addButton("キャンセル", s, a, this.width - s - l - s - l, this.height - a - l, {
            click: function() {
                return this.$window.onCancel.apply(this, arguments), this.close();
            }
        }), c = null != r ? r.call(this) : void 0, c !== !1 && this.show();
    }
    return e.prototype.close = function(e) {
        return this.window.close(e);
    }, e.prototype.show = function() {
        return this.window.show(), this;
    }, e.prototype.hide = function() {
        return this.window.hide(), this;
    }, e.prototype.center = function() {
        return this.window.center(), this;
    }, e.prototype.addControl = function(e, t, n, i, o, r, a) {
        var l, s, c;
        if (l = new ControlUI(this, e, t, n, i, o, r), null != a) for (c in a) __hasProp.call(a, c) && (s = a[c], 
        l.on(c, s));
        return this.controls.push(l), l;
    }, e.prototype.addTextbox = function(e, t, n, i, o, r) {
        return null == o && (o = ""), this.addControl("edittext", e, t, n, i, [ o ], r);
    }, e.prototype.addText = function(e, t, n, i, o, r) {
        return null == e && (e = ""), this.addControl("statictext", t, n, i, o, [ e ], r);
    }, e.prototype.addButton = function(e, t, n, i, o, r) {
        return this.addControl("button", t, n, i, o, [ e ], r);
    }, e.prototype.addRadio = function(e, t, n, i, o, r) {
        return this.addControl("radiobutton", t, n, i, o, [ e ], r);
    }, e.prototype.addCheckbox = function(e, t, n, i, o, r) {
        return this.addControl("checkbox", t, n, i, o, [ e ], r);
    }, e.prototype.ok = function(e) {
        return null == e && (e = function() {}), this.onOK = e, this;
    }, e.prototype.cancel = function(e) {
        return null == e && (e = function() {}), this.onCancel = e, this;
    }, e;
}(), DialogUI = function(e) {
    function t(e, n, i, o, r) {
        this.name = e, this.width = n, this.height = i, t.__super__.constructor.call(this, "dialog", this.name, this.width, this.height, o, r);
    }
    return __extends(t, e), t;
}(WindowUI), $.level = 1, preferences.rulerUnits = Units.PIXELS, originalWidth = 0, 
originalHeight = 0, currentWidth = 0, currentHeight = 0, offsetX = 0, offsetY = 0, 
saveFolder = null, nameCounter = 0, structures = [], fileNames = {}, fileNameCounter = 0, 
Number.prototype.fillZero = function(e) {
    var t;
    return t = Array(e + 1 - this.toString(10).length), t.join("0") + this;
}, varDump = function(e) {
    var t, n, i;
    n = [];
    for (t in e) if (__hasProp.call(e, t)) try {
        i = e[t], i instanceof Function || n.push(t + ": " + i);
    } catch (o) {}
    return alert(n.join("\n"));
}, getLayerPath = function(e) {
    var t, n;
    return n = [], t = function(e) {
        n.push(e.name), e.parent && t(e.parent);
    }, t(e), n.shift(), n.pop(), n.pop(), n.reverse(), encodeURI("/" + n.join("/"));
}, saveJPEG = function(e, t, n) {
    var i, o, r, a;
    return null == t && (t = ""), null == n && (n = 80), r = new Folder(saveFolder + t + "/"), 
    r.exists || r.create(), o = r + "/" + e + ".jpg", i = new File(o), a = new JPEGSaveOptions(), 
    a.embedColorProfile = !1, a.quality = parseInt(12 * (n / 100), 10), a.formatOptions = FormatOptions.OPTIMIZEDBASELINE, 
    a.scans = 3, a.matte = MatteType.NONE, activeDocument.saveAs(i, a, !0, Extension.LOWERCASE), 
    i.getRelativeURI(saveFolder);
}, saveGIF = function(e, t) {
    var n, i, o, r;
    return null == t && (t = ""), o = new Folder(saveFolder + t + "/"), o.exists || o.create(), 
    i = o + "/" + e + ".gif", n = new File(i), r = new GIFSaveOptions(), r.colors = 32, 
    r.dither = Dither.NONE, r.interlacted = !0, r.matte = MatteType.WHITE, r.palette = Palette.EXACT, 
    r.preserveExactColors = !1, r.transparency = !0, activeDocument.saveAs(n, r, !0, Extension.LOWERCASE), 
    n.getRelativeURI(saveFolder);
}, savePNG = function(e, t) {
    var n, i, o, r;
    return null == t && (t = ""), o = new Folder(saveFolder + t + "/"), o.exists || o.create(), 
    i = o + "/" + e + ".png", n = new File(i), r = new PNGSaveOptions(), r.interlaced = !1, 
    activeDocument.saveAs(n, r, !0, Extension.LOWERCASE), n.getRelativeURI(saveFolder);
}, close = function(e) {
    null == e && (e = !1), (!e || confirm("閉じてよろしいですか?")) && activeDocument.close(SaveOptions.DONOTSAVECHANGES);
}, getBounds = function(e) {
    var t;
    return t = e.bounds, {
        x: parseInt(t[0], 10),
        y: parseInt(t[1], 10),
        x2: parseInt(t[2], 10),
        y2: parseInt(t[3], 10)
    };
}, enlargeForSelect = function(e) {
    var t;
    return t = getBounds(e), 0 > t.x && (currentWidth -= t.x, offsetX += t.x, activeDocument.resizeCanvas(currentWidth, currentHeight, AnchorPosition.TOPRIGHT)), 
    0 > t.y && (currentHeight -= t.y, offsetY += t.y, activeDocument.resizeCanvas(currentWidth, currentHeight, AnchorPosition.BOTTOMLEFT)), 
    t.x2 > currentWidth + offsetX && (currentWidth += t.x2 + offsetX, activeDocument.resizeCanvas(currentWidth, currentHeight, AnchorPosition.TOPLEFT)), 
    t.y2 > currentHeight + offsetY && (currentHeight += t.y2 + offsetY, activeDocument.resizeCanvas(currentWidth, currentHeight, AnchorPosition.TOPLEFT)), 
    t;
}, restoreDimension = function() {
    return activeDocument.resizeCanvas(originalWidth - offsetX, originalHeight - offsetY, AnchorPosition.TOPLEFT), 
    activeDocument.resizeCanvas(originalWidth, originalHeight, AnchorPosition.BOTTOMRIGHT);
}, selectAllLayers = function() {
    var e, t;
    t = new ActionReference(), t.putEnumerated(charIDToTypeID("Lyr "), charIDToTypeID("Ordn"), charIDToTypeID("Trgt")), 
    e = new ActionDescriptor(), e.putReference(charIDToTypeID("null"), t), executeAction(stringIDToTypeID("selectAllLayers"), e, DialogModes.NO);
}, isSelect = function() {
    var e, t;
    e = !0, t = $.level, $.level = 0;
    try {
        activeDocument.selection.translate(0, 0);
    } catch (n) {
        return $.level = t, e = !1;
    } finally {
        return $.level = t, e;
    }
}, copy = function(e) {
    var t, n, i, o;
    return n = enlargeForSelect(e), activeDocument.selection.select([ [ n.x, n.y ], [ n.x + 1, n.y ], [ n.x + 1, n.y + 1 ], [ n.x, n.y + 1 ] ]), 
    o = !1, isSelect() || (t = new SolidColor(), t.model = ColorModel.RGB, t.red = 0, 
    t.green = 0, t.blue = 0, i = activeDocument.artLayers.add(), activeDocument.activeLayer = i, 
    activeDocument.selection.fill(t, ColorBlendMode.NORMAL, 100, !1), o = !0), activeDocument.selection.deselect(), 
    selectAllLayers(), activeDocument.selection.select([ [ n.x, n.y ], [ n.x2, n.y ], [ n.x2, n.y2 ], [ n.x, n.y2 ] ]), 
    activeDocument.selection.copy(!0), activeDocument.selection.deselect(), activeDocument.activeLayer = e, 
    i && i.remove(), i = null, $.gc(), o;
}, paste = function(e, t) {
    var n;
    e.paste(), n = activeDocument.activeLayer, n.translate(-n.bounds[0], -n.bounds[1]), 
    t && (activeDocument.selection.select([ [ 0, 0 ], [ 1, 0 ], [ 1, 1 ], [ 0, 1 ] ]), 
    activeDocument.selection.clear()), activeDocument.selection.deselect(), e = null, 
    $.gc();
}, getMetrics = function(e) {
    var t;
    return t = getBounds(e), {
        x: t.x + offsetX,
        y: t.y + offsetY,
        width: t.x2 - t.x,
        height: t.y2 - t.y
    };
}, createDocument = function(e, t, n) {
    return documents.add(e, t, 72, n, NewDocumentMode.RGB, DocumentFill.TRANSPARENT);
}, outputCSS = function(e) {
    var t, n, i, o, r, a, l, s, c, u, h, d, p, v;
    for (i = [], l = h = 0, p = e.length; p > h; l = ++h) s = e[l], u = 10 * l, t = s.url.replace(/\//g, "_").replace(/\.[a-z]+$/i, ""), 
    c = "." + t + " {\n	position: absolute;\n	top: " + s.y + "px;\n	left: " + s.x + "px;\n	z-index: " + u + ";\n	width: " + s.width + "px;\n	height: " + s.height + "px;\n	background: url(" + s.url + ") no-repeat scroll 0 0;\n}", 
    i.push(c);
    for (n = new File(saveFolder + "/" + "style.css"), n.open("w"), n.encoding = "utf-8", 
    n.write(i.join("\n")), n.close(), i = null, n = null, $.gc(), a = [], l = d = 0, 
    v = e.length; v > d; l = ++d) s = e[l], u = 10 * l, t = s.url.replace(/\//g, "_").replace(/\.[a-z]+$/i, ""), 
    c = '<div class="' + t + '">\n	<!-- <img class="' + t + '" src="' + s.url + '" alt="' + s.name + '" width="' + s.width + '" height="' + s.height + '"> -->\n	<!-- <div class="' + t + '" data-src="' + s.url + '" data-width="' + s.width + '" data-height="' + s.height + '" data-x="' + s.x + '" data-y="' + s.y + '" data-z="' + u + '">' + s.name + "<div> -->\n</div>", 
    a.push(c);
    o = '<!doctype html>\n<html>\n<head>\n	<meta charset="utf-8">\n	<link rel="stylesheet" href="style.css">\n$\n</haed>\n<body>\n</body>\n</html>', 
    r = new File(saveFolder + "/" + "index.html"), r.open("w"), r.encoding = "utf-8", 
    r.write(o.replace("$", a.join("\n"))), r.close(), a = null, o = null, r = null, 
    $.gc();
}, outputLESS = function() {
    alert("LESSはまだつくってない");
}, outputJSON = function(e) {
    var t, n, i, o, r, a, l, s;
    for (o = [], t = l = 0, s = e.length; s > l; t = ++l) n = e[t], a = 1e4 - 10 * t, 
    r = '{\n	"name": "' + n.name + '",\n	"className": "' + n.name + '",\n	"x": ' + n.x + ',\n	"y": ' + n.y + ',\n	"z": ' + a + ',\n	"width": ' + n.width + ',\n	"height": ' + n.height + ',\n	"url": "' + n.url + '"\n}', 
    o.push(r);
    i = new File(saveFolder + "/" + "structures.json"), i.open("w"), i.encoding = "utf-8", 
    i.write("[" + o.join(",\n") + "]"), i.close();
}, hideLayerWithoutSelf = function(e) {
    var t, n, i, o, r;
    if (t = e.parent, t && t.layers) {
        for (r = t.layers, i = 0, o = r.length; o > i; i++) n = r[i], n._v = n.visible, 
        n.visible = !1;
        hideLayerWithoutSelf(t);
    }
    return e.visible = !0;
}, showLayer = function(e) {
    var t, n, i, o, r;
    if (t = e.parent, t && t.layers) {
        for (r = t.layers, i = 0, o = r.length; o > i; i++) n = r[i], null != n._v && (n.visible = n._v);
        return showLayer(t);
    }
}, extract = function(e, t, n) {
    var i, o, r, a, l, s, c, u, h, d, p;
    s = e.name, (r = s.match(/(\.(?:jpe?g|gif|png))$/i)) && (r = r[0], s = s.replace(r, "")), 
    n && (r = "." + n), t || hideLayerWithoutSelf(e), o = getLayerPath(e), s = s.replace(/^[0-9]/, "image$0").replace(/[^a-z0-9_\.:-]/gi, ""), 
    "image" === s && (s = "image_" + nameCounter++), fileNames[o + s] && (s += fileNameCounter++), 
    fileNames[o + s] = !0, a = copy(e), l = getMetrics(e), c = createDocument(l.width, l.height, e.name), 
    paste(c, a), p = ".jpeg" === r || ".jpg" === r ? saveJPEG(s, o) : ".gif" === r ? saveGIF(s, o) : savePNG(s, o), 
    c.close(SaveOptions.DONOTSAVECHANGES), i = l, i.name = s, i.url = p, structures.push(i), 
    t || showLayer(e), u = null, h = null, d = null, $.gc();
}, output = function(e, t, n) {
    var i, o, r;
    for (o = 0, r = e.length; r > o; o++) i = e[o], "LayerSet" === i.typename && i.visible ? output(i.layers, t, n) : i.visible && i.kind === LayerKind.SMARTOBJECT && extract(i, t, n);
}, exec = function(e, t, n, i) {
    var o, r, a, l;
    null == n && (n = "~/"), null == i && (i = !1), originalWidth = activeDocument.width, 
    originalHeight = activeDocument.height, currentWidth = originalWidth, currentHeight = originalHeight, 
    saveFolder = new Folder(n), l = activeDocument.layers, output(l, i, t), restoreDimension(), 
    fileNames = null, l = null, $.gc(), structures.reverse(), o = 1, a = 2, r = 4, e & o && outputCSS(structures), 
    e & r && outputJSON(structures), structures = null, saveFolder = null, $.gc(), alert("Complete!!");
}, $dialog = new DialogUI("PSD to PNG", 700, 400, null, function() {
    var e, t, n, i, o;
    return this.addText("書き出しフォルダ", 120, 20, 10, 50), i = this.addTextbox(540, 20, 60, 70), 
    this.addButton("選択", 80, 20, 610, 70, {
        click: function() {
            return saveFolder = Folder.selectDialog("保存先のフォルダを選択してください"), saveFolder ? i.val(decodeURI(saveFolder.getRelativeURI("/"))) : void 0;
        }
    }), this.addText("書き出し形式", 120, 20, 10, 160), o = [], o.push(this.addCheckbox("HTML&CSS", 220, 20, 10, 190)), 
    o.push(this.addCheckbox("LESS", 220, 20, 230, 190)), o.push(this.addCheckbox("JSON", 220, 20, 450, 190)), 
    this.addText("オプション", 120, 20, 10, 230), t = this.addCheckbox("背景やバウンディングボックスの範囲に入るオブジェクトも含めて書きだす。", 600, 20, 10, 260), 
    n = this.addRadio("全ての画像を強制的にPNGで書き出す。", 600, 20, 10, 290), e = this.addRadio("全ての画像を強制的にGIFで書き出す。", 600, 20, 10, 320), 
    this.ok(function() {
        var r, a, l, s, c, u, h;
        for (s = encodeURI(i.val()), c = 0, l = u = 0, h = o.length; h > u; l = ++u) r = o[l], 
        r.val() && (c += Math.pow(2, l));
        return n.val() && (a = "png"), e.val() && (a = "gif"), this.close(), exec(c, a, s, t.val());
    });
});