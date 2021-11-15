
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
    details(node)
  end
end

-- Similarly for ways

function way_function(way)
  local amenity = way:Find("amenity")
  if amenity=="bicycle_parking" then
    way:LayerAsCentroid("bicycle_parking")
    details(way)
  end
end

function details(i)
  if i:Find("covered")=="yes" then
    i:Attribute("class", "bicycle_covered")

  elseif i:Find("bicycle_parking")=="shed" then
    i:Attribute("class", "bicycle_shed")

  elseif i:Find("bicycle_parking")=="lockers" then
    i:Attribute("class", "bicycle_locker")

  else
    i:Attribute("class", "bicycle_parking")
  end

end
