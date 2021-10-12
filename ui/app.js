var retina = (window.devicePixelRatio || (window.screen.deviceXDPI / window.screen.logicalXDPI)) > 1;

let r = "";
if(retina) {
  r = "@2x"
}

const layers = [
  {
    label: "Positron",
    name: "positron",
    url: `https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}${r}.png`,
    attribution: 'Map tiles by <a target="_top" rel="noopener" href="http://carto.com">Carto</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>'
  },
  {
    label: "Outdoor",
    name: "outdoor",
    url: `https://tile.thunderforest.com/outdoors/{z}/{x}/{y}${r}.png?apikey=a09616e6150b4c0fa635a23efcda2af8`,
    attribution: 'Map tiles by <a target="_top" rel="noopener" href="http://thunderforest.com">Thunderforest</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>'
  },
  {
    label: "Toner",
    name: "toner",
    url: `https://stamen-tiles-a.a.ssl.fastly.net/toner/{z}/{x}/{y}${r}.png`,
    attribution: 'Map tiles by <a target="_top" rel="noopener" href="https://stamen.com">Stamen</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>'
  },
  {
    label: "Watercolor",
    name: "watercolor",
    url: `https://stamen-tiles-a.a.ssl.fastly.net/watercolor/{z}/{x}/{y}.png`,
    attribution: 'Map tiles by <a target="_top" rel="noopener" href="https://stamen.com">Stamen</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>'
  },
  {
    label: "CyclOSM",
    name: "cyclosm",
    url: "https://a.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png",
    attribution: 'Map tiles by <a target="_top" rel="noopener" href="https://cyclosm.com">CyclOSM</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>'
  },
  {
    label: "Atlas",
    name: "atlas",
    url: `https://tile.thunderforest.com/atlas/{z}/{x}/{y}${r}.png?apikey=a09616e6150b4c0fa635a23efcda2af8`,
    attribution: 'Map tiles by <a target="_top" rel="noopener" href="http://thunderforest.com">Thunderforest</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>'
  },
  {
    label: "Terrain",
    name: "terrain",
    url: `https://stamen-tiles-a.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png`,
    attribution: 'Map tiles by <a target="_top" rel="noopener" href="https://stamen.com">Stamen</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>'
  }
];


const sources = {};
layers.forEach((config) => {
  sources[config.name] = {
    'type': 'raster',
    'tiles': [ config.url ],
    'tileSize': 256,
    'attribution': config.attribution
  };
});


const url = new URL(window.location);
const currentBackground = url.searchParams.get('background') || "positron";

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
      makeBackgroundLayer(currentBackground)
    ]
  },
  hash: true,
  center: [10.1968, 59.7448],
  zoom: 11
});

const computeLengthFromCurrentViewport = () => {
  const bounds = map.getBounds();
  const params = {
    maxLat: bounds.getNorth(),
    minLat: bounds.getSouth(),
    maxLon: bounds.getEast(),
    minLon: bounds.getWest()
  };

  const searchParams = new URLSearchParams(params);

  fetch(`https://byvekstavtale.leonard.io/cycleway-length/?${searchParams.toString()}`)
    .then(response => response.json())
    .then(data => {
      Object.keys(data).forEach(key => {
        const value = data[key];
        document.getElementById(key).textContent = (value / 1000).toFixed(2);
      })
    });

}

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
        "line-cap": "round",
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

  layers.forEach(l => {

    var option = document.createElement("option");
    option.value = l.name;
    option.textContent = l.label;

    if(l.name === currentBackground) {
      option.selected = "selected";
    }

    dropdown.appendChild(option);
  });

  dropdown.onchange = (evt) => {
    map.removeLayer("background");
    map.addLayer(makeBackgroundLayer(evt.target.value), "existing-casing");
    const url = new URL(window.location);
    url.searchParams.set('background', evt.target.value);
    window.history.pushState({}, '', url);
  };

  map.on('zoomend', computeLengthFromCurrentViewport);
  map.on('dragend', computeLengthFromCurrentViewport);
  computeLengthFromCurrentViewport();
});

