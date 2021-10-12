from flask import Flask
import osmium as o
import sys, os

app = Flask(__name__)

FILENAME=os.environ.get("PBF_FILE", "/var/tilemaker/norway-filtered.pbf")

@app.route('/')
def get_distances():
    return distance()


class RoadLengthHandler(o.SimpleHandler):
    def __init__(self):
        super(RoadLengthHandler, self).__init__()
        self.proposed_length = 0.0
        self.existing_length = 0.0

    def way(self, w):
        if w.tags.get("buskerudbyen:cycleway") == "existing":
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



def distance():
    h = RoadLengthHandler()
    # As we need the geometry, the node locations need to be cached. Therefore
    # set 'locations' to true.
    h.apply_file(FILENAME, locations=True)

    return {
        "proposed": h.proposed_length,
        "existing": h.existing_length,
        "total": h.proposed_length + h.existing_length
    }

if __name__ == '__main__':
   app.run()
