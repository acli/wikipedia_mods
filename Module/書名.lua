-- vi:set sw=4 ts=4 ai sm:
---- This module implements the backend logic for displaying the two types
---- of ˈsyˌmiŋˍhou (punctuation mark for indicating the title of a citable
---- work in Chinese languages)

require ('Module:No globals');
local p = {};

--- Debugging functions -------------------------------------------------------

-- Stringify something to a form suitable for debugging and error messages
local function cvs( s )
	if s == nil then
		s= '<b>null</b>';
	end
	return s;
end

--- Auxiliaries ---------------------------------------------------------------

-- Return a sanitized version of an argument value
local function sanitize( arg )
	if arg ~= nil and arg:match('^{{{%w-}}}$') then
		arg = nil
	end
	return arg;
end

-- Canonicalize the type parameter
local function canonicalize_type_value( type )
	if type == '甲' then
		type = '1'
	elseif type == '乙' then
		type = '2'
	end
	return type;
end

-- Return a value that should be suitable for use as an alt or aria-label
-- and safe to use for double-quoting
local function build_aria_label_from( s )
	if s == nil then
		return s;
	end
	return	mw.ustring.gsub(
			mw.ustring.gsub(
			mw.ustring.gsub(s,
				'<[^<>]*>', ''),					-- try to nuke tags
				'"', '”'), 
				"'", '’')
end

-- Build a type 1 part (not necessarily the entire title)
local function build_type_1_part( s )
	local it;
	it = '';
	for i = 1, mw.ustring.len(s), 1 do
		local c = mw.ustring.sub(s, i, i);
		it = it .. '<span class=zi6>' .. c .. '</span>';	-- wrap each char
	end
	return it;
end

-- Build a type 1 citable with type 2 as a fallback
local function build_type_1_citable( work, part )
	local it;
	local part1, part2;
	local class1, class2;
	local prefix, suffix;
	local infix = '';
	if part ~= nil then
		prefix = '〈';
		suffix = '〉';
		if work ~= nil then
			infix = '・';							-- U+30FB
			part1 = build_type_1_part(work);
			part2 = build_type_1_part(part);
			class1 = 'syu1ming4';
			class2 = 'pin1ming4';
		else
			part1 = build_type_1_part(part);
			class1 = 'pin1ming4';
		end
	elseif work ~= nil then
		part1 = build_type_1_part(work);
		class1 = 'syu1ming4';
		prefix = '《';
		suffix = '》';
	end
	local alt;

	-- build HTML tag with fallback and aria-label
	it = '';
	if part1 ~= nil then
		it = it .. '<span class=' .. class1 .. '>'
				.. '<span class=hoi1>' .. prefix .. '</span>'
				.. part1
				.. '</span>';
	end
	if part2 ~= nil then
		it = it .. '<span class=' .. class2 .. '>'
				..' <span class=fan1gaak3>' .. infix .. '</span>'
				.. part2
				.. '</span>';

		if part1 ~= nil then
			alt = prefix .. build_aria_label_from(part1..infix..part2) .. suffix;
		else
			alt = prefix .. build_aria_label_from(part2) .. suffix;
		end
	elseif part1 ~= nil then
		alt = prefix .. build_aria_label_from(part1) .. suffix;
	end
	if it ~= nil then
		it = mw.ustring.gsub(it,
							'(</span>)$',
							'<span class=saan1>' ..suffix .. '</span>%1');
					
		it = '<span aria-label="' .. alt .. '">' .. it .. '</span>';
	end
	return it;
end

