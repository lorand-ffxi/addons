

function addBuff(name, ...)
	local args = {...}
	if players[name] ~= nil then
		for _,arg in pairs(args) do
			local spell = res.spells:with('name', arg)
			local ability = res.abilities:with('name', arg)
			if spell ~= nil then
				if players[name].buffs[spell.name] == nil then
					players[name].buffs[spell.name] = 1
				end
			elseif ability ~= nil then
				if players[name].buffs[ability.name] == nil then
					players[name].buffs[ability.name] = 2
				end
			else
				atc('Error: Unable to add invalid spell to desired buff list: '..arg)
			end
		end
	else
		atc('Error: Unable to add desired buffs to unmonitored player: '..name)
	end
end

--[[
	Returns a list of buffs that are missing from the given player
--]]
function getMissingBuffs(name)
	
end




-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2014, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of ffxiHealer nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------