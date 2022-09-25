-- vi:set sw=4 ts=4 ai sm:
-- This module implements the backend logic for displaying the two types
-- of ˈsyˌmiŋˍhou (punctuation mark for indicating the title of a citable
-- work in Chinese languages)

require ('Module:No globals');
local p = {};

-- Return a value that should be suitable for use as an alt or aria-label
-- and safe to use for double-quoting
local function build_aria_label_from( s )
	return	mw.ustring.gsub(
			mw.ustring.gsub(s,
				'"', '”'), 
				"'", '’')
end

-- Build a type 2 citable using the correct quotation marks
-- and, if needed, inner separator
local function build_type_2_citable( work, part )
	local it;
	local class;
	local prefix;
	local suffix;
	local root;
	if work == nil then															-- error
		-- do nothing for now
	elseif part ~= nil then
		class = 'pin1ming4';
		prefix = '〈';
		suffix = '〉';
		if work ~= nil then
			root = work .. '・' .. part;										-- dot = U+30FB
		else
			root = part;
		end
	else
		class = 'syu1ming4';
		prefix = '《';
		suffix = '》';
		root = work;
	end
	local alt = prefix .. build_aria_label_from(root) .. suffix;
	prefix = '<span class=hoi1-adj>' .. prefix .. '</span>';
	suffix = '<span class=saan1-adj>'.. suffix .. '</span>';
	it = '<span class = "' .. class .. '-b" aria-label="' .. alt .. '">' 
			.. prefix .. root .. suffix 
			.. '</span>';
	return it;
end

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
		it = build_type_2_citable(s, nil)
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

