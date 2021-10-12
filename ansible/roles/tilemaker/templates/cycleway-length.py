from flask import Flask
import osmium as o
import sys
app = Flask(__name__)

PROPOSED_FILE="/tmp/buskerudbyen/cycleway-proposed.pbf"

@app.route('/')
def hello_world():
    return { "proposed": distance() }


class RoadLengthHandler(o.SimpleHandler):
    def __init__(self):
        super(RoadLengthHandler, self).__init__()
        self.length = 0.0

    def way(self, w):
        if 'buskerudbyen:cycleway' in w.tags:
            try:
                self.length += o.geom.haversine_distance(w.nodes)
            except o.InvalidLocationError:
                # A location error might occur if the osm file is an extract
                # where nodes of ways near the boundary are missing.
                print("WARNING: way %d incomplete. Ignoring." % w.id)

def distance():
    h = RoadLengthHandler()
    # As we need the geometry, the node locations need to be cached. Therefore
    # set 'locations' to true.
    h.apply_file(PROPOSED_FILE, locations=True)

    print('Total way length: %.2f km' % (h.length/1000))

    return h.length

if __name__ == '__main__':
   app.run()
