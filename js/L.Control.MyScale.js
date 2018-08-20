L.Control.MyScale = L.Control.extend({
    options: {
		  position: 'bottomleft',

		  // @option maxWidth: Number = 100
		  // Maximum width of the control in pixels. The width is set dynamically to show round values (e.g. 100, 200, 500).
		  maxWidth: 100,

		  // @option metric: Boolean = True
		  // Whether to show the metric scale line (m/km).
		  metric: true,

		  // @option imperial: Boolean = True
		  // Whether to show the imperial scale line (mi/ft).
		  imperial: false

		  // @option updateWhenIdle: Boolean = false
		  // If `true`, the control is updated on [`moveend`](#map-moveend), otherwise it's always up-to-date (updated on [`move`](#map-move)).
    },
onAdd: function (map) {
		var className = 'leaflet-control-scale',
		    container = L.DomUtil.create('div', className),
		    options = this.options;

		this._addScales(options, className + '-line', container);

		map.on(options.updateWhenIdle ? 'moveend' : 'move', this._update, this);
		map.whenReady(this._update, this);

		return container;
	},

	onRemove: function (map) {
		map.off(this.options.updateWhenIdle ? 'moveend' : 'move', this._update, this);
	},

	_addScales: function (options, className, container) {
		if (options.metric) {
			this._mScale = L.DomUtil.create('div', className, container);
		}
		if (options.imperial) {
			this._iScale = L.DomUtil.create('div', className, container);
		}
	},

	_update: function () {
//		var map = this._map,
//		    y = map.getSize().y / 2;
//		var maxMeters = map.distance(
//				map.containerPointToLatLng([0, y]),
//				map.containerPointToLatLng([this.options.maxWidth, y]));
//		this._updateScales(maxMeters);

    var t = this._map.getBounds(),
        e = t.getCenter().lat,
        i = 6378137 * Math.PI * Math.cos(e * Math.PI / 180),
        n = i * (t.getNorthEast().lng - t.getSouthWest().lng) / 180,
        o = this._map.getSize(),
        s = this.options,
        a = 0;
    if (o.x > 0){
      a = n * (s.maxWidth / o.x);
      this._updateScales(a);
    }

    var z = this._map.getZoom();
    var lng_ne = t.getNorthEast().lng;
    var lng_sw = t.getSouthWest().lng;

    var k = (lng_ne - lng_sw) / 360;
    var length = s.length * k;
    //var pix = 256 * Math.pow(2, z) / k;
    var aa = length * s.maxWidth / o.x;
    this._updateScales(aa);

//    o.x > 0 && (a = n * (s.maxWidth / o.x)), this._updateScales(s, a)

	},

	_updateScales: function (maxMeters) {
		if (this.options.metric && maxMeters) {
			this._updateMetric(maxMeters);
		}
		if (this.options.imperial && maxMeters) {
			this._updateImperial(maxMeters);
		}
	},

	_updateMetric: function (maxMeters) {
		var meters = this._getRoundNum(maxMeters),
		    label = meters < 1000 ? meters + ' um' : (meters / 1000) + ' mm';

		this._updateScale(this._mScale, label, meters / maxMeters);
	},

	_updateImperial: function (maxMeters) {
		var maxFeet = maxMeters * 3.2808399,
		    maxMiles, miles, feet;

		if (maxFeet > 5280) {
			maxMiles = maxFeet / 5280;
			miles = this._getRoundNum(maxMiles);
			this._updateScale(this._iScale, miles + ' mi', miles / maxMiles);

		} else {
			feet = this._getRoundNum(maxFeet);
			this._updateScale(this._iScale, feet + ' ft', feet / maxFeet);
		}
	},

	_updateScale: function (scale, text, ratio) {
		scale.style.width = Math.round(this.options.maxWidth * ratio) + 'px';
		scale.innerHTML = text;
	},

	_getRoundNum: function (num) {
		var pow10 = Math.pow(10, (Math.floor(num) + '').length - 1),
		    d = num / pow10;

		d = d >= 10 ? 10 :
		    d >= 5 ? 5 :
		    d >= 3 ? 3 :
		    d >= 2 ? 2 : 1;

		return pow10 * d;
  }
});

L.control.myscale = function (options) {
    return new L.Control.MyScale(options)
};
