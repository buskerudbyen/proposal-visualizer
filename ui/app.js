var retina = (window.devicePixelRatio || (window.screen.deviceXDPI / window.screen.logicalXDPI)) > 1;

let r = "";
if(retina) {
  r = "@2x"
}

var map = new maplibregl.Map({
  container: 'map', // container id
  style: {
    'version': 8,
    'sources': {
      'raster-tiles': {
        'type': 'raster',
        'tiles': [
          `https://tile.thunderforest.com/outdoors/{z}/{x}/{y}${r}.png?apikey=a09616e6150b4c0fa635a23efcda2af8`
        ],
        'tileSize': 256,
        'attribution':
        'Map tiles by <a target="_top" rel="noopener" href="http://stamen.com">Stamen Design</a>, under <a target="_top" rel="noopener" href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>, under <a target="_top" rel="noopener" href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>'
      }
    },
    'layers': [
      {
        'id': 'simple-tiles',
        'type': 'raster',
        'source': 'raster-tiles',
        'minzoom': 0,
        'maxzoom': 22
      }
    ]
  },
  hash: true,
  center: [10.4051, 59.6153],
  zoom: 15
});

map.on('load', function () {
  map.addSource('tippecanoe', {
    'type': 'vector',
    'tiles': [ 'https://byvekstavtale.leonard.io/tiles/{z}/{x}/{y}.pbf' ],
    'minzoom': 6,
    'maxzoom': 14
  });


  map.addLayer(
    {
      "id": "existing-casing",
      "layout": {
        "line-cap": "butt",
        "line-join": "round",
        "visibility": "visible"
      },
      "metadata": {},
      "paint": {
        "line-color": "#fff",
        "line-width": {
          "base": 1,
          "stops": [
            [
              5,
              0
            ],
            [
              7,
              0.7
            ],
            [
              20,
              14
            ]
          ]
        }
      },
      "source": "tippecanoe",
      "source-layer": "cyclewayexisting",
      "type": "line"
    },
  )
  map.addLayer({
    'id': 'cycleway-existing',
    'type': 'line',
    'source': 'tippecanoe',
    'source-layer': 'cyclewayexisting',
    'layout': {
      'line-cap': 'round',
      'line-join': 'round'
    },
    'paint': {
      'line-opacity': 1,
      'line-color': '#1965e8',
      "line-width": {
        "base": 0.9,
        "stops": [
          [
            11,
            1
          ],
          [
            20,
            6
          ]
        ]
      }
    }
  });

  map.addLayer(

    {
      "id": "proposed-casing",
      "layout": {
        "line-cap": "butt",
        "line-join": "round",
        "visibility": "visible"
      },
      "metadata": {},
      "paint": {
        "line-color": "#000",
        "line-width": {
          "base": 1.2,
          "stops": [
            [
              5,
              0
            ],
            [
              7,
              0.7
            ],
            [
              20,
              14
            ]
          ]
        }
      },
      "source": "tippecanoe",
      "source-layer": "cyclewayproposed",
      "type": "line"
    },
  )

  map.addLayer({
    'id': 'cycleway-proposed',
    'type': 'line',
    'source': 'tippecanoe',
    'source-layer': 'cyclewayproposed',
    'layout': {
      'line-cap': 'round',
      'line-join': 'round'
    },
    'paint': {
      'line-opacity': 1,
      'line-color': '#fcf932',
      "line-width": {
        "base": 0.9,
        "stops": [
          [
            11,
            1
          ],
          [
            20,
            6
          ]
        ]
      }
    }
  });




});

