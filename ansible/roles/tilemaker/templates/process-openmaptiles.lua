
-- Nodes will only be processed if one of these keys is present

node_keys = { "amenity", "shop" }

-- Initialize Lua logic

function init_function()
end

-- Finalize Lua logic()
function exit_function()
end

-- Assign nodes to a layer, and set attributes, based on OSM tags

function node_function(node)
  local amenity = node:Find("amenity")
  if amenity=="bicycle_parking" then
    node:Layer("bicycle_parking", false)
    node:Attribute("class",amenity)
  end
end

-- Similarly for ways

function way_function(way)
  local amenity = way:Find("amenity")
  if amenity=="bicycle_parking" then
    way:LayerAsCentroid("bicycle_parking")
    way:Attribute("class",amenity)
  end
end
