local cursor = {}

local player_data = require("scripts.player-data")

function cursor.check_stack(cursor_stack, cursor_ghost)
  if cursor_stack and cursor_stack.valid_for_read then
    return cursor_stack.name
  elseif cursor_ghost then
    return cursor_ghost.name
  else
    return
  end
end

function cursor.set_stack(player, cursor_stack, player_table, item_name)
  local is_cheating = player.cheat_mode or (player.controller_type == defines.controllers.editor)
  local spawn_item = player_table.settings.spawn_items_when_cheating

  -- space exploration - don't spawn items when in the satellite view
  if script.active_mods["space-exploration"] and player.controller_type == defines.controllers.god then
    spawn_item = false
  end

  -- main inventory
  player_data.ensure_valid_inventory(player, player_table)
  local main_inventory = player_table.main_inventory

  -- set cursor stack
  local item_stack, item_stack_index = main_inventory.find_item_stack(item_name)
  if item_stack and item_stack.valid then
    if player.clean_cursor() then
      -- actually transfer from the main inventory, then set the hand location
      cursor_stack.transfer_stack(item_stack)
      player.hand_location = {inventory=main_inventory.index, slot=item_stack_index}
    end
    return true
  elseif spawn_item and is_cheating then
    local stack_spec = {name=item_name, count=game.item_prototypes[item_name].stack_size}
    -- insert into main inventory first, then transfer and set the hand location
    if main_inventory.can_insert(stack_spec) and player.clean_cursor() then
      main_inventory.insert(stack_spec)
      local new_stack, new_stack_index = main_inventory.find_item_stack(item_name)
      cursor_stack.transfer_stack(new_stack)
      player.hand_location = {inventory=main_inventory.index, slot=new_stack_index}
    else
      player.print{"cen-message.main-inventory-full"}
    end
    return true
  else
    local place_result = game.item_prototypes[item_name].place_result
    if place_result and player.clean_cursor() then
      player_table.last_item = item_name
      player.cursor_ghost = item_name
      return true
    else
      return false
    end
  end
end

function cursor.scroll(player_index, direction)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  local cursor_stack = player.cursor_stack
  local current_item = cursor.check_stack(cursor_stack, player.cursor_ghost)

  if current_item then
    -- check personal registry, then the global registry
    local registry = player_table.registry[current_item]
    if not registry or not registry[direction] then
      registry = global.registry[current_item]
    end
    -- set stack
    if registry and registry[direction] then
      cursor.set_stack(player, cursor_stack, player_table, registry[direction])
    end
  end
end

return cursor