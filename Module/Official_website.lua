local makeUrl = require('Module:URL')._url

local p = {}

-- Wrapper for pcall which returns nil on failure.
local function quickPcall(func)
	local success, result = pcall(func)
	if success then
		return result
	end
end

-- Gets the rank for a Wikidata property table. Returns 1, 0 or -1, in
-- order of rank.
local function getRank(prop)
	local rank = prop.rank
	if rank == 'preferred' then
		return 1
	elseif rank == 'normal' then
		return 0
	elseif rank == 'deprecated' then
		return -1
	else
		-- No rank or undefined rank is treated as "normal".
		return 0
	end
end

-- Finds whether a Wikidata property is qualified as being in English.
local function isEnglish(prop)
	local ret = quickPcall(function ()
		for i, lang in ipairs(prop.qualifiers.P407) do
			if lang.datavalue.value['numeric-id'] == 1860 then
				return true
			end
		end
		return false
	end)
	return ret == true
end

-- Fetches the official website URL from Wikidata.
local fetchWikidataUrl
fetchWikidataUrl = function()
	-- Get objects for all official sites on Wikidata.
	local websites = quickPcall(function ()
		return mw.wikibase.getAllStatements(mw.wikibase.getEntityIdForCurrentPage(), 'P856')
	end)

	-- Clone the objects in case other code needs them in their original order.
	websites = websites and mw.clone(websites) or {}

	-- Add the table index to the objects in case it is needed in the sort.
	for i, website in ipairs(websites) do
		website._index = i
	end

	-- Sort the websites, first by highest rank, and then by websites in the
	-- English language, then by the website's original position in the
	-- property list. When we are done, get the URL from the highest-sorted
	-- object.
	table.sort(websites, function(ws1, ws2)
		local r1 = getRank(ws1)
		local r2 = getRank(ws2)
		if r1 ~= r2 then
			return r1 > r2
		end
		local e1 = isEnglish(ws1)
		local e2 = isEnglish(ws2)
		if e1 ~= e2 then
			return e1
		end
		return ws1._index < ws2._index
	end)
	local url = quickPcall(function ()
		return websites[1].mainsnak.datavalue.value
	end)

	-- Cache the result so that we only do the heavy lifting once per #invoke.
	fetchWikidataUrl = function ()
		return url
	end

	return url
end

