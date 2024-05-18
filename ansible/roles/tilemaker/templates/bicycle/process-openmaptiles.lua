-- Data processing based on openmaptiles.org schema
-- https://openmaptiles.org/schema/
-- Copyright (c) 2016, KlokanTech.com & OpenMapTiles contributors.
-- Used under CC-BY 4.0

--------
-- Alter these lines to control which languages are written for place/streetnames
--
-- Preferred language can be (for example) "en" for English, "de" for German, or nil to use OSM's name tag:
preferred_language = nil
-- This is written into the following vector tile attribute (usually "name:latin"):
preferred_language_attribute = "name:latin"
-- If OSM's name tag differs, then write it into this attribute (usually "name_int"):
default_language_attribute = "name_int"
-- Also write these languages if they differ - for example, { "de", "fr" }
additional_languages = { "no", "de", "en", "fr" }
--------

-- Enter/exit Tilemaker
function init_function()
end
function exit_function()
end

-- Implement Sets in tables
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

-- Meters per pixel if tile is 256x256
ZRES5  = 4891.97
ZRES6  = 2445.98
ZRES7  = 1222.99
ZRES8  = 611.5
ZRES9  = 305.7
ZRES10 = 152.9
ZRES11 = 76.4
ZRES12 = 38.2
ZRES13 = 19.1

-- The height of one floor, in meters
BUILDING_FLOOR_HEIGHT = 3.66

local monthMap = {
	Jan = 1,
	Feb = 2,
	Mar = 3,
	Apr = 4,
	May = 5,
	Jun = 6,
	Jul = 7,
	Aug = 8,
	Sep = 9,
	Oct = 10,
	Nov = 11,
	Dec = 12
}

-- Process node/way tags
aerodromeValues = Set { "international", "public", "regional", "military", "private" }

-- Process node tags

node_keys = { "addr:housenumber","aerialway","aeroway","amenity","barrier","highway","historic","leisure","natural","office","place","railway","shop","sport","tourism","waterway" }
function node_function(node)
	-- Write 'aerodrome_label'
	local aeroway = node:Find("aeroway")
	if aeroway == "aerodrome" then
		node:Layer("aerodrome_label", false)
		SetNameAttributes(node)
		node:Attribute("iata", node:Find("iata"))
		SetEleAttributes(node)
		node:Attribute("icao", node:Find("icao"))

		local aerodrome_value = node:Find("aerodrome")
		local class
		if aerodromeValues[aerodrome_value] then class = aerodrome_value else class = "other" end
		node:Attribute("class", class)
	end
	-- Write 'housenumber'
	local housenumber = node:Find("addr:housenumber")
	if housenumber~="" then
		node:Layer("housenumber", false)
		node:Attribute("housenumber", housenumber)
	end

	-- Write 'place'
	-- note that OpenMapTiles has a rank for countries (1-3), states (1-6) and cities (1-10+);
	--   we could potentially approximate it for cities based on the population tag
	local place = node:Find("place")
	if place ~= "" then
		local rank = nil
		local mz = 13
		local pop = tonumber(node:Find("population")) or 0

		if     place == "continent"     then mz=0
		elseif place == "country"       then
			if     pop>50000000 then rank=1; mz=1
			elseif pop>20000000 then rank=2; mz=2
			else                     rank=3; mz=3 end
		elseif place == "state"         then mz=4
		elseif place == "city"          then mz=5
		elseif place == "town" and pop>8000 then mz=7
		elseif place == "town"          then mz=8
		elseif place == "village" and pop>2000 then mz=9
		elseif place == "village"       then mz=10
		elseif place == "suburb"        then mz=11
		elseif place == "hamlet"        then mz=12
		elseif place == "neighbourhood" then mz=13
		elseif place == "locality"      then mz=13
		end

		node:Layer("place", false)
		node:Attribute("class", place)
		node:MinZoom(mz)
		if rank then node:AttributeNumeric("rank", rank) end
		if place=="country" then node:Attribute("iso_a2", node:Find("ISO3166-1:alpha2")) end
		SetNameAttributes(node)
		return
	end

	-- Write 'poi'
	local rank, class, subclass = GetPOIRank(node)
	if rank then WritePOI(node,class,subclass,rank) end

	-- Write 'mountain_peak' and 'water_name'
	local natural = node:Find("natural")
	if natural == "peak" or natural == "volcano" then
		node:Layer("mountain_peak", false)
		SetEleAttributes(node)
		node:AttributeNumeric("rank", 1)
		node:Attribute("class", natural)
		SetNameAttributes(node)
		return
	end
	if natural == "bay" then
		node:Layer("water_name", false)
		SetNameAttributes(node)
		return
	end
end

-- Process way tags

