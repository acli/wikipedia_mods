require ('Module:No globals');
local p = {};

p.Syu1meng2 = function( frame )
	local s = frame.args[1];
	local type = frame.args['type'];
	local it;
	local alt = '';
	local styles = 'Module:書名/styles.css';
	if type == nil or type:match('^{{{.-}}}$') then								-- 冇寫邊式
		type = '1';
	end
	if type == '2' then															-- 乙式
		it = '《' .. s .. '》';
	else																		-- 甲式
		it = '';
		for i = 1, mw.ustring.len(s), 1 do
			local c = mw.ustring.sub(s, i, i);
			it = it .. '<span class=zi6>' .. c .. '</span>';					-- wrap each character
			if mw.ustring.match(c, '^[^<>"' .. "'" .. ']$') then				-- update alt if it looks safe
				alt = alt .. c;
			end
		end
		
		-- build HTML tag with fallback and aria-label
		it = '<span class=hoi1>《</span>' .. it .. '<span class=saan1>》</span>';
		it = '<span class=syu1ming4 aria-label="《' .. alt .. '》">' .. it .. '</span>';
		
		-- request our style sheet, which is needed for type 1 to work
		it = table.concat ({
			frame:extensionTag ('templatestyles', '', {src=styles}),
			it
		});
	end
	return it;
end
return p;

