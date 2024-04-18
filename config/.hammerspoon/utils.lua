local M = {}

function M.deepMerge(tbl1, tbl2)
	local merged = {}

	-- Merge values from tbl1
	for k, v in pairs(tbl1) do
		if type(v) == 'table' and type(tbl2[k]) == 'table' then
			-- If both values are tables, recursively merge them
			merged[k] = M.deepMerge(v, tbl2[k])
		else
			-- Otherwise, overwrite or add the value
			merged[k] = v
		end
	end

	-- Merge values from tbl2
	for k, v in pairs(tbl2) do
		if type(v) == 'table' and type(tbl1[k]) == 'table' then
			-- If both values are tables, they've been handled in the first loop
		elseif merged[k] ~= nil then
			-- If the key already exists in merged, overwrite it
			merged[k] = v
		else
			-- Otherwise, add the value
			merged[k] = v
		end
	end

	return merged
end

return M