majorRoadValues = Set { "motorway", "trunk", "primary" }
mainRoadValues  = Set { "secondary", "motorway_link", "trunk_link", "primary_link", "secondary_link" }
midRoadValues   = Set { "tertiary", "tertiary_link" }
minorRoadValues = Set { "unclassified", "residential", "road", "living_street" }
trackValues     = Set { "cycleway", "byway", "bridleway", "track" }
pathValues      = Set { "footway", "path", "steps", "pedestrian" }
linkValues      = Set { "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link" }
constructionValues = Set { "primary", "secondary", "tertiary", "motorway", "service", "trunk", "track" }

aerowayBuildings= Set { "terminal", "gate", "tower" }
landuseKeys     = Set { "school", "university", "kindergarten", "college", "library", "hospital",
                        "railway", "cemetery", "military", "residential", "commercial", "industrial",
                        "retail", "stadium", "pitch", "playground", "theme_park", "bus_station", "zoo" }
landcoverKeys   = { wood="wood", forest="wood",
                    wetland="wetland",
                    beach="sand", sand="sand",
                    farmland="farmland", farm="farmland", orchard="farmland", vineyard="farmland", plant_nursery="farmland",
                    glacier="ice", ice_shelf="ice",
                    grassland="grass", grass="grass", meadow="grass", allotments="grass", park="grass", village_green="grass", recreation_ground="grass", garden="grass", golf_course="grass" }

-- POI key/value pairs: based on https://github.com/openmaptiles/openmaptiles/blob/master/layers/poi/mapping.yaml
poiTags         = { aerialway = Set { "station" },
					amenity = Set { "arts_centre", "bank", "bar", "bbq", "bicycle_parking", "bicycle_rental", "bicycle_repair_station", "biergarten", "bus_station", "cafe", "cinema", "clinic", "college", "community_centre", "compressed_air", "courthouse", "dentist", "doctors", "drinking_water", "embassy", "fast_food", "ferry_terminal", "fire_station", "food_court", "fuel", "grave_yard", "hospital", "ice_cream", "kindergarten", "library", "marketplace", "motorcycle_parking", "nightclub", "nursing_home", "parking", "pharmacy", "place_of_worship", "police", "post_box", "post_office", "prison", "pub", "public_building", "recycling", "restaurant", "school", "shelter", "swimming_pool", "taxi", "telephone", "theatre", "toilets", "townhall", "university", "veterinary", "waste_basket" },
					barrier = Set { "bollard", "border_control", "cycle_barrier", "gate", "lift_gate", "sally_port", "stile", "toll_booth" },
					building = Set { "dormitory", "sports_centre" },
					highway = Set { "bus_stop", "track" },
					historic = Set { "monument", "castle", "ruins" },
					landuse = Set { "basin", "brownfield", "cemetery", "reservoir", "winter_sports" },
					leisure = Set { "dog_park", "escape_game", "garden", "golf_course", "ice_rink", "hackerspace", "marina", "miniature_golf", "park", "pitch", "playground", "sports_centre", "stadium", "swimming_area", "swimming_pool", "track", "water_park" },
					natural = Set { "beach" },
					railway = Set { "halt", "station", "subway_entrance", "train_station_entrance", "tram_stop" },
					shop = Set { "accessories", "alcohol", "antiques", "art", "bag", "bakery", "beauty", "bed", "beverages", "bicycle", "books", "boutique", "butcher", "camera", "car", "car_repair", "carpet", "charity", "chemist", "chocolate", "clothes", "coffee", "computer", "confectionery", "convenience", "copyshop", "cosmetics", "deli", "delicatessen", "department_store", "doityourself", "dry_cleaning", "electronics", "erotic", "fabric", "florist", "frozen_food", "furniture", "garden_centre", "general", "gift", "greengrocer", "hairdresser", "hardware", "hearing_aids", "hifi", "ice_cream", "interior_decoration", "jewelry", "kiosk", "lamps", "laundry", "mall", "massage", "mobile_phone", "motorcycle", "music", "musical_instrument", "newsagent", "optician", "outdoor", "perfume", "perfumery", "pet", "photo", "second_hand", "shoes", "sports", "stationery", "supermarket", "tailor", "tattoo", "ticket", "tobacco", "toys", "travel_agency", "video", "video_games", "watches", "weapons", "wholesale", "wine" },
					sport = Set { "american_football", "archery", "athletics", "australian_football", "badminton", "baseball", "basketball", "beachvolleyball", "billiards", "bmx", "boules", "bowls", "boxing", "canadian_football", "canoe", "chess", "climbing", "climbing_adventure", "cricket", "cricket_nets", "croquet", "curling", "cycling", "disc_golf", "diving", "dog_racing", "equestrian", "fatsal", "field_hockey", "free_flying", "gaelic_games", "golf", "gymnastics", "handball", "hockey", "horse_racing", "horseshoes", "ice_hockey", "ice_stock", "judo", "karting", "korfball", "long_jump", "model_aerodrome", "motocross", "motor", "multi", "netball", "orienteering", "paddle_tennis", "paintball", "paragliding", "pelota", "racquet", "rc_car", "rowing", "rugby", "rugby_league", "rugby_union", "running", "sailing", "scuba_diving", "shooting", "shooting_range", "skateboard", "skating", "skiing", "soccer", "surfing", "swimming", "table_soccer", "table_tennis", "team_handball", "tennis", "toboggan", "volleyball", "water_ski", "yoga" },
					tourism = Set { "alpine_hut", "aquarium", "artwork", "attraction", "bed_and_breakfast", "camp_site", "caravan_site", "chalet", "gallery", "guest_house", "hostel", "hotel", "information", "motel", "museum", "picnic_site", "theme_park", "viewpoint", "zoo" },
					waterway = Set { "dock" } }

