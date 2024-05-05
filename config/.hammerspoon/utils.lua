local M = {}

function M.deepMerge(tbl1, tbl2)
	for k, v in pairs(tbl2) do
		if type(v) == 'table' and type(tbl1[k]) == 'table' then
			-- If it's a list, then concat
			if v[1] ~= nil and tbl1[k][1] ~= nil then
				tbl1[k] = hs.fnutils.concat(tbl1[k], v)
			else
				-- Otherwise it's a map
				tbl1[k] = M.deepMerge(tbl1[k], v)
			end
		else
			tbl1[k] = v
		end
	end
	return tbl1
end

return M
