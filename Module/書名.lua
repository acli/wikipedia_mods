-- vi:set sw=4 ts=4 ai sm:
---- This module implements the backend logic for displaying the two types
---- of ˈsyˌmiŋˍhou (punctuation mark for indicating the title of a citable
---- work in Chinese languages)
---- It has also been modified to deal with ˍdzœkˍdzuŋˍhou (emphasis marks,
---- which unfortunately needs to be dealt with despite being a standard part
---- of CSS) and also some experimental support for ˈdzynˌmiŋˍhou (punctuation
---- mark for indicating personal and geographical names)

require ('Module:No globals');
local p = {};

local TYPE_1 = '甲';
local TYPE_2 = '乙';

--- Auxiliaries ---------------------------------------------------------------

-- Figure out if a thing is an array
local function array_p( thing )
	local it = (type(thing) == 'table');
	if it then
		local i_min, i_max;
		for i, v in pairs(thing) do
			if type(i) ~= 'number' then
				it = false;
			else
				if i_min == nil or i < i_min then
					i_min = i;
				end
				if i_max == nil or i > i_max then
					i_max = i;
				end
			end
		end
		-- in PostScript array indexes start at 0, but in Lua they start at 1
		-- in addition, Lua "sequences" cannot contain nils (ignoring for now)
		if it and not (i_min and i_min == 1 and i_max == #thing) then
			it = false;				-- index has holes, not a real array
		end
	end
	return it;
end

-- Stringify something into a form suitable for debugging and error messages
-- (cvs is the name of the Postscript operator that does this)
local function cvs( s )
	if s == nil or s == false or s == true then
		s= tostring(s);
	elseif type(s) == 'string' then
		s = '(' .. mw.ustring.gsub(s, '([()])', '\\%1') .. ')';
	elseif type(s) == 'function' then
		s = 'FUNCTION';			-- sigh
	elseif type(s) == 'table' then
		local s2 = '';
		if array_p(s) then
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
			s2 = '<<' .. s2 .. '>>';
		end
		s = s2;
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

-- If the passed string is a null string, turn it into an actual null
local function nullify( s )
	if s == '' then
		s = nil
	end
	return s;
end

-- Check if the given string is (believed to be) CJK
local function cjk_p( s )
	return mw.ustring.match(s, '^['
			.. '—'									-- 2014 (em dash)
			.. '…'									-- 2026
			.. '─'									-- 2500 (line drawing)
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

local function space_p( c )
	return mw.ustring.match(c, '[ 　]');	-- sp, CJK sp
end

local function kernable_left_punctuation_p( c )
	return c and mw.ustring.match(c, '[《〈（【「『]');
end

local function kernable_right_punctuation_p( c )
	return c and mw.ustring.match(c, '[》〉）】」』]');
end

local function left_kernable_narrow_punctuation_p( c )
	return c and mw.ustring.match(c, '[，；：。！]');
end

local function right_kernable_narrow_punctuation_p( c )
	return c and mw.ustring.match(c, '[、，；：。！]');
end

-- Canonicalize the type parameter
local function canonicalize_type_value( type )
	if type == '1' or type == '甲' then
		type = '甲'
	elseif type == '2' or type == '乙' then
		type = '乙'
	end
	return type;
end

-- Try to guess what REALLY is the thing, in the context of this module.
-- Like Lisp or Perl, Lua has no real concept of classes, but unlike Perl
-- there's no way to "bless" an array (table in Lua) into a class.
-- So everything is just a generic table - a most non-ideal situation.
-- (ref is the name of the Perl operator that does this)
local function ref( thing )
	local it = type(thing);
	if thing == nil then
		it = nil
	elseif it == 'table' then
		-- Are we looking at a parsed title?
		if thing.label and type(thing.label) == 'string' then
			it = 'parsed-title';
		-- Are we looking at an array?
		elseif array_p(thing) then
			it = 'array'
		end
	end
	return it;
end

-- Analyze the title and see if it's a link of some kind
local function parse_title( s )
	local it = s;
	local t = ref(s);
	if t == 'string' then
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
		-- Silent change a few things to make it easier to typeset
		label = mw.ustring.gsub(label, '[─]', '—');		-- U+2500 line drawing
		label = mw.ustring.gsub(label, '[○]', '〇');	-- U+25CB circle
		label = mw.ustring.gsub(label, '⸺', '——');	-- 2-em dash -0> 2x em dash'
		it = {
			['label'] = label;
			['link'] = link;
			['url'] = url;
		};
	elseif t and t ~= 'parsed-title' then
		error('parse-title got unexpected argument '..cvs(s) .. ' (t=' .. cvs(t) .. ')', 2);
	end
	return it;
end

-- Inverse of parse_title: Try to reconstruct a wikified link given its parse
-- This does not seem to actually work
local function linkify_title( label, link, url )
	local it;
	if type(label) == 'table' then
		link = label.link;
		url = label.url;
		label = label.label;
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
	if type(s) ~= 'string' then
		error('ERROR: build_aria_label got a non-string '..cvs(s), 2);
	end
	return	mw.ustring.gsub(
			mw.ustring.gsub(
			mw.ustring.gsub(
			mw.ustring.gsub(
			mw.ustring.gsub(
			mw.ustring.gsub(s,
				'<[^<>]*>', ''),					-- try to nuke tags
				"'''''", ''),						-- Wikitext bold italic
				"'''", ''),							-- Wikitext bold
				"'", ''),							-- Wikitext italic
				'"', '”'), 
				"'", '’')
end

local function get_token( t )
	local t_next;
	local it = {['pre'] = ''; ['c'] = ''; ['post'] = '';};
	for stage = 1, 3, 1 do
		local formatting = '';
		while true do
			local t1, t2;
			local done_p = false;
			if stage == 1 then
				t1, t2 = mw.ustring.match(t, '^(<[^/][^<>]*>)(.*)$');
			elseif stage == 2 then
				t1 = nil;
			elseif stage == 3 then
				t1, t2 = mw.ustring.match(t, '^(</[^<>]*>)(.*)$');
			else
				error('Internal error 1, stage='..cvs(stage), 1)
			end
			if t1 then
				formatting = formatting .. t1;
				t_next = t2;
			elseif stage == 1 or stage == 3 then
				t1, t2 =  mw.ustring.match(t, "^(''''')(.*)$");
				if not t1 then
					t1, t2 =  mw.ustring.match(t, "^(''')(.*)$")
					if not t1 then
						t1, t2 =  mw.ustring.match(t, "^('')(.*)$");
					end
				end
				if t1 then
					formatting = formatting .. t1;
					t_next = t2;
				else
					done_p = true;
				end
			elseif stage == 2 then
				t1, t2 = mw.ustring.match(t, '^([^<])(.*)$');
				if t1 then
					it.c = it.c .. t1;
					t_next = t2;
				end
				done_p = true;
			else
				error('Internal error 2, stage='..cvs(stage), 1)
			end
		if done_p then break end
			t = t_next;
		end
		if formatting then
			if stage == 1 then
				it.pre = it.pre .. formatting;
			else
				it.post = it.post .. formatting;
			end
		end
	end
	return it, t_next or '';
end

-- Build a type 1 part (not necessarily the entire title)
-- Try to construct the final HTML so that it line wrap correctly
-- while also following kinsokushori rules
local function build_type_1_part( s )
	local it;
	local stage1 = {};
	local opening_p = false;
	s = parse_title(s);
	assert(ref(s) == 'parsed-title')
	it = '';
	local t = s.label;
	while #t > 0 do
		local c, t_next = get_token(t);
		local closing_p = mw.ustring.match('[】》〉）｣」』]', c.c);
		if opening_p or closing_p then
			table.insert(stage1[#stage1], c);
		else
			table.insert(stage1, {c});
		end
		opening_p = mw.ustring.match('[【《〈（｢「『]', c.c);
		t = t_next;
	end
	for i = 1, #stage1, 1 do
		local stage2 = stage1[i];
		local class = 'zit3';
		if i == #stage1 then
			class = 'hai2zeoi3mei1ge3 '..class;
		end
		if i == 1 then
			class = 'hai2tau4ge3 '..class;
		end
		it = it .. '<span class="'..class..'">' .. '<span class=zit3>';
		for j = 1, #stage2, 1 do
			local class = 'zi6';
			if j == #stage2 then
				class = 'hai2zeoi3mei1ge3 '..class;
			end
			if j == 1 then
				class = 'hai2tau4ge3 '..class;
			end
			local s = stage2[j];
			local c = table.concat({s.pre or '', s.c, s.post or ''});
			it = it .. '<span class="'..class..'">' .. c .. '</span>';
		end
		it = it .. '</span>' .. '</span>';
	end
	--it = 'DEBUG: stage1 = ' .. cvs(stage1) .. '<br>→ it = ' .. cvs(it); 
	it = linkify_title(it, s.link, s.url);
	return it;
end

-- Try to kern the given string
-- The logic is a deterministic finite state machine. The DFA diagram is
-- currently on a piece of paper and will be added here later.
local function kern( s0 )
	local it;
	local s = parse_title(s0);
	assert(ref(s) == 'parsed-title');
	local t = s.label;
	local segment;
	local STATE = { ['INITIAL'] = 'INITIAL';
					['OPENING'] = 'OPENING';
					['CLOSING'] = 'CLOSING';
	};
	local state = STATE.INITIAL;
	local function tag_p( s )
		return s and s:sub(1, 1) == '<';
	end
	local function remember_kerned( c, class, segment, state )
		if segment == nil then
			segment = {};
		end
		table.insert(segment, { ['c'] = c;
								['class'] = class;
								['state'] = state; });
		return segment;
	end
	local function remember_unkerned(c, segment, state)
		if segment == nil then
			segment = {};
		end
		if #segment == 0 
		or segment[#segment].class 
		or segment[#segment].post
		or c.pre then
			table.insert(segment, { ['c'] = c;
									['state'] = state; } );
		else
			segment[#segment].c.c = table.concat({segment[#segment].c.c, c.c});
			segment[#segment].c.post = c.post;
		end
		return segment;
	end
	local function change_class_of_last_remembered( segment, class, state )
		if segment ~= nil and #segment > 0 then
			segment[#segment].class = class;
		end
		return segment;
	end
	local function remove_last_character_from_memory( segment )
		local it = {};
		if segment and #segment > 0 
		and segment[#segment].c.post then	-- last segment has a tag. sigh.
			it.c = '';
		elseif segment and #segment > 0 
		and #(segment[#segment].c.c) > 0 then
			local s1, s2 = mw.ustring.match(segment[#segment].c.c, '^(.*)(.)$');
			it.c = s2;
			it.post = segment[#segment].c.post;
			segment[#segment].c.c = s1;
			segment[#segment].c.post = nil;
			if #s1 == 0 then
				it.pre = segment[#segment].c.pre;
				segment[#segment].c.pre = nil;
			end
		else
			it.c = '';
		end
		return it, segment;
	end
	local function flush_segment( segment, it, state )
		local s = '';
		if segment then
			for i, v in pairs(segment) do
				s = s .. (v.c.pre or '');
				if v.class then
					s = s .. '<span class=' .. v.class .. '>' .. v.c.c .. '</span>'
				else
					s = s .. v.c.c;
				end
				s = s .. (v.c.post or '');
			end
			if #s > 0 then
				s = '<span class=zit3 ' .. '>' .. s .. '</span>';
				--s=mw.ustring.gsub(s,'<','&lt;');--DEBUG
				it = it .. s;
			end
		end
		segment = {};
		return segment, it;
	end
	it = '';
	while #t > 0 do
		-- We might encounter a tag. try to not break it
		-- XXX Actually, if we see a tag maybe we should stop and give up
		local c, t_next = get_token(t);
		if state == STATE.INITIAL then
			if kernable_left_punctuation_p(c.c) then
				state = STATE.OPENING;
				if #it == 0 then
					segment = remember_kerned(c, 'koen1zo2', segment, state);
				else
					segment = remember_kerned(c, 'koen1zo2siu2siu2', segment, state);
				end
			elseif kernable_right_punctuation_p(c.c) then
				state = STATE.CLOSING;
				local c_last;
				c_last, segment = remove_last_character_from_memory(segment);
				segment, it = flush_segment(segment, it, state);
				segment = remember_unkerned(c_last, segment, state);
				segment = remember_kerned(c, 'koen1jau6', segment, state);
			else
				segment = remember_unkerned(c, segment, state);
			end
		elseif state == STATE.OPENING then
			if kernable_left_punctuation_p(c.c) then
				segment = remember_kerned(c, 'koen1zo2', segment, state);
			elseif kernable_right_punctuation_p(c.c) then
				state = STATE.CLOSING;
				segment = remember_kerned(c, 'koen1jau6', segment, state);
			else
				state = STATE.INITIAL;
				segment = remember_unkerned(c, segment, state);
				segment, it = flush_segment(segment, it, state);
			end
		elseif state == STATE.CLOSING then
			if kernable_left_punctuation_p(c.c) then
				state = STATE.OPENING;
				segment, it = flush_segment(segment, it, state);
				segment = remember_unkerned(c, segment, state);
			elseif kernable_right_punctuation_p(c.c) then
				segment = remember_kerned(c, 'koen1jau6', segment, state);
			else
				state = STATE.INITIAL;
				if not space_p(c.c) and not left_kernable_narrow_punctuation_p(c.c) then
					segment = change_class_of_last_remembered(segment, 'koen1jau6siu2siu2', state)
				end
				segment = remember_unkerned(c, segment, state);
				segment, it = flush_segment(segment, it, state);
			end
		else
			error('kern() encountered unexpeected state '.. cvs(state));
		end
		t = t_next;
	end
	segment, it = flush_segment(segment, it, state);
	if ref(s0) == 'parsed-title' then	-- try to return a result that's the same type
		s.label = it;
		it = s;
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
				.. linkify_title(part1)
				.. '</span>';
	end
	if part2 ~= nil then
		it = it .. '<span class=' .. class2 .. '>'
				.. '<span class=fan1gaak3>' .. infix .. '</span>'
				.. linkify_title(part2)
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
		if work ~= nil then
			prefix = '《';
			suffix = '》';
			work.label = prefix .. work.label;
			part.label = part.label .. suffix;
			root = linkify_title(kern(work))
				.. '・'								-- dot = U+30FB
				.. linkify_title(kern(part));

			alt = work.label .. '・' .. part.label;
		else
			prefix = '〈';
			suffix = '〉';
			part.label = prefix .. part.label .. suffix;
			root = linkify_title(kern(part));
			alt = part.label;
		end
	elseif work ~= nil then
		class = 'syu1ming4';
		prefix = '《';
		suffix = '》';
		work.label = prefix .. work.label .. suffix;
		root = linkify_title(kern(work));
		alt = work.label;
	end
	if root ~= nil then
		alt = build_aria_label_from(alt);
		--prefix = '<span class=hoi1-adj>' .. prefix .. '</span>';
		--suffix = '<span class=saan1-adj>'.. suffix .. '</span>';
		it = '<span class = "' .. class .. '-b" aria-label="' .. alt .. '">' 
				.. root 
				.. '</span>';
	end
	return it;
end

-- Build a non-citable proper noun using CSS underlining or borders
local function build_noncitable_proper_simple( parts, use_dot_p )
	local it;
	local class = 'zyun1ming4';
	local zwsp = '​';								-- U+200B
	local zwnj = '‌';								-- U+200C
	local infix = '・'								-- dot = U+30FB
	local root;
	local alt;
	if not use_dot_p then
		infix = zwnj;
	end
	if parts then
		for k, v in pairs(parts) do
			local part = parse_title(parts[k]);
			if not root then
				root = '';
				alt = '';
			else
				root = root .. zwnj;
				alt = alt .. infix;
			end
			local segment = linkify_title(part);
			alt = build_aria_label_from(part.label);
			segment = '<span class = "' .. class .. '-b" aria-label="' .. alt .. '">' 
					.. segment 
					.. '</span>';
			root = root .. segment;
		end
	end
	it = '<span class=zyun1ming4-b>'
		.. root
		.. '</span>';
	return it;
end

-- Attempt to build a non-citable proper noun using Unicode
local function build_noncitable_proper_alternate( parts, use_dot_p )
	local it;
	local class = 'zyun1ming4';
	local zwsp = '​';								-- U+200B
	local zwnj = '‌';								-- U+200C
	local infix = '・'								-- dot = U+30FB
	local root;
	local alt;
	if not use_dot_p then
		infix = zwnj;
	end
	if parts then
		for k, v in pairs(parts) do
			local part = parse_title(parts[k]);
			if not root then
				root = '';
				alt = '';
			else
				root = root .. zwnj;
				alt = alt .. infix;
			end
			local segment = build_type_1_part(part);
			alt = build_aria_label_from(part.label);
			segment = '<span class = "' .. class .. '" aria-label="' .. alt .. '">' 
					.. segment 
					.. '</span>';
			root = root .. segment;
		end
	end
	it = '<span class=zyun1ming4>'
		.. root
		.. '</span>';
	return it;
end

-- Analyze the given title(s) and decide if type 1 is safe to use
local function determine_which_type_to_use( work, part )
	local it;
	local det;
	local t = ref(work);
	if t == 'parsed-title' then
		work = work.label;
	elseif t == 'array' then
		work = table.concat(work);
	end
	if type(part) == 'table' then
		part = part.label;
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
		it = TYPE_1;
	else
		it = TYPE_2;
	end
	return it;
end

-- Automatically select whether to build either a type 1 or type 2 citable
local function auto_build_citable( work, part )
	local type = determine_which_type_to_use(work, part);
	local it;
	if type == TYPE_1 then
		it = build_type_1_citable(work, part);
	else
		it = build_type_2_citable(work, part);
	end
	return it;
end

-- Automatically select whether to build noncitable with Unicode or underlining
local function auto_build_noncitable( parts, use_dots_p )
	local type = determine_which_type_to_use(parts);
	local it;
	if type == TYPE_1 then
		it = build_noncitable_proper_alternate(parts, use_dots_p);
	else
		it = build_noncitable_proper_simple(parts, use_dots_p);
	end
	return it;
end

--- Exported, invocable functions ---------------------------------------------

-- Entry point for Template:書名 and Template:篇名
p.Syu1meng2 = function( frame )
	local parent = frame:getParent();
	local chapter_mode_p = (frame.args.mode and frame.args.mode == 'chapter') == true;
	local it;
	local alt = '';
	local styles = 'Module:書名/styles.css';
	local work, part;
	local type;

	-- figure out what is actually being marked up as a citable
	local parts = {};
	local name = parent:getTitle();
	if chapter_mode_p then
		table.insert(parts, '');
		name = '篇名模';
	end
	for k, v in pairs(parent.args) do
		local ps = ' (參數明細：' .. cvs(parent.args) .. ')';
		v = sanitize(v);
		if ref(k) == 'number' then
			assert(v ~= nil);
			table.insert(parts, v);
		elseif k == 'type' or k == '式' then
			if type then
				error(name..'遇到 '..k..' 參數，但係已經指咗 ｢'..type..'｣ 式'..ps);
			else
				type = canonicalize_type_value(v);
			end
		elseif (not chapter_mode_p and k == 'title')
			or (chapter_mode_p and k == 'work') then
				
			if nullify(parts[1]) then
				error(name..'遇到 '..k..' 參數，但係已經有 ｢'..parts[1]..'｣'..ps);
			else
				parts[1] = v;
			end
		elseif k == 'chapter'
			or (chapter_mode_p and k == 'title') then
				
			if nullify(parts[2]) then
				error(name..'遇到 '..k..' 參數，但係已經有 ｢'..parts[2]..'｣'..ps);
			else
				if not parts[1] then
					parts[1] = '';
				end
				parts[2] = v;
			end
		else
			error(name..'遇到不明參數 ｢' .. k .. '｣'..ps);
		end
	end
	if #parts == 0 then
		error('冇指定書名或者篇名');
	elseif #parts > 2 then
		error('指定咗太多章名，暫時處理唔到（parts='..cvs(parts)..'）');
	end
	work = parse_title(nullify(parts[1]));
	part = parse_title(nullify(parts[2]));

	-- fixup default type
	if type == nil then
		type = 'auto';
	end

	-- build it
	if type == 'auto' then
		it = auto_build_citable(work, part)
	elseif type == TYPE_1 then						-- 甲式 (type 1)
		it = build_type_1_citable(work, part)
	elseif type == TYPE_2 then						-- 乙式 (type 2)
		it = build_type_2_citable(work, part)
	else
		error('唔明'..cvs(type)..'式書名號係乜');
	end

	-- request our style sheet
	it = table.concat ({
			frame:extensionTag ('templatestyles', '', {src=styles}),
			it
		});
	return it;
end

-- Entry point for Template:專名
p.Zyun1ming4 = function( frame )
	local parent = frame:getParent();
	local use_dots_p = (frame.args.mode and frame.args.mode == 'dotted') == true;
	local it;
	local alt = '';
	local styles = 'Module:書名/styles.css';
	local error;
	local parts = {};
	for k, v in pairs(parent.args) do
		if type(k) == 'number' then
			table.insert(parts, v);
		elseif not error then
			error = '專名模遇到不明參數 ｢' .. k .. '｣';
		else
			error = error .. '、｢' .. k .. '｣';
		end
	end
	if #parts == 0 then
		parts = nil;
	end

	-- build it
	if parts ~= nil then
		it = auto_build_noncitable(parts, use_dots_p);
	else
		if error == nil then
			error = '專名模出錯，搵唔到有乜嘢名';
		end
	end

	if it == nil and error ~= nil then
		it = '<span class=error>' .. error .. '</span>'
			.. '（parts=' .. cvs(parts)
			.. '）'
	end
	
	-- request our style sheet
	it = table.concat ({
			frame:extensionTag ('templatestyles', '', {src=styles}),
			it
		});
	return it;
end

-- Entry point for Template:着重
p.Zoek6zung6 = function( frame )
	local parent = frame:getParent();
	local it;
	local alt = '';
	local styles = 'Module:書名/styles.css';

	local parts = {};
	for k, v in pairs(parent.args) do
		if type(k) == 'number' then
			v = parse_title(v);
			v.alt = build_aria_label_from(v.label);
			table.insert(parts, v);
		else
			error('着重模遇到不明參數 ｢' .. k .. '｣');
		end
	end
	if #parts == 0 then
		error('着重模出錯，搵唔到着重乜嘢');
	end
	
	-- build it
	it = '';
	for i, v in pairs(parts) do
		v = parse_title(v);
		local segment = build_type_1_part(v.label);
		if it ~= nil then
			it = it
				.. '<span class=zoek6zung6 aria-label="' .. v.alt .. '">'
				.. segment
				.. '</span>';
		end
	end

	-- request our style sheet
	it = table.concat ({
			frame:extensionTag ('templatestyles', '', {src=styles}),
			it
		});
	return it;
end

-- Entry point for Template:Kern
p.Kern = function( frame )
	local parent = frame:getParent();
	local it;
	local alt = '';
	local styles = 'Module:書名/styles.css';

	local parts = {};
	for k, v in pairs(parent.args) do
		if type(k) == 'number' then
			v = parse_title(v);
			v.alt = build_aria_label_from(v.label);
			table.insert(parts, v);
		else
			error('Kern 模遇到不明參數 ｢' .. k .. '｣');
		end
	end
	if #parts == 0 then
		error('Kern 模出錯，搵唔到 kern 乜嘢');
	end

	-- build it
	it = '';
	for i, v in pairs(parts) do
		v = parse_title(v);
		local segment = kern(v.label);
		if it ~= nil then
			it = it
				.. '<span class=koen1 aria-label="' .. v.alt .. '">'
				.. segment
				.. '</span>';
		end
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
p.ref = ref;
p.cjk_p = cjk_p;
p.kernable_left_punctuation_p = kernable_left_punctuation_p;
p.kernable_right_punctuation_p = kernable_right_punctuation_p;
p.array_p = array_p;
p.determine_which_type_to_use = determine_which_type_to_use;
p.build_type_1_citable = build_type_1_citable;
p.build_type_2_citable = build_type_2_citable;
p.auto_build_citable = auto_build_citable;
return p;