-- POI "class" values: based on https://github.com/openmaptiles/openmaptiles/blob/master/layers/poi/poi.yaml
poiClasses      = { townhall="town_hall", public_building="town_hall", courthouse="town_hall", community_centre="town_hall",
					golf="golf", golf_course="golf", miniature_golf="golf",
					fast_food="fast_food", food_court="fast_food",
					park="park", bbq="park", beach="beach",
					bus_stop="bus", bus_station="bus",
					subway_entrance="entrance", train_station_entrance="entrance",
					camp_site="campsite", caravan_site="campsite",
					laundry="laundry", dry_cleaning="laundry",
					supermarket="grocery", deli="grocery", delicatessen="grocery", department_store="grocery", greengrocer="grocery", marketplace="grocery",
					books="library", library="library",
					university="college", college="college",
					hotel="lodging", motel="lodging", bed_and_breakfast="lodging", guest_house="lodging", hostel="lodging", chalet="lodging", alpine_hut="lodging", dormitory="lodging",
					chocolate="ice_cream", confectionery="ice_cream",
					post_box="post",  post_office="post",
					cafe="cafe",
					school="school",  kindergarten="school",
					alcohol="alcohol_shop",  beverages="alcohol_shop",  wine="alcohol_shop",
					bar="bar", nightclub="bar",
					marina="harbor", dock="harbor",
					car="car", car_repair="car", taxi="car",
					hospital="hospital", nursing_home="hospital",  clinic="hospital",
					grave_yard="cemetery", cemetery="cemetery",
					attraction="attraction", viewpoint="attraction",
					biergarten="beer", pub="beer",
					music="music", musical_instrument="music",
					american_football="stadium", stadium="stadium", soccer="stadium",
					art="art_gallery", artwork="art_gallery", gallery="art_gallery", arts_centre="art_gallery",
					bag="clothing_store", clothes="clothing_store",
					swimming_area="swimming", swimming="swimming",
					castle="castle", ruins="castle", toilets="toilet",
					museum="museum", playground="playground" }
poiClassRanks   = { hospital=1, railway=2, bus=3, attraction=4, museum=4, harbor=5, college=6,
					school=7, stadium=8, zoo=9, town_hall=10, campsite=11, toilet=11, cemetery=12,
					park=13, playground=13, library=14, police=15, post=16, golf=17, shop=18, grocery=19,
					fast_food=20, clothing_store=21, bar=22 }
waterClasses    = Set { "river", "riverbank", "stream", "canal", "drain", "ditch", "dock" }
waterwayClasses = Set { "stream", "river", "canal", "drain", "ditch" }

-- Scan relations for use in ways

function relation_scan_function(relation)
	if relation:Find("type")=="boundary" and relation:Find("boundary")=="administrative" then
		relation:Accept()
	end
	if relation:Find("type")=="route" and relation:Find("route")=="bicycle" then
		relation:Accept()
	end
end


function relation_function(relation)
	if relation:Find("type")=="route" and relation:Find("route")=="bicycle" then
		relation:Layer("transportation", false)
		relation:Attribute("class", "bicycle_route")
		relation:Attribute("ref", relation:Find("ref"))
		relation:Attribute("description", relation:Find("description"))
		relation:Attribute("name", relation:Find("name"))
		relation:Attribute("from", relation:Find("from"))
		relation:Attribute("to", relation:Find("to"))
		relation:Attribute("website", relation:Find("website"))

		local ref = relation:Find("ref")
		if ref~="" then
			relation:Attribute("ref",ref)
			relation:AttributeNumeric("ref_length", ref:len())
		end
		relation:Attribute("name", relation:Find("name"))

		local networks = {
			["lcn"] = "local",
			["rcn"] = "regional",
			["ncn"] = "national",
			["icn"] = "international"
		}

		local network = relation:Find("network")
		local n = networks[network]
		if n~=nil then
			relation:Attribute("network", n)
		end
	end
end
-- Process way tags