-- Build a type 2 citable using the correct quotation marks
-- and, if needed, inner separator
local function build_type_2_citable( work, part )
	local it;
	local class;
	local prefix;
	local suffix;
	local root;
	if part ~= nil then
		class = 'pin1ming4';
		prefix = '〈';
		suffix = '〉';
		if work ~= nil then
			root = work .. '・' .. part;			-- dot = U+30FB
		else
			root = part;
		end
	elseif work ~= nil then
		class = 'syu1ming4';
		prefix = '《';
		suffix = '》';
		root = work;
	end
	if root ~= nil then
		local alt = prefix .. build_aria_label_from(root) .. suffix;
		prefix = '<span class=hoi1-adj>' .. prefix .. '</span>';
		suffix = '<span class=saan1-adj>'.. suffix .. '</span>';
		it = '<span class = "' .. class .. '-b" aria-label="' .. alt .. '">' 
				.. prefix .. root .. suffix 
				.. '</span>';
	end
	return it;
end

-- Check if the given string is (believed to be) CJK
local function cjk_p( s )
	return mw.ustring.match(s, '^['
			.. '⺀-䶿'								-- 2E80-4DBF
			.. '一-鿿'								-- 4E00-9FFF
			.. '가-힯'								-- AC00-D7AF
			.. '豈-﫿'								-- F900-FAFF
			.. '︰-﹏'								-- FE30-FE4F
			.. '！-｠'								-- FF01-FF60
			.. '𠀀-𯨟'								-- 20000-2FA1F
			.. ']+$');
end

-- Analyze the given title(s) and decide if type 1 is safe to use
local function determine_which_type_to_use( work, part )
	local type;
	local det;
	if work ~= nil and part ~= nil then
		det = work .. part;
	elseif work ~= nil then
		det = work;
	elseif part ~= nil then
		det = part;
	else
		det = '';
	end
	if cjk_p(det) then
		type = '1';
	else
		type = '2';
	end
	return type;
end

--- Exported, invocable functions ---------------------------------------------

p.Syu1meng2 = function( frame )
	local parent = frame:getParent();
	local s1 = sanitize(parent.args[1]);
	local s2 = sanitize(parent.args[2]);
	local title = sanitize(parent.args['title']);
	local chapter = sanitize(parent.args['chapter']);
	local type = sanitize(frame.args['type']);
	local it;
	local alt = '';
	local styles = 'Module:書名/styles.css';
	local work, part;
	local error;
	
	-- figure out what is actually being marked up as a citable
	if s1 ~= nil and s2 ~= nil then
		work = s1;
		part = s2;
	elseif s1 ~= nil and chapter ~= nil then
		work = s1;
		part = chapter;
	elseif s1 == nil and chapter ~= nil then
		part = chapter;
	elseif s1 == nil and title ~= nil then
		work = title;
	elseif title ~= nil and chapter ~= nil then
		work = title;
		part = chapter;
	elseif s1 ~= nil then
		work = s1;
	elseif s2 ~= nil then
		part = s2;
	end
	
	-- fixup default type
	if type == nil then
		type = 'auto';
	end
	
	-- if type=auto is requested, analyze the title(s) and choose 1 or 2
	if type == 'auto' then
		type = determine_which_type_to_use(work, part)
	else
		type = canonicalize_type_value(type);
	end
	
	-- build it
	if work == nil and part == nil then
		if error == nil then
			error = '書名模出錯，搵唔到書名，又搵唔到篇名';
		end
	elseif type == '1' then							-- 甲式 (type 1)
		it = build_type_1_citable(work, part)
	elseif type == '2' then							-- 乙式 (type 2)
		it = build_type_2_citable(work, part)
	else
		error = '唔明'..cvs(type)..'式書名號係乜';
	end

	if it == nil and error ~= nil then
		it = '<span class=error>' .. error .. '</span>'
			.. '（s1=' .. cvs(s1)
			.. '，s2=' .. cvs(s2)
			.. '，title=' .. cvs(title)
			.. '，chapter=' .. cvs(chapter)
			.. '）'
	end
	
	-- request our style sheet
	it = table.concat ({
			frame:extensionTag ('templatestyles', '', {src=styles}),
			it
		});
	return it;
end

--- Non-invocable internal functions exported for other modules to use --------

p.cjk_p = cjk_p;
p.determine_which_type_to_use = determine_which_type_to_use;
p.build_type_1_citable = build_type_1_citable;
p.build_type_2_citable = build_type_2_citable;
return p;
