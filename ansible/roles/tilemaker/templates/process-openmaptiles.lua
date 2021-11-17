
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

  if i:Find("access")=="customers" and i:Find("fee")=="yes" and i:Holds("operator") and i:Find("operator"):startswith("Bane") then
    i:Attribute("class", "bicycle_shed_public")

  elseif i:Find("bicycle_parking")=="lockers" then
    add_access(i, "bicycle_locker")

  elseif i:Find("covered")=="yes" then
    add_access(i, "bicycle_covered")

  else
    add_access(i, "bicycle_parking")
  end


end

function add_access(i, base)

  local access = i:Find("access")

  if access=="private" or access=="customers" or access=="no" then
    i:Attribute("class", base .. "_private")
  else
    i:Attribute("class", base .. "_public")
  end

end


function string:startswith(start)
  return self:sub(1, #start) == start
end