function way_function(way)
	local route    = way:Find("route")
	local highway  = way:Find("highway")
	local waterway = way:Find("waterway")
	local water    = way:Find("water")
	local building = way:Find("building")
	local natural  = way:Find("natural")
	local historic = way:Find("historic")
	local landuse  = way:Find("landuse")
	local leisure  = way:Find("leisure")
	local amenity  = way:Find("amenity")
	local aeroway  = way:Find("aeroway")
	local railway  = way:Find("railway")
	local service  = way:Find("service")
	local sport    = way:Find("sport")
	local shop     = way:Find("shop")
	local tourism  = way:Find("tourism")
	local man_made = way:Find("man_made")
	local boundary = way:Find("boundary")
	local isClosed = way:IsClosed()
	local housenumber = way:Find("addr:housenumber")
	local write_name = false
	local construction = way:Find("construction")

	-- Miscellaneous preprocessing
	if way:Find("disused") == "yes" then return end
	if boundary~="" and way:Find("protection_title")=="National Forest" and way:Find("operator")=="United States Forest Service" then return end
	if highway == "proposed" then return end
	if aerowayBuildings[aeroway] then building="yes"; aeroway="" end
	if landuse == "field" then landuse = "farmland" end
	if landuse == "meadow" and way:Find("meadow")=="agricultural" then landuse="farmland" end

	-- Boundaries within relations
	local admin_level = 11
	local isBoundary = false
	while true do
		local rel = way:NextRelation()
		if not rel then break end
		isBoundary = true
		admin_level = math.min(admin_level, tonumber(way:FindInRelation("admin_level")) or 11)
	end

	-- Boundaries in ways
	if boundary=="administrative" then
		admin_level = math.min(admin_level, tonumber(way:Find("admin_level")) or 11)
		isBoundary = true
	end

	-- Administrative boundaries
	-- https://openmaptiles.org/schema/#boundary
	if isBoundary and not (way:Find("maritime")=="yes") then
		local mz = 0
		if     admin_level>=3 and admin_level<5 then mz=4
		elseif admin_level>=5 and admin_level<7 then mz=8
		elseif admin_level==7 then mz=10
		elseif admin_level>=8 then mz=12
		end

		way:Layer("boundary",false)
		way:AttributeNumeric("admin_level", admin_level)
		way:MinZoom(mz)
		-- disputed status (0 or 1). some styles need to have the 0 to show it.
		local disputed = way:Find("disputed")
		if disputed=="yes" then
			way:AttributeNumeric("disputed", 1)
		else
			way:AttributeNumeric("disputed", 0)
		end
	end

	-- Roads ('transportation' and 'transportation_name', plus 'transportation_name_detail')
	if highway~="" then
		local access = way:Find("access")
		if access=="private" or access=="no" then return end

		local h = highway
		local minzoom = 99
		local layer = "transportation"
		if majorRoadValues[highway] then              minzoom = 4 end
		if highway == "trunk"       then              minzoom = 5
		elseif highway == "primary" then              minzoom = 7 end
		if mainRoadValues[highway]  then              minzoom = 9 end
		if midRoadValues[highway]   then              minzoom = 11 end
		if minorRoadValues[highway] then h = "minor"; minzoom = 12 end
		if trackValues[highway]     then h = "track"; minzoom = 14 end
		if pathValues[highway]      then h = "path" ; minzoom = 14 end
		if h=="service"             then              minzoom = 12 end

		-- Links (ramp)
		local ramp=false
		if linkValues[highway] then
			splitHighway = split(highway, "_")
			highway = splitHighway[1]; h = highway
			ramp = true
			minzoom = 11
		end

		-- Construction
		local road_construction = false
		if highway == "construction" and (construction ~= "motorway" or has_falsy_tag(way, "bicycle")) then
			road_construction = true
			minzoom = 12
		end

		-- Write to layer
		if minzoom <= 14 then
			way:Layer(layer, false)
			way:MinZoom(minzoom)
			SetZOrder(way)
			way:Attribute("class", h)
			SetBrunnelAttributes(way)
			if ramp then way:AttributeNumeric("ramp",1) end

			if road_construction then way:AttributeNumeric("road_construction", 1) end

			-- No bike roads
			if has_falsy_tag(way, "bicycle") or has_thruthy_tag(way, "motorroad") then
				way:Attribute("no_bike", 1)
			end

			-- Service
			if highway == "service" and service ~="" then way:Attribute("service", service) end

			local oneway = way:Find("oneway")
			if oneway == "yes" or oneway == "1" then
				if has_falsy_tag(way, "oneway:bicycle") then
					way:AttributeNumeric("oneway", 2)
				else
					way:AttributeNumeric("oneway", 1)
				end
			end
			if oneway == "-1" then
				if has_falsy_tag(way, "oneway:bicycle") then
					way:AttributeNumeric("oneway", -2)
				else
					way:AttributeNumeric("oneway", -1)
				end
			end

			local has_cycleway = not_separate(way, "cycleway") or not_separate(way, "cycleway:left") or not_separate(way, "cycleway:right") or highway == "cycleway"
			if has_cycleway then
				way:AttributeNumeric("cycleway", 1)
			end

			way:Attribute("maxspeed", way:Find("maxspeed"))
			-- slow roads
			if get_maxspeed(way) < 40 or highway == "living_street" then
				way:AttributeNumeric("slow-road", 1)
			end

			if h=="track" and has_thruthy_tag(way, "bicycle") then
				local tracktype = way:Find("tracktype")
				local tracktypeArray = {"grade3", "grade2", "grade1"}
				local scale = way:Find("mtb:scale")
				if has_value(tracktypeArray, tracktype) or scale == 0 then
					way:Attribute("subclass", "bicycle")
				end
			end

			if way:Find("tunnel") == "yes" and (has_thruthy_tag(way, "bicycle") or has_cycleway) then
				if way:Holds("lit") and way:Find("lit") ~= "yes" then
					way:Attribute("lit", way:Find("lit"))
				end
				if way:Holds("opening_hours") then
					way:Attribute("opening_hours", way:Find("opening_hours"))
				end
				if way:Holds("bicycle:conditional") then
					way:Attribute("conditional_bike", way:Find("bicycle:conditional"))
				end
			end

			-- no snowplowing
			local current_month = os.date('%b')
			if has_falsy_tag(way, 'snowplowing') then
				if way:Holds('motor_vehicle:conditional') then -- eg. 'no @ Nov-May'
					local first, last = string.match(way:Find('motor_vehicle:conditional'), "(%u..)-(%u..)")
					if (monthMap[first] ~= nil and monthMap[current_month] >= monthMap[first]) or (monthMap[last] ~= nil and monthMap[current_month] <= monthMap[last]) then
						way:Attribute('snowplowing', 'no')
					end
				elseif way:Holds('opening_hours') then -- eg. 'Apr-Oct'
					local last, first = string.match(way:Find('opening_hours'), "(%u..)-(%u..)")
					if (monthMap[last] ~= nil and monthMap[current_month] > monthMap[last]) or (monthMap[first] ~= nil and monthMap[current_month] < monthMap[first]) then
						way:Attribute('snowplowing', 'no')
					end
				else -- default closed Nov-Feb
					if monthMap[current_month] >= monthMap['Nov'] or monthMap[current_month] <= monthMap['Feb'] then
						way:Attribute('snowplowing', 'no')
					end
				end
			end

			-- Write names
			if minzoom < 8 then
				minzoom = 8
			end
			if highway == "motorway" or highway == "trunk" then
				way:Layer("transportation_name", false)
				way:MinZoom(minzoom)
			elseif h == "minor" or h == "track" or h == "path" or h == "service" then
				way:Layer("transportation_name_detail", false)
				way:MinZoom(minzoom)
			else
				way:Layer("transportation_name_mid", false)
				way:MinZoom(minzoom)
			end
			SetNameAttributes(way)
			way:Attribute("class", h)
			way:Attribute("network","road") -- **** could also be us-interstate, us-highway, us-state
			if h~=highway then way:Attribute("subclass",highway) end
			local ref = way:Find("ref")
			if ref~="" then
				way:Attribute("ref",ref)
				way:AttributeNumeric("ref_length",ref:len())
			end
		end
	end

	-- Railways ('transportation' and 'transportation_name', plus 'transportation_name_detail')
	if railway~="" then
		way:Layer("transportation", false)
		way:Attribute("class", railway)
		SetZOrder(way)
		SetBrunnelAttributes(way)
		if service~="" then
			way:Attribute("service", service)
			way:MinZoom(12)
		else
			way:MinZoom(9)
		end

		way:Layer("transportation_name", false)
		SetNameAttributes(way)
		way:MinZoom(14)
		way:Attribute("class", "rail")
	end

	-- Pier
	if man_made=="pier" then
		way:Layer("transportation", isClosed)
		SetZOrder(way)
		way:Attribute("class", "pier")
		SetMinZoomByArea(way)
	end

	-- 'Ferry'
	if route=="ferry" then
		way:Layer("transportation", false)
		way:Attribute("class", "ferry")
		SetZOrder(way)
		way:MinZoom(9)
		SetBrunnelAttributes(way)

		way:Layer("transportation_name", false)
		SetNameAttributes(way)
		way:MinZoom(12)
		way:Attribute("class", "ferry")
	end

	-- 'Aeroway'
	if aeroway~="" then
		way:Layer("aeroway", isClosed)
		way:Attribute("class",aeroway)
		way:Attribute("ref",way:Find("ref"))
		write_name = true
	end

	-- 'aerodrome_label'
	if aeroway=="aerodrome" then
		way:LayerAsCentroid("aerodrome_label")
		SetNameAttributes(way)
		way:Attribute("iata", way:Find("iata"))
			SetEleAttributes(way)
		way:Attribute("icao", way:Find("icao"))

		local aerodrome = way:Find(aeroway)
		local class
		if aerodromeValues[aerodrome] then class = aerodrome else class = "other" end
		way:Attribute("class", class)
	end

	-- Set 'waterway' and associated
	if waterwayClasses[waterway] and not isClosed then
		if waterway == "river" and way:Holds("name") then
			way:Layer("waterway", false)
		else
			way:Layer("waterway_detail", false)
		end
		if way:Find("intermittent")=="yes" then way:AttributeNumeric("intermittent", 1) else way:AttributeNumeric("intermittent", 0) end
		way:Attribute("class", waterway)
		SetNameAttributes(way)
		SetBrunnelAttributes(way)
	elseif waterway == "boatyard"  then way:Layer("landuse", isClosed); way:Attribute("class", "industrial"); way:MinZoom(12)
	elseif waterway == "dam"       then way:Layer("building",isClosed)
	elseif waterway == "fuel"      then way:Layer("landuse", isClosed); way:Attribute("class", "industrial"); way:MinZoom(14)
	end
	-- Set names on rivers
	if waterwayClasses[waterway] and not isClosed then
		if waterway == "river" and way:Holds("name") then
			way:Layer("water_name", false)
		else
			way:Layer("water_name_detail", false)
			way:MinZoom(14)
		end
		way:Attribute("class", waterway)
		SetNameAttributes(way)
	end

	-- Set 'building' and associated
	if building~="" then
		way:Layer("building", true)
		SetBuildingHeightAttributes(way)
		SetMinZoomByArea(way)
	end

	-- Set 'housenumber'
	if housenumber~="" then
		way:LayerAsCentroid("housenumber", false)
		way:Attribute("housenumber", housenumber)
	end

	-- Set 'water'
	if natural=="water" or natural=="bay" or leisure=="swimming_pool" or landuse=="reservoir" or landuse=="basin" or waterClasses[waterway] then
		if way:Find("covered")=="yes" or not isClosed then return end
		local class="lake"; if natural=="bay" then class="ocean" elseif waterway~="" then class="river" end
		if class=="lake" and way:Find("wikidata")=="Q192770" then return end
		if class=="ocean" and isClosed and (way:AreaIntersecting("ocean")/way:Area() > 0.98) then return end
		way:Layer("water",true)
		SetMinZoomByArea(way)
		way:Attribute("class",class)

		if way:Find("intermittent")=="yes" then way:Attribute("intermittent",1) end
		-- we only want to show the names of actual lakes not every man-made basin that probably doesn't even have a name other than "basin"
		-- examples for which we don't want to show a name:
		--  https://www.openstreetmap.org/way/25958687
		--  https://www.openstreetmap.org/way/27201902
		--  https://www.openstreetmap.org/way/25309134
		--  https://www.openstreetmap.org/way/24579306
		if way:Holds("name") and natural=="water" and water ~= "basin" and water ~= "wastewater" then
			way:LayerAsCentroid("water_name_detail")
			SetNameAttributes(way)
			SetMinZoomByArea(way)
			way:Attribute("class", class)
		end

		return -- in case we get any landuse processing
	end

	-- Set 'landcover' (from landuse, natural, leisure)
	local l = landuse
	if l=="" then l=natural end
	if l=="" then l=leisure end
	if landcoverKeys[l] then
		way:Layer("landcover", true)
		SetMinZoomByArea(way)
		way:Attribute("class", landcoverKeys[l])
		if l=="wetland" then way:Attribute("subclass", way:Find("wetland"))
		else way:Attribute("subclass", l) end
		write_name = true

	-- Set 'landuse'
	else
		if l=="" then l=amenity end
		if l=="" then l=tourism end
		if landuseKeys[l] then
			way:Layer("landuse", true)
			way:Attribute("class", l)
			if l=="residential" then
				if way:Area()<ZRES8^2 then way:MinZoom(8)
				else SetMinZoomByArea(way) end
			else way:MinZoom(11) end
			write_name = true
		end
	end

	-- Parks
	-- **** name?
	if     boundary=="national_park" then way:Layer("park",true); way:Attribute("class",boundary); SetNameAttributes(way)
	elseif leisure=="nature_reserve" then way:Layer("park",true); way:Attribute("class",leisure ); SetNameAttributes(way) end

	-- Leisure tracks
	if leisure=="track" then
		way:Layer("landuse", true)
		SetNameAttributes(way)
		local sportType = way:Find("sport")
		if string.find(sportType, "bmx") or string.find(sportType, "cycling") then
			way:Attribute("sport", "bike")
			way:Attribute("class", "leisure")
			way:Attribute("subclass", "track")
		elseif sportType=="athletics" then
			way:Attribute("class", "pitch")
		end
	end

	if man_made=="bridge" then
		way:Layer("transportation_name", false)
		SetNameAttributes(way)
		way:Attribute("man_made", "bridge")
	end

	-- POIs ('poi' and 'poi_detail')
	local rank, class, subclass = GetPOIRank(way)
	if rank then WritePOI(way,class,subclass,rank); return end

	-- Catch-all
	if (building~="" or write_name) and way:Holds("name") then
		way:LayerAsCentroid("poi_detail")
		SetNameAttributes(way)
		if write_name then rank=6 else rank=25 end
		way:AttributeNumeric("rank", rank)
	end
