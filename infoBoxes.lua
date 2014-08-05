_addon.name = 'infoBoxes'
_addon.author = 'Lorand'
_addon.commands = {'infoBoxes', 'ib'}
_addon.version = '1.0'

require('sets')
local InfoBox = require('infoBox')

local strat_charge_time = {[1]=240,[2]=120,[3]=80,[4]=60,[5]=48}

local stratSettings = {pos = {x = -200, y = -20}, flags = {bottom = true, right = true}}
local targetSettings = {pos = {x = -125, y = 250}, flags = {bottom = false, right = true}}
local targHpSettings = {pos = {x = -125, y = 270}, flags = {bottom = false, right = true}}
local targTpSettings = {pos = {x = -125, y = 290}, flags = {bottom = false, right = true}}

local boxes = {}
local player

windower.register_event('load', 'login', function()
	player = windower.ffxi.get_player()
	boxes.stratagems = InfoBox.new(stratSettings, 'Stratagems')
	boxes.target = InfoBox.new(targetSettings)
	boxes.targHp = InfoBox.new(targHpSettings, 'HP')
	boxes.targTp = InfoBox.new(targTpSettings, 'TP')
end)

windower.register_event('logout', function()
	player = nil
end)

windower.register_event('addon command', function(command,...)
    command = command and command:lower() or 'help'
    local args = {...}
	
	if command == 'reload' then
		windower.send_command('lua unload '.._addon.name..'; lua load '.._addon.name)
	elseif command == 'unload' then
		windower.send_command('lua unload '.._addon.name)
	else
		windower.add_to_chat(0, 'Error: Unable to parse valid command')
	end
end)

windower.register_event('prerender', function()
	if player then
		if S{player.main_job, player.sub_job}:contains('SCH') then
			boxes.stratagems:updateContents(get_available_stratagem_count())
		else
			boxes.stratagems:hide()
		end
		
		local target = windower.ffxi.get_mob_by_target()
		if target ~= nil then
			boxes.target:updateContents(target.name)
			boxes.targHp:updateContents(target.hpp..'%')
			boxes.targTp:updateContents(target.tp)
		else
			boxes.target:hide()
			boxes.targHp:hide()
			boxes.targTp:hide()
		end
	else
		for _,box in pairs(boxes) do
			box:hide()
		end
	end
end)

--[[
	Calculates and returns the maximum number of SCH stratagems available for use.
--]]
function get_max_stratagem_count()
	if S{player.main_job, player.sub_job}:contains('SCH') then
		local lvl = player.main_job == 'SCH' and player.main_job_level or player.sub_job_level
		return math.floor(((lvl  - 10) / 20) + 1)
	else
		return 0
	end
end

--[[
	Calculates the number of SCH stratagems that are currently available for use. Calculated from the combined recast timer for stratagems and the maximum number
	of stratagems that are available.  The recast time for each stratagem charge corresponds directly with the maximum number of stratagems that can be used.
--]]
function get_available_stratagem_count()
	local recastTime = windower.ffxi.get_ability_recasts()[231] or 0
	local maxStrats = get_max_stratagem_count()
	if maxStrats == 0 then return 0 end
	local stratsUsed = (recastTime/strat_charge_time[maxStrats]):ceil()
	return maxStrats - stratsUsed
end

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2014, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of info nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------