local global_data = {}

local constants = require("constants")

local util = require("scripts.util")

function global_data.init()
  global.players = {}
  global.proxies = {
    -- proxy unit_number -> target unit_number
    by_proxy = {},
    -- target unit_number -> proxy entity
    by_target = {}
  }

  global_data.build_global_registry()
end

-- build the default upgrade/downgrade registry
function global_data.build_global_registry()
  local entity_prototypes = game.entity_prototypes
  local item_prototypes = game.item_prototypes
  local data = {}

  -- auto-generated
  for name, prototype in pairs(entity_prototypes) do
    if prototype.next_upgrade and prototype.items_to_place_this then
      local next_item = prototype.next_upgrade.name
      for _, item in ipairs(prototype.items_to_place_this) do
        if not data[item.name] then data[item.name] = {} end
        data[item.name].next = next_item
      end
      for _, item in ipairs(entity_prototypes[next_item].items_to_place_this) do
        if not data[item.name] then data[item.name] = {} end
        data[item.name].previous = name
      end
    end
  end

  -- default overrides
  for mod_name, overrides in pairs(constants.default_overrides) do
    if script.active_mods[mod_name] then
      util.apply_overrides(data, overrides, item_prototypes)
    end
  end

  global.registry = data
end

return global_data