end

-- Remap coastlines
function attribute_function(attr,layer)
	if attr["featurecla"]=="Glaciated areas" then
		return { subclass="glacier" }
	elseif attr["featurecla"]=="Antarctic Ice Shelf" then
		return { subclass="ice_shelf" }
	elseif attr["featurecla"]=="Urban area" then
		return { class="residential" }
	else
		return { class="ocean" }
	end
end

function has_thruthy_tag(item, tag)
	return item:Holds(tag) and item:Find(tag)~="no"
end

function has_falsy_tag(item, tag)
	return item:Holds(tag) and item:Find(tag)=="no"
end

function not_separate(item, tag)
	return has_thruthy_tag(item, tag) and item:Find(tag)~="separate"
end

function has_value(arr, val)
	for i, value in ipairs(arr) do
		if value == val then
			return true
		end
	end
	return false
end

function get_maxspeed(item)
	local value = item:Find("maxspeed")
	if value == nil then
		return 500
	end

	local number_value = tonumber(value)

	if number_value == nil then
		return 500
	end

	return number_value
end

-- ==========================================================
-- Common functions

-- Write a way centroid to POI layer
function WritePOI(obj,class,subclass,rank)
	local layer = "poi"
	if rank>4 then layer="poi_detail" end
	obj:LayerAsCentroid(layer)
	SetNameAttributes(obj)
	obj:Attribute("class", class)
	obj:Attribute("subclass", subclass)

	if subclass=="bicycle_parking" then
		local access = obj:Find("access")

		if access=="customers" and obj:Find("fee")=="yes" and obj:Holds("operator") and obj:Find("operator"):startswith("Bane") then
			obj:Attribute("type", "shed")
			obj:Attribute("capacity", obj:Find("capacity"))
			obj:AttributeNumeric("rank", 13)
		elseif obj:Find("bicycle_parking")=="lockers" then
			obj:Attribute("type", "lockers")
			obj:AttributeNumeric("rank", 15)
		elseif obj:Find("covered")=="yes" then
			obj:Attribute("type", "covered")
			obj:AttributeNumeric("rank", 17)
		elseif access=="private" or access=="no" then
			obj:AttributeNumeric("private", 1)
			obj:AttributeNumeric("rank", 25)
		else
			obj:AttributeNumeric("rank", 19)
		end
	elseif subclass=="bicycle_repair_station" then
		obj:Attribute("pump", obj:Find("service:bicycle:pump"))
		obj:Attribute("tools", obj:Find("service:bicycle:tools"))
		if has_thruthy_tag(obj, "service:bicycle:pump") then
			obj:AttributeNumeric("rank", 21)
		elseif has_thruthy_tag(obj, "service:bicycle:tools") then
			obj:AttributeNumeric("rank", 23)
		else
			obj:AttributeNumeric("rank", rank)
		end
	else
		obj:AttributeNumeric("rank", rank)
	end

	if subclass=="sports" then
		local isBike = "no"
		local repair = obj:Find("service:bicycle:repair") == "yes"
		local retail = obj:Find("service:bicycle:retail") == "yes"
		local second_hand = obj:Find("service:bicycle:second_hand") == "yes"
		if repair or retail or second_hand then
			isBike = "yes"
		end
		obj:Attribute("bike", isBike)
	end

	if class=="tourism" and subclass=="information" and obj:Holds("information") and obj:Find("information") == "office" then
		obj:Attribute("office", 1)
	end

	if class=="campsite" and (has_thruthy_tag(obj, "tents") or has_thruthy_tag(obj, "cabins")) then
		obj:Attribute("sleep", 1)
	end

	if subclass=="shelter" and obj:Holds("shelter_type") then
		obj:Attribute("shelter_type", obj:Find("shelter_type"))
	end

	if class=="toilet" then
		obj:Attribute("fee", obj:Find("fee"))
		obj:Attribute("opening_hours", obj:Find("opening_hours"))
	end
end

-- Set name attributes on any object
function SetNameAttributes(obj)
	local name = obj:Find("name"), iname
	local main_written = name
	-- if we have a preferred language, then write that (if available), and additionally write the base name tag
	if preferred_language and obj:Holds("name:"..preferred_language) then
		iname = obj:Find("name:"..preferred_language)
		obj:Attribute(preferred_language_attribute, iname)
		if iname~=name and default_language_attribute then
			obj:Attribute(default_language_attribute, name)
		else main_written = iname end
	else
		obj:Attribute(preferred_language_attribute, name)
	end
	-- then set any additional languages
	for i,lang in ipairs(additional_languages) do
		iname = obj:Find("name:"..lang)
		if iname=="" then iname=name end
		if iname~=main_written then obj:Attribute("name:"..lang, iname) end
	end
end

-- Set ele and ele_ft on any object
function SetEleAttributes(obj)
    local ele = obj:Find("ele")
	if ele ~= "" then
		local meter = math.floor(tonumber(ele) or 0)
		local feet = math.floor(meter * 3.2808399)
		obj:AttributeNumeric("ele", meter)
		obj:AttributeNumeric("ele_ft", feet)
    end
end

function SetBrunnelAttributes(obj)
	if     obj:Find("bridge") == "yes" then obj:Attribute("brunnel", "bridge")
	elseif obj:Find("tunnel") == "yes" then obj:Attribute("brunnel", "tunnel")
	elseif obj:Find("ford")   == "yes" then obj:Attribute("brunnel", "ford")
	end