-- Render the URL link, plus other visible output.
local function renderUrl(options)
	if not options.url and not options.wikidataurl then
		local qid = mw.wikibase.getEntityIdForCurrentPage()
		local result = '<strong class="error">' ..
			--[[ LOCAL: localize error message -- disable original message
			-- END LOCAL
			'No URL found. Please specify a URL here or add one to Wikidata.' ..
			-- LOCAL: replace with our own version
			--]]
			'喺維基數據搵唔到網站資料；'..
			'你可以揀人手打，或者擺個官方網址入維基數據。'..
			-- END LOCAL
			'</strong>'
		if qid then
			result = result.. ' [[File:OOjs UI icon edit-ltr-progressive.svg |frameless |text-top |10px |alt=Edit this at Wikidata |link=https://www.wikidata.org/wiki/' .. qid .. '#P856|Edit this at Wikidata]]'
		end
		return result
	end
	local ret = {}
	ret[#ret + 1] = string.format(
		'<span class="official-website">%s</span>',
		makeUrl(options.url or options.wikidataurl, options.display)
	)
	if options.wikidataurl and not options.url then
		local qid = mw.wikibase.getEntityIdForCurrentPage()
		if qid then
			ret[#ret + 1] = '[[File:OOjs UI icon edit-ltr-progressive.svg |frameless |text-top |10px |alt=Edit this at Wikidata |link=https://www.wikidata.org/wiki/' .. qid .. '#P856|Edit this at Wikidata]]'
		end
	end
	if options.format == 'flash' then
		ret[#ret + 1] = mw.getCurrentFrame():expandTemplate{
			title = 'Color',
			args = {'#505050', '(Requires [[Adobe Flash Player]])'}
		}
	end
	if options.mobile then
		ret[#ret + 1] = '(' .. makeUrl(options.mobile, 'Mobile') .. ')'
	end
	return table.concat(ret, ' ')
end

-- Render the tracking category.
local function renderTrackingCategory(url, wikidataurl)
	if mw.title.getCurrentTitle().namespace ~= 0 then
		return ''
	end
	local category
	if not url and not wikidataurl then
		category = 'Official website missing URL'
		-- LOCAL: translate maintenance category
		category = '官方網站冇網址'
		-- END LOCAL
	elseif not url and wikidataurl then
		return ''
	elseif url and wikidataurl then
		if url:gsub('/%s*$', '') ~= wikidataurl:gsub('/%s*$', '') then
			category = 'Official website different in Wikidata and Wikipedia'
			-- LOCAL: translate maintenance category
			category = '官方網站喺維基數據同喺維基有唔同網址'
			-- END LOCAL
		end
	else
		category = 'Official website not in Wikidata'
		-- LOCAL: translate maintenance category
		category = '官方網站喺維基數據冇網址'
		-- END LOCAL
	end
	return category and string.format('[[Category:%s]]', category) or ''
end

function p._main(args)
	local url = args[1] or args.URL or args.url
	local wikidataurl = fetchWikidataUrl()
	-- LOCAL: restore the Cantonese introducer but make adjustments for non-CJK
	local default_label = '官方網站';
	local qid = mw.wikibase.getEntityIdForCurrentPage();
	-- This gets a dict of all listed properties on Wikidata
	-- /labels keys another dict indexed by language name (us is /yue).
	-- The value is another dict with /language and /value keys.
	-- value is the label in the stated language, which is yue if a
	-- Cantonese label is entered into Wikidata, otw. it's listed as en.
	-- The above technically should work but 竹內瑪莉亞 does not have
	-- a /yue /label so it fails and we get the English name. To work
	-- around this we can get the /sitelinks element instead, which
	-- returns a dict containing dicts indexed by the site name (us is
	-- zh_yuewiki), then get the /title element
	local data = mw.wikibase.getEntity(qid);
	if data and data.sitelinks and data.sitelinks.zh_yuewiki then
		local candidate = data.sitelinks.zh_yuewiki.title;
		-- Cut out any parenthesized qualifier in the label
		candidate = mw.ustring.gsub(candidate, '%s*%([^%(%)]+%)$', '')
		-- Check if the label ends in a CJK character
		local det = mw.ustring.match(candidate, '(.)$');
		local english_p = true;
		local aux = require('模組:書名');
		if aux then
			english_p = not aux.cjk_p(det);
		end
		if english_p then
			default_label = candidate .. ' 嘅' .. default_label;
		else
			default_label = candidate .. '嘅' .. default_label;
		end
	end
	-- END LOCAL
	local formattedUrl = renderUrl{
		url = url,
		wikidataurl = wikidataurl,
		--[[ LOCAL: change default label - disable the original code
		-- END LOCAL
		display = args[2] or args.name or 'Official website',
		-- LOCAL: change default label - replace with our version
		--]]
		display = args[2] or args.name or default_label,
		-- END LOCAL
		format = args.format,
		mobile = args.mobile
	}
	return formattedUrl .. renderTrackingCategory(url, wikidataurl)
end

function p.main(frame)
	--[[ LOCAL: disable Module:Arguments
	-- END LOCAL
	local args = require('Module:Arguments').getArgs(frame, {
		wrappers = 'Template:Official website'
	})
	--]]-- LOCAL: replace with our own code to figure out arguments
	local parent = frame:getParent();
	local name = parent:getTitle();
	local args = {};
	for k, v in pairs(parent.args) do
		if k == 1 or k == 'url' or k == 'URL' then
			args.url = v;
		elseif k == 2 or k == 'name' then
			args.name = v;
		elseif k == 'mobile' then
			args.mobile = v;
		elseif k == 'format' then
			args.format = v;
		else
			error(name .. '遇到不明參數 ｢' .. k .. '｣');
		end
	end
	-- END LOCAL
	return p._main(args)
end

return p