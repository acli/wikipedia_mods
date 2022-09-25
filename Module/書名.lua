-- vi:set sw=4 ts=4 ai sm:
-- This module implements the backend logic for displaying the two types
-- of ˈsyˌmiŋˍhou (punctuation mark for indicating the title of a citable
-- work in Chinese languages)

require ('Module:No globals');
local p = {};

-- Stringify something to a form suitable for debugging and error messages
local function cvs( s )
	if s == nil then
		s= '<b>null</b>';
	end
	return s;
end

-- Return a sanitized version of an argument value
local function sanitize( arg )
	if arg ~= nil and arg:match('^{{{%w-}}}$') then
		arg = nil
	end
	return arg;
end

-- Return a value that should be suitable for use as an alt or aria-label
-- and safe to use for double-quoting
local function build_aria_label_from( s )
	return	mw.ustring.gsub(
			mw.ustring.gsub(
			mw.ustring.gsub(s,
				'<[^<>]*>', ''),												-- try to nuke tags
				'"', '”'), 
				"'", '’')
end

-- Build a type 1 part (not necessarily the entire title)
local function build_type_1_part( s )
	local it;
	it = '';
	for i = 1, mw.ustring.len(s), 1 do
		local c = mw.ustring.sub(s, i, i);
		it = it .. '<span class=zi6>' .. c .. '</span>';						-- wrap each character
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
			infix = '・';														-- U+30FB
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

		alt = prefix .. build_aria_label_from(part1 .. infix .. part2) .. suffix;
	elseif part1 ~= nil then
		alt = prefix .. build_aria_label_from(part1) .. suffix;
	end
	it = mw.ustring.gsub(it, '(</span>)$', '<span class=saan1>' ..suffix .. '</span>%1');
	it = '<span aria-label="' .. alt .. '">' .. it .. '</span>';
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
			root = work .. '・' .. part;										-- dot = U+30FB
		else
			root = part;
		end
	elseif work ~= nil then
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
	local parent = frame:getParent();
	local s1 = sanitize(parent.args[1]);
	local s2 = sanitize(parent.args[2]);
	local title = sanitize(parent.args['title']);
	local chapter = sanitize(parent.args['chapter']);
	local type = frame.args['type'];
	local it;
	local alt = '';
	local styles = 'Module:書名/styles.css';
	local work, part;
	
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
		type = '1';
	end
	
	-- build it
	if work == nil and part == nil then
		it = '書名模出錯，搵唔到書名，又搵唔到篇名（s1=' .. cvs(s1)
			.. '，s2=' .. cvs(s2)
			.. '，title=' .. cvs(title)
			.. '，chapter=' .. cvs(chapter)
			.. '）'
	elseif type == '2' then														-- 乙式
		it = build_type_2_citable(work, part)
	else																		-- 甲式
		it = build_type_1_citable(work, part)
	end
	
	-- request our style sheet
	it = table.concat ({
			frame:extensionTag ('templatestyles', '', {src=styles}),
			it
		});
	return it;
end
return p;