end

-- Set minimum zoom level by area
function SetMinZoomByArea(way)
	local area=way:Area()
	if     area>ZRES5^2  then way:MinZoom(6)
	elseif area>ZRES6^2  then way:MinZoom(7)
	elseif area>ZRES7^2  then way:MinZoom(8)
	elseif area>ZRES8^2  then way:MinZoom(9)
	elseif area>ZRES9^2  then way:MinZoom(10)
	elseif area>ZRES10^2 then way:MinZoom(11)
	elseif area>ZRES11^2 then way:MinZoom(12)
	elseif area>ZRES12^2 then way:MinZoom(13)
	else                      way:MinZoom(14) end
end

-- Calculate POIs (typically rank 1-4 go to 'poi' z12-14, rank 5+ to 'poi_detail' z14)
-- returns rank, class, subclass
function GetPOIRank(obj)
	local k,list,v,class,rank

	-- Can we find the tag?
	for k,list in pairs(poiTags) do
		if list[obj:Find(k)] then
			v = obj:Find(k)	-- k/v are the OSM tag pair
			class = poiClasses[v] or k
			rank  = poiClassRanks[class] or 25
			return rank, class, v
		end
	end

	-- Catch-all for shops
	local shop = obj:Find("shop")
	if shop~="" then return poiClassRanks['shop'], "shop", shop end

	-- Nothing found
	return nil,nil,nil
