-- vi:set sw=4 ts=4 ai sm:
---- This module implements the backend logic for displaying the two types
---- of ˈsyˌmiŋˍhou (punctuation mark for indicating the title of a citable
---- work in Chinese languages)

require ('Module:No globals');
local p = {};

--- Debugging functions -------------------------------------------------------

-- Stringify something into a form suitable for debugging and error messages
-- (cvs is the name of the Postscript operator that does this)
local function cvs( s )
	if s == nil or s == false or s == true then
		s= tostring(s);
	elseif type(s) == 'string' then
		s = '(' .. mw.ustring.gsub(s, '([()])', '\\%1') .. ')';
	elseif type(s) == 'table' then
		local array_p = true;
		for i, v in pairs(s) do
			if type(i) ~= 'number' then
				array_p = false;
			end
		end
		local s2 = '';
		if array_p then
			for i = 1, #s, 1 do
				if #s2 > 0 then
					s2 = s2 .. ' ';
				end
				s2 = s2 .. cvs(s[i]);
			end
			s2 = '[' .. s2 .. ']';
		else
			for i, v in pairs(s) do
				if #s2 > 1 then
					s2 = s2 .. ' ';
				end
				if type(i) == 'string' and i:match('^%w%w*$') then
					s2 = s2 .. '/' .. i;
				else
					s2 = s2 .. cvs(i);
				end
				s2 = s2 .. ' ' .. cvs(v);
			end
			s2 = '{' .. s2 .. '}';
		end
		s = s2;
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

-- Analyze the title and see if it's a link of some kind
local function parse_title( s )
	local it = s;
	if type(s) == 'string' then
		local label, link, url;
		link, label = mw.ustring.match(s, '^%[%[%s*([^%[][^%[]*)%s*|%s*([^%[%]]*)%s*%]%]$');
		if link then
			if label and #label == 0 then
				label = link;
			end
		else
			link = mw.ustring.match(s, '^%[%[([^%[]+)%]%]$');
			if link then
				label = link;
			else
				url, label = mw.ustring.match(s, '^%[(%S+)%s([^%]]+)%]$');
				if not url then
					label = s;
				end
			end
		end
		it = {
			['label'] = label;
			['link'] = link;
			['url'] = url;
		};
	end
	return it;
end

-- Inverse of parse_title: Try to reconstruct a wikified link given its parse
local function wrap_title( label, link, url )
	local it;
	if type(label) == 'table' then
		link = label['link'];
		url = label['url'];
		label = label['label'];
	end
	if label == nil then
		-- all is lost
	elseif link ~= nil then
		it = '[[' .. link .. '|' .. label .. ']]';
	elseif url ~= nil then
		it = '[' .. url .. ' ' .. label .. ']';
	else
		it = label;
	end
	return it;
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
-- Try to construct the final HTML so that it line wrap correctly
-- while also following kinsokushori rules
local function build_type_1_part( s )
	local it;
	local stage1 = {};
	local opening_p = false;
	s = parse_title(s);
	it = '';
	for i = 1, mw.ustring.len(s['label']), 1 do
		local c = mw.ustring.sub(s['label'], i, i);
		if opening_p or (#stage1 > 0 and mw.ustring.match('[》〉｣」』]', c)) then
			table.insert(stage1[#stage1], c);
		else
			table.insert(stage1, {c});
		end
		opening_p = mw.ustring.match('[《〈｢「『]', c);
	end
	for i = 1, #stage1, 1 do
		local stage2 = stage1[i];
		it = it .. '<span class=zit3>' .. '<span class=zit3>';
		for j = 1, #stage2, 1 do
			it = it .. '<span class=zi6>' .. stage2[j] .. '</span>';
		end
		it = it .. '</span>' .. '</span>';
	end
	--it = 'DEBUG: stage1 = ' .. cvs(stage1) .. '<br>→ it = ' .. cvs(it); 
	it = wrap_title(it, s['link'], s['url']);
	return it;
end

-- Build a type 1 citable with type 2 as a fallback
local function build_type_1_citable( work, part )
	local it;
	local part1, part2;
	local class1, class2;
	local prefix, suffix;
	local infix = '';
	work = parse_title(work);
	part = parse_title(part);
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
				.. wrap_title(part1)
				.. '</span>';
	end
	if part2 ~= nil then
		it = it .. '<span class=' .. class2 .. '>'
				..' <span class=fan1gaak3>' .. infix .. '</span>'
				.. wrap_title(part2)
				.. '</span>';

		if part1 ~= nil then
			alt = prefix .. build_aria_label_from(part1
												..infix
												..part2) .. suffix;
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
	local alt;
	work = parse_title(work);
	part = parse_title(part);
	if part ~= nil then
		class = 'pin1ming4';
		prefix = '〈';
		suffix = '〉';
		if work ~= nil then
			root = wrap_title(work)
				.. '・'								-- dot = U+30FB
				.. wrap_title(part);

			alt = work['label'] .. '・' .. part['label'];
		else
			root = wrap_title(part);
			alt = part['label'];
		end
	elseif work ~= nil then
		class = 'syu1ming4';
		prefix = '《';
		suffix = '》';
		root = work['label'];
		alt = work['label'];
	end
	if root ~= nil then
		alt = prefix .. build_aria_label_from(alt) .. suffix;
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
			.. '—'									-- 2014 (em dash)
			.. '…'									-- 2026
			.. '○'									-- 25CB (circle [not zero])
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
	local it;
	local det;
	if type(work) == 'table' then
		work = work['label'];
	end
	if type(part) == 'table' then
		part = part['label'];
	end
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
		it = '1';
	else
		it = '2';
	end
	return it;
end

-- Automatically select whether to build either a type 1 or type 2 citable
local function auto_build_citable( work, part )
	local type = determine_which_type_to_use(work, part);
	local it;
	if type == '1' then
		it = build_type_1_citable(work, part);
	else
		it = build_type_2_citable(work, part);
	end
	return it;
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
	work = parse_title(work);
	part = parse_title(part);
	
	-- fixup default type
	if type == nil then
		type = 'auto';
	end
	type = canonicalize_type_value(type);

	-- build it
	if work == nil and part == nil then
		if error == nil then
			error = '書名模出錯，搵唔到書名，又搵唔到篇名';
		end
	elseif type == 'auto' then
		it = auto_build_citable(work, part)
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

p.Zoek6zung6 = function( frame )
	local parent = frame:getParent();
	local s1 = sanitize(frame.args[1]);
	local it;
	local alt = '';
	local styles = 'Module:書名/styles.css';
	local error;
	
	-- build it
	if s1 ~= nil then
		s1 = parse_title(s1);
		local alt = build_aria_label_from(s1['label']);
		it = build_type_1_part(s1);
		if it ~= nil then
			it = '<span class=zoek6zung6 aria-label="' .. alt .. '">'
				.. it
				.. '</span>';
		end
	else
		if error == nil then
			error = '着重模出錯，搵唔到着重乜嘢';
		end
	end

	if it == nil and error ~= nil then
		it = '<span class=error>' .. error .. '</span>'
			.. '（s1=' .. cvs(s1)
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

p.cvs = cvs;
p.cjk_p = cjk_p;
p.determine_which_type_to_use = determine_which_type_to_use;
p.build_type_1_citable = build_type_1_citable;
p.build_type_2_citable = build_type_2_citable;
p.auto_build_citable = auto_build_citable;
return p;
