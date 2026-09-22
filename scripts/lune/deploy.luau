-- Required environment variables: DEPLOY_API_KEY, UNIVERSE_ID, and PLACE_ID
-- DEPLOY_API_KEY should be an OpenCloud API key with `universe-places:write` access

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local outputPath = "rojo-project-template.rbxlx"
local apiKey = process.env.DEPLOY_API_KEY
local universeId = process.env.UNIVERSE_ID
local placeId = process.env.PLACE_ID
local rojo = process.env.ROJO_PATH or `{process.env.HOME}/.rokit/bin/rojo`

assert(apiKey, "DEPLOY_API_KEY is required")
assert(universeId, "UNIVERSE_ID is required")
assert(placeId, "PLACE_ID is required")

-- Use rojo to build the initial place file
local build = process.exec(rojo, { "build", "-o", outputPath })
assert(build.ok, "Rojo build failed")

-- Use lune to do modifications to the place file, in this case: remove all PackageLinks to ensure a stable deployment
local game = roblox.deserializePlace(fs.readFile(outputPath))

for _, instance in game:GetDescendants() do
	if instance:IsA("PackageLink") then
		instance:Destroy()
	end
end

local modifiedGame = roblox.serializePlace(game)

-- Upload the new file to Roblox using OpenCloud endpoint
local response = net.request({
	url = `https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published`,
	method = "POST",
	headers = {
		["x-api-key"] = apiKey,
		["Content-Type"] = "application/octet-stream",
	},
	body = modifiedGame,
})

assert(response.ok, `Deployment failed ({response.statusCode} - {response.statusMessage}): {response.body}`)
print(`Published place version: {response.body}`)