end

function SetBuildingHeightAttributes(way)
	local height = tonumber(way:Find("height"), 10)
	local minHeight = tonumber(way:Find("min_height"), 10)
	local levels = tonumber(way:Find("building:levels"), 10)
	local minLevel = tonumber(way:Find("building:min_level"), 10)

	local renderHeight = BUILDING_FLOOR_HEIGHT
	if height or levels then
		renderHeight = height or (levels * BUILDING_FLOOR_HEIGHT)
	end
	local renderMinHeight = 0
	if minHeight or minLevel then
		renderMinHeight = minHeight or (minLevel * BUILDING_FLOOR_HEIGHT)
	end

	-- Fix upside-down buildings
	if renderHeight < renderMinHeight then
		renderHeight = renderHeight + renderMinHeight
	end

	way:AttributeNumeric("render_height", renderHeight)
	way:AttributeNumeric("render_min_height", renderMinHeight)
end

-- Implement z_order as calculated by Imposm
-- See https://imposm.org/docs/imposm3/latest/mapping.html#wayzorder for details.
function SetZOrder(way)
	local highway = way:Find("highway")
	local layer = tonumber(way:Find("layer"))
	local bridge = way:Find("bridge")
	local tunnel = way:Find("tunnel")
	local zOrder = 0
	if bridge ~= "" and bridge ~= "no" then
		zOrder = zOrder + 10
	elseif tunnel ~= "" and tunnel ~= "no" then
		zOrder = zOrder - 10
	end
	if not (layer == nil) then
		if layer > 7 then
			layer = 7
		elseif layer < -7 then
			layer = -7
		end
		zOrder = zOrder + layer * 10
	end
	local hwClass = 0
	-- See https://github.com/omniscale/imposm3/blob/53bb80726ca9456e4a0857b38803f9ccfe8e33fd/mapping/columns.go#L251
	if highway == "motorway" then
		hwClass = 9
	elseif highway == "trunk" then
		hwClass = 8
	elseif highway == "primary" then
		hwClass = 6
	elseif highway == "secondary" then
		hwClass = 5
	elseif highway == "tertiary" then
		hwClass = 4
	else
		hwClass = 3
	end
	zOrder = zOrder + hwClass
	way:ZOrder(zOrder)
end

-- ==========================================================
-- Lua utility functions

function split(inputstr, sep) -- https://stackoverflow.com/a/7615129/4288232
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

function string:startswith(start)
  return self:sub(1, #start) == start
end


-- vim: tabstop=2 shiftwidth=2 noexpandtab
