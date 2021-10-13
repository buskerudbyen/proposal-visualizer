from flask import Flask, request
import osmium as o
import sys, os

app = Flask(__name__)

FILENAME=os.environ.get("PBF_FILE", "/var/tilemaker/norway-filtered.pbf")

@app.route('/')
def get_distances():
    max_lat = request.args.get('maxLat')
    max_lon = request.args.get('maxLon')

    min_lat = request.args.get('minLat')
    min_lon = request.args.get('minLon')

    return distance(max_lat, max_lon, min_lat, min_lon)


class RoadLengthHandler(o.SimpleHandler):
    def __init__(self, max_lat, max_lon, min_lat, min_lon):
        super(RoadLengthHandler, self).__init__()

        self.proposed_length = 0.0
        self.existing_length = 0.0

        self.max_lat = self.to_float(max_lat)
        self.max_lon = self.to_float(max_lon)
        self.min_lat = self.to_float(min_lat)
        self.min_lon = self.to_float(min_lon)

    def to_float(self, value):
        if value is None:
            return None
        else:
            return float(value)

    def way(self, w):
        if not self.check_if_inside(w):
            pass
        elif w.tags.get("buskerudbyen:cycleway") == "existing" :
            try:
                self.existing_length += o.geom.haversine_distance(w.nodes)
            except o.InvalidLocationError:
                # A location error might occur if the osm file is an extract
                # where nodes of ways near the boundary are missing.
                print("WARNING: way %d incomplete. Ignoring." % w.id)

        elif w.tags.get("buskerudbyen:cycleway") == "proposed":
            try:
                self.proposed_length += o.geom.haversine_distance(w.nodes)
            except o.InvalidLocationError:
                # A location error might occur if the osm file is an extract
                # where nodes of ways near the boundary are missing.
                print("WARNING: way %d incomplete. Ignoring." % w.id)

    def check_if_inside(self, way):
        if(self.max_lat is None or self.max_lon is None or self.min_lat is None or self.min_lon is None):
            return True
        else:
            for i in way.nodes:
                if(i.lon < self.max_lon and i.lon > self.min_lon and i.lat < self.max_lat and i.lat > self.min_lat):
                    return True
            return False

def distance(max_lat, max_lon, min_lat, min_lon):
    h = RoadLengthHandler(max_lat, max_lon, min_lat, min_lon)

    # As we need the geometry, the node locations need to be cached. Therefore
    # set 'locations' to true.

    h.apply_file(FILENAME, locations=True)

    proposed = round(h.proposed_length / 1000, 1)
    existing = round(h.existing_length / 1000, 1)
    total = round(proposed + existing, 1)

    return {
        "proposed": proposed,
        "existing": existing,
        "total": total
    }

if __name__ == '__main__':
   app.run()
