var retina = (window.devicePixelRatio || (window.screen.deviceXDPI / window.screen.logicalXDPI)) > 1;

let r = "";
if(retina) {
  r = "@2x"
}

const layers = [
  { name: "outdoor",
    url: `https://tile.thunderforest.com/outdoors/{z}/{x}/{y}${r}.png?apikey=a09616e6150b4c0fa635a23efcda2af8`
  },
  {
    name: "toner",
    url: `http://a.tile.stamen.com/toner/{z}/{x}/{y}${r}.png`
  },
  {
    name: "watercolor",
    url: `http://c.tile.stamen.com/watercolor/{z}/{x}/{y}.jpg`
  },
  {
    name: "cyclosm",
    url: "https://a.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png"
  },
  {
    name: "positron",
    url: `https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}${r}.png`
  }
];


const sources = {};
layers.forEach((config) => {
  sources[config.name] = {
    'type': 'raster',
    'tiles': [ config.url ],
    'tileSize': 256,
    'attribution':
    'Map tiles by <a target="_top" rel="noopener" href="http://thunderforest.com">Thunderforest</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>'
  };
});


const makeBackgroundLayer = (name) => {
  return {
    'id': 'background',
    'type': 'raster',
    'source': name,
    'minzoom': 0,
    'maxzoom': 22
  }
}

var map = new maplibregl.Map({
  container: 'map', // container id
  style: {
    'version': 8,
    'sources': sources,
    'layers': [
      makeBackgroundLayer("outdoor")
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

  const dropdown = document.getElementById("layer");
  dropdown.onchange = (evt) => {
    map.removeLayer("background");
    map.addLayer(makeBackgroundLayer(evt.target.value), "existing-casing");
  };

});

