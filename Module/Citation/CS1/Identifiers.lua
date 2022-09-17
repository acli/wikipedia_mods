--[[--------------------------< F O R W A R D   D E C L A R A T I O N S >--------------------------------------
]]

local has_accept_as_written, is_set, in_array, set_message, select_one,			-- functions in Module:Citation/CS1/Utilities
		substitute, make_wikilink;

local z;																		-- table of tables defined in Module:Citation/CS1/Utilities

local cfg;																		-- table of configuration tables that are defined in Module:Citation/CS1/Configuration


--[[--------------------------< P A G E   S C O P E   V A R I A B L E S >--------------------------------------

declare variables here that have page-wide scope that are not brought in from other modules; that are created here and used here

]]

local auto_link_urls = {};														-- holds identifier URLs for those identifiers that can auto-link |title=


--============================<< H E L P E R   F U N C T I O N S >>============================================

--[[--------------------------< W I K I D A T A _ A R T I C L E _ N A M E _ G E T >----------------------------

as an aid to internationalizing identifier-label wikilinks, gets identifier article names from Wikidata.

returns :<lang code>:<article title> when <q> has an <article title> for <lang code>; nil else

for identifiers that do not have q, returns nil

for wikis that do not have mw.wikibase installed, returns nil

]]

local function wikidata_article_name_get (q)
	if not is_set (q) or (q and not mw.wikibase) then							-- when no q number or when a q number but mw.wikibase not installed on this wiki
		return nil;																-- abandon
	end

	local wd_article;
	local this_wiki_code = cfg.this_wiki_code;									-- Wikipedia subdomain; 'en' for en.wikipedia.org

	wd_article = mw.wikibase.getSitelink (q, this_wiki_code .. 'wiki');			-- fetch article title from WD; nil when no title available at this wiki

	if wd_article then
		wd_article = table.concat ({':', this_wiki_code, ':', wd_article});		-- interwiki-style link without brackets if taken from WD; leading colon required
	end

	return wd_article;															-- article title from WD; nil else
end


--[[--------------------------< L I N K _ L A B E L _ M A K E >------------------------------------------------

common function to create identifier link label from handler table or from Wikidata

returns the first available of
	1. redirect from local wiki's handler table (if enabled)
	2. Wikidata (if there is a Wikidata entry for this identifier in the local wiki's language)
	3. label specified in the local wiki's handler table
	
]]

local function link_label_make (handler)
	local wd_article;
	
	if not (cfg.use_identifier_redirects and is_set (handler.redirect)) then	-- redirect has priority so if enabled and available don't fetch from Wikidata because expensive
		wd_article = wikidata_article_name_get (handler.q);						-- if Wikidata has an article title for this wiki, get it;
	end
	
	return (cfg.use_identifier_redirects and is_set (handler.redirect) and handler.redirect) or wd_article or handler.link;
end


--[[--------------------------< E X T E R N A L _ L I N K _ I D >----------------------------------------------

Formats a wiki-style external link

]]

local function external_link_id (options)
	local url_string = options.id;
	local ext_link;
	local this_wiki_code = cfg.this_wiki_code;									-- Wikipedia subdomain; 'en' for en.wikipedia.org
	local wd_article;															-- article title from Wikidata
	
	if options.encode == true or options.encode == nil then
		url_string = mw.uri.encode (url_string, 'PATH');
	end

	if options.auto_link and is_set (options.access) then
		auto_link_urls[options.auto_link] = table.concat ({options.prefix, url_string, options.suffix});
	end

	ext_link = mw.ustring.format ('[%s%s%s %s]', options.prefix, url_string, options.suffix or "", mw.text.nowiki (options.id));
	if is_set (options.access) then
		ext_link = substitute (cfg.presentation['ext-link-access-signal'], {cfg.presentation[options.access].class, cfg.presentation[options.access].title, ext_link});	-- add the free-to-read / paywall lock
	end

	return table.concat	({
		make_wikilink (link_label_make (options), options.label),				-- redirect, Wikidata link, or locally specified link (in that order)
		options.separator or '&nbsp;',
		ext_link
		});
end


--[[--------------------------< I N T E R N A L _ L I N K _ I D >----------------------------------------------

Formats a wiki-style internal link

TODO: Does not currently need to support options.access, options.encode, auto-linking and COinS (as in external_link_id),
but may be needed in the future for :m:Interwiki_map custom-prefixes like :arxiv:, :bibcode:, :DOI:, :hdl:, :ISSN:,
:JSTOR:, :Openlibrary:, :PMID:, :RFC:.

]]

local function internal_link_id (options)
	local id = mw.ustring.gsub (options.id, '%d', cfg.date_names.local_digits);	-- translate 'local' digits to Western 0-9

	return table.concat (
		{
		make_wikilink (link_label_make (options), options.label),				-- wiki-link the identifier label
		options.separator or '&nbsp;',											-- add the separator
		make_wikilink (
			table.concat (
				{
				options.prefix,
				id,																-- translated to Western digits
				options.suffix or ''
				}),
			substitute (cfg.presentation['bdi'], {'', mw.text.nowiki (options.id)})	-- bdi tags to prevent Latin script identifiers from being reversed at RTL language wikis
			);																	-- nowiki because MediaWiki still has magic links for ISBN and the like; TODO: is it really required?
		});
end


--[[--------------------------< I S _ E M B A R G O E D >------------------------------------------------------

Determines if a PMC identifier's online version is embargoed. Compares the date in |pmc-embargo-date= against
today's date.  If embargo date is in the future, returns the content of |pmc-embargo-date=; otherwise, returns
an empty string because the embargo has expired or because |pmc-embargo-date= was not set in this cite.

]]

local function is_embargoed (embargo)
	if is_set (embargo) then
		local lang = mw.getContentLanguage();
		local good1, embargo_date, todays_date;
		good1, embargo_date = pcall (lang.formatDate, lang, 'U', embargo);
		todays_date = lang:formatDate ('U');
	
		if good1 then															-- if embargo date is a good date
			if tonumber (embargo_date) >= tonumber (todays_date) then			-- is embargo date is in the future?
				return embargo;													-- still embargoed
			else
				set_message ('maint_pmc_embargo');								-- embargo has expired; add main cat
				return '';														-- unset because embargo has expired
			end
		end
	end
	return '';																	-- |pmc-embargo-date= not set return empty string
end


--[=[-------------------------< I S _ V A L I D _ B I O R X I V _ D A T E >------------------------------------

returns true if:
	2019-12-11T00:00Z <= biorxiv_date < today + 2 days
	
The dated form of biorxiv identifier has a start date of 2019-12-11.  The Unix timestamp for that date is {{#time:U|2019-12-11}} = 1576022400

biorxiv_date is the date provided in those |biorxiv= parameter values that are dated at time 00:00:00 UTC
today is the current date at time 00:00:00 UTC plus 48 hours
	if today is 2015-01-01T00:00:00 then
		adding 24 hours gives 2015-01-02T00:00:00 – one second more than today
		adding 24 hours gives 2015-01-03T00:00:00 – one second more than tomorrow

This function does not work if it is fed month names for languages other than English.  Wikimedia #time: parser
apparently doesn't understand non-English date month names. This function will always return false when the date
contains a non-English month name because good1 is false after the call to lang_object.formatDate().  To get
around that call this function with date parts and create a YYYY-MM-DD format date.

]=]

local function is_valid_biorxiv_date (y, m, d)
	local biorxiv_date = table.concat ({y, m, d}, '-');							-- make ymd date
	local good1, good2;
	local biorxiv_ts, tomorrow_ts;												-- to hold Unix timestamps representing the dates
	local lang_object = mw.getContentLanguage();

	good1, biorxiv_ts = pcall (lang_object.formatDate, lang_object, 'U', biorxiv_date);		-- convert biorxiv_date value to Unix timestamp 
	good2, tomorrow_ts = pcall (lang_object.formatDate, lang_object, 'U', 'today + 2 days' );	-- today midnight + 2 days is one second more than all day tomorrow
	
	if good1 and good2 then														-- lang.formatDate() returns a timestamp in the local script which tonumber() may not understand
		biorxiv_ts = tonumber (biorxiv_ts) or lang_object:parseFormattedNumber (biorxiv_ts);	-- convert to numbers for the comparison;
		tomorrow_ts = tonumber (tomorrow_ts) or lang_object:parseFormattedNumber (tomorrow_ts);
	else
		return false;															-- one or both failed to convert to Unix timestamp
	end

	return ((1576022400 <= biorxiv_ts) and (biorxiv_ts < tomorrow_ts))			-- 2012-12-11T00:00Z <= biorxiv_date < tomorrow's date
end


--[[--------------------------< IS _ V A L I D _ I S X N >-----------------------------------------------------

ISBN-10 and ISSN validator code calculates checksum across all ISBN/ISSN digits including the check digit.
ISBN-13 is checked in isbn().

If the number is valid the result will be 0. Before calling this function, ISBN/ISSN must be checked for length
and stripped of dashes, spaces and other non-ISxN characters.

]]

local function is_valid_isxn (isxn_str, len)
	local temp = 0;
	isxn_str = { isxn_str:byte(1, len) };										-- make a table of byte values '0' → 0x30 .. '9' → 0x39, 'X' → 0x58
	len = len + 1;																-- adjust to be a loop counter
	for i, v in ipairs (isxn_str) do											-- loop through all of the bytes and calculate the checksum
		if v == string.byte ("X" ) then											-- if checkdigit is X (compares the byte value of 'X' which is 0x58)
			temp = temp + 10 * (len - i);										-- it represents 10 decimal
		else
			temp = temp + tonumber (string.char (v) )*(len-i);
		end
	end
	return temp % 11 == 0;														-- returns true if calculation result is zero
end


--[[--------------------------< IS _ V A L I D _ I S X N _ 1 3 >-----------------------------------------------

ISBN-13 and ISMN validator code calculates checksum across all 13 ISBN/ISMN digits including the check digit.
If the number is valid, the result will be 0. Before calling this function, ISBN-13/ISMN must be checked for length
and stripped of dashes, spaces and other non-ISxN-13 characters.

]]

local function is_valid_isxn_13 (isxn_str)
	local temp=0;
	
	isxn_str = { isxn_str:byte(1, 13) };										-- make a table of byte values '0' → 0x30 .. '9' → 0x39
	for i, v in ipairs (isxn_str) do
		temp = temp + (3 - 2*(i % 2)) * tonumber (string.char (v) );			-- multiply odd index digits by 1, even index digits by 3 and sum; includes check digit
	end
	return temp % 10 == 0;														-- sum modulo 10 is zero when ISBN-13/ISMN is correct
end


--[[--------------------------< N O R M A L I Z E _ L C C N >--------------------------------------------------

LCCN normalization (http://www.loc.gov/marc/lccn-namespace.html#normalization)
1. Remove all blanks.
2. If there is a forward slash (/) in the string, remove it, and remove all characters to the right of the forward slash.
3. If there is a hyphen in the string:
	a. Remove it.
	b. Inspect the substring following (to the right of) the (removed) hyphen. Then (and assuming that steps 1 and 2 have been carried out):
		1. All these characters should be digits, and there should be six or less. (not done in this function)
		2. If the length of the substring is less than 6, left-fill the substring with zeroes until the length is six.

Returns a normalized LCCN for lccn() to validate.  There is no error checking (step 3.b.1) performed in this function.

]]

local function normalize_lccn (lccn)
	lccn = lccn:gsub ("%s", "");												-- 1. strip whitespace

	if nil ~= string.find (lccn, '/') then
		lccn = lccn:match ("(.-)/");											-- 2. remove forward slash and all character to the right of it
	end

	local prefix
	local suffix
	prefix, suffix = lccn:match ("(.+)%-(.+)");									-- 3.a remove hyphen by splitting the string into prefix and suffix

	if nil ~= suffix then														-- if there was a hyphen
		suffix = string.rep("0", 6-string.len (suffix)) .. suffix;				-- 3.b.2 left fill the suffix with 0s if suffix length less than 6
		lccn = prefix..suffix;													-- reassemble the LCCN
	end
	
	return lccn;
	end


--============================<< I D E N T I F I E R   F U N C T I O N S >>====================================

--[[--------------------------< A R X I V >--------------------------------------------------------------------

See: http://arxiv.org/help/arxiv_identifier

format and error check arXiv identifier.  There are three valid forms of the identifier:
the first form, valid only between date codes 9107 and 0703, is:
	arXiv:<archive>.<class>/<date code><number><version>
where:
	<archive> is a string of alpha characters - may be hyphenated; no other punctuation
	<class> is a string of alpha characters - may be hyphenated; no other punctuation; not the same as |class= parameter which is not supported in this form
	<date code> is four digits in the form YYMM where YY is the last two digits of the four-digit year and MM is the month number January = 01
		first digit of YY for this form can only 9 and 0
	<number> is a three-digit number
	<version> is a 1 or more digit number preceded with a lowercase v; no spaces (undocumented)
	
the second form, valid from April 2007 through December 2014 is:
	arXiv:<date code>.<number><version>
where:
	<date code> is four digits in the form YYMM where YY is the last two digits of the four-digit year and MM is the month number January = 01
	<number> is a four-digit number
	<version> is a 1 or more digit number preceded with a lowercase v; no spaces

the third form, valid from January 2015 is:
	arXiv:<date code>.<number><version>
where:
	<date code> and <version> are as defined for 0704-1412
	<number> is a five-digit number

]]

local function arxiv (options)
	local id = options.id;
	local class = options.Class;												-- TODO: lowercase?
	local handler = options.handler;
	local year, month, version;
	local err_msg = false;														-- assume no error message
	local text;																	-- output text
	
	if id:match("^%a[%a%.%-]+/[90]%d[01]%d%d%d%d$") or id:match("^%a[%a%.%-]+/[90]%d[01]%d%d%d%dv%d+$") then	-- test for the 9107-0703 format with or without version
		year, month = id:match("^%a[%a%.%-]+/([90]%d)([01]%d)%d%d%d[v%d]*$");
		year = tonumber (year);
		month = tonumber (month);
		if ((not (90 < year or 8 > year)) or (1 > month or 12 < month)) or		-- if invalid year or invalid month
			((91 == year and 7 > month) or (7 == year and 3 < month)) then		-- if years ok, are starting and ending months ok?
				err_msg = true;													-- flag for error message
		end

	elseif id:match("^%d%d[01]%d%.%d%d%d%d$") or id:match("^%d%d[01]%d%.%d%d%d%dv%d+$") then	-- test for the 0704-1412 with or without version
		year, month = id:match("^(%d%d)([01]%d)%.%d%d%d%d[v%d]*$");
		year = tonumber (year);
		month = tonumber (month);
		if ((7 > year) or (14 < year) or (1 > month or 12 < month)) or			-- is year invalid or is month invalid? (doesn't test for future years)
			((7 == year) and (4 > month)) then									-- when year is 07, is month invalid (before April)?
				err_msg = true;													-- flag for error message
		end

	elseif id:match("^%d%d[01]%d%.%d%d%d%d%d$") or id:match("^%d%d[01]%d%.%d%d%d%d%dv%d+$") then	-- test for the 1501- format with or without version
		year, month = id:match("^(%d%d)([01]%d)%.%d%d%d%d%d[v%d]*$");
		year = tonumber (year);
		month = tonumber (month);
		if ((15 > year) or (1 > month or 12 < month)) then						-- is year invalid or is month invalid? (doesn't test for future years)
			err_msg = true;														-- flag for error message
		end

	else
		err_msg = true;															-- not a recognized format; flag for error message
	end

	if err_msg then
		options.coins_list_t['ARXIV'] = nil;									-- when error, unset so not included in COinS
	end
	
	local err_msg_t = {};
	if err_msg then
		set_message ('err_bad_arxiv');
	end

	text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode, access = handler.access});

	if is_set (class) then
		if id:match ('^%d+') then
			text = table.concat ({text, ' [[//arxiv.org/archive/', class, ' ', class, ']]'});	-- external link within square brackets, not wikilink
		else
			set_message ('err_class_ignored');
		end
	end

	return text;
end


--[[--------------------------< B I B C O D E >--------------------------------------------------------------------

Validates (sort of) and formats a bibcode ID.

Format for bibcodes is specified here: http://adsabs.harvard.edu/abs_doc/help_pages/data.html#bibcodes

But, this: 2015arXiv151206696F is apparently valid so apparently, the only things that really matter are length, 19 characters
and first four digits must be a year.  This function makes these tests:
	length must be 19 characters
	characters in position
		1–4 must be digits and must represent a year in the range of 1000 – next year
		5 must be a letter
		6–8 must be letter, digit, ampersand, or dot (ampersand cannot directly precede a dot; &. )
		9–18 must be letter, digit, or dot
		19 must be a letter or dot

]]

local function bibcode (options)
	local id = options.id;
	local access = options.access;
	local handler = options.handler;
	local err_type;
	local err_msg = '';
	local year;

	local text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode,
		access = access});
	
	if 19 ~= id:len() then
		err_type = cfg.err_msg_supl.length;
	else
		year = id:match ("^(%d%d%d%d)[%a][%w&%.][%w&%.][%w&%.][%w.]+[%a%.]$");
		if not year then														-- if nil then no pattern match
			err_type = cfg.err_msg_supl.value;									-- so value error
		else
			local next_year = tonumber (os.date ('%Y')) + 1;					-- get the current year as a number and add one for next year
			year = tonumber (year);												-- convert year portion of bibcode to a number
			if (1000 > year) or (year > next_year) then
				err_type = cfg.err_msg_supl.year;								-- year out of bounds
			end
			if id:find('&%.') then
				err_type = cfg.err_msg_supl.journal;							-- journal abbreviation must not have '&.' (if it does it's missing a letter)
			end
		end
	end

	if is_set (err_type) then													-- if there was an error detected
		set_message ('err_bad_bibcode', {err_type});
		options.coins_list_t['BIBCODE'] = nil;									-- when error, unset so not included in COinS

	end

	return text;
end


--[[--------------------------< B I O R X I V >-----------------------------------------------------------------

Format bioRxiv ID and do simple error checking.  Before 2019-12-11, biorXiv IDs were 10.1101/ followed by exactly
6 digits.  After 2019-12-11, biorXiv IDs retained the six-digit identifier but prefixed that with a yyyy.mm.dd. 
date and suffixed with an optional version identifier.

The bioRxiv ID is the string of characters:
	https://doi.org/10.1101/078733 -> 10.1101/078733
or a date followed by a six-digit number followed by an optional version indicator 'v' and one or more digits:
	https://www.biorxiv.org/content/10.1101/2019.12.11.123456v2 -> 10.1101/2019.12.11.123456v2
	
see https://www.biorxiv.org/about-biorxiv

]]

local function biorxiv (options)
	local id = options.id;
	local handler = options.handler;
	local err_msg = true;														-- flag; assume that there will be an error
	
	local patterns = {
		'^10.1101/%d%d%d%d%d%d$',												-- simple 6-digit identifier (before 2019-12-11)
		'^10.1101/(20[1-9]%d)%.([01]%d)%.([0-3]%d)%.%d%d%d%d%d%dv%d+$',			-- y.m.d. date + 6-digit identifier + version (after 2019-12-11)
		'^10.1101/(20[1-9]%d)%.([01]%d)%.([0-3]%d)%.%d%d%d%d%d%d$',				-- y.m.d. date + 6-digit identifier (after 2019-12-11)
		}
	
	for _, pattern in ipairs (patterns) do										-- spin through the patterns looking for a match
		if id:match (pattern) then
			local y, m, d = id:match (pattern);									-- found a match, attempt to get year, month and date from the identifier

			if m then															-- m is nil when id is the six-digit form
				if not is_valid_biorxiv_date (y, m, d) then						-- validate the encoded date; TODO: don't ignore leap-year and actual month lengths ({{#time:}} is a poor date validator)
					break;														-- date fail; break out early so we don't unset the error message
				end
			end
			err_msg = nil;														-- we found a match so unset the error message
			break;																-- and done
		end
	end																			-- err_cat remains set here when no match

	if err_msg then
		options.coins_list_t['BIORXIV'] = nil;									-- when error, unset so not included in COinS
		set_message ('err_bad_biorxiv');										-- and set the error message
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, separator = handler.separator,
			encode = handler.encode, access = handler.access});
end


--[[--------------------------< C I T E S E E R X >------------------------------------------------------------

CiteSeerX use their own notion of "doi" (not to be confused with the identifiers resolved via doi.org).

The description of the structure of this identifier can be found at Help_talk:Citation_Style_1/Archive_26#CiteSeerX_id_structure

]]

local function citeseerx (options)
	local id = options.id;
	local handler = options.handler;
	local matched;

	local text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode,
		access = handler.access});
	
	matched = id:match ("^10%.1%.1%.[1-9]%d?%d?%d?%.[1-9]%d?%d?%d?$");
	if not matched then
		set_message ('err_bad_citeseerx' );
		options.coins_list_t['CITESEERX'] = nil;								-- when error, unset so not included in COinS
	end

	return text;
end


--[[--------------------------< D O I >------------------------------------------------------------------------

Formats a DOI and checks for DOI errors.

DOI names contain two parts: prefix and suffix separated by a forward slash.
	Prefix: directory indicator '10.' followed by a registrant code
	Suffix: character string of any length chosen by the registrant

This function checks a DOI name for: prefix/suffix.  If the DOI name contains spaces or endashes, or, if it ends
with a period or a comma, this function will emit a bad_doi error message.

DOI names are case-insensitive and can incorporate any printable Unicode characters so the test for spaces, endash,
and terminal punctuation may not be technically correct but it appears, that in practice these characters are rarely
if ever used in DOI names.

]]

local function doi (options)
	local id = options.id;
	local inactive = options.DoiBroken
	local access = options.access;
	local ignore_invalid = options.accept;
	local handler = options.handler;
	local err_flag;

	local text;
	if is_set (inactive) then
		local inactive_year = inactive:match("%d%d%d%d") or '';					-- try to get the year portion from the inactive date
		local inactive_month, good;

		if is_set (inactive_year) then
			if 4 < inactive:len() then											-- inactive date has more than just a year (could be anything)
				local lang_obj = mw.getContentLanguage();						-- get a language object for this wiki
				good, inactive_month = pcall (lang_obj.formatDate, lang_obj, 'F', inactive);	-- try to get the month name from the inactive date
				if not good then
					inactive_month = nil;										-- something went wrong so make sure this is unset
				end
			end
		else
			inactive_year = nil;												-- |doi-broken-date= has something but it isn't a date
		end
		
		if is_set (inactive_year) and is_set (inactive_month) then
			set_message ('maint_doi_inactive_dated', {inactive_year, inactive_month, ' '});
		elseif is_set (inactive_year) then
			set_message ('maint_doi_inactive_dated', {inactive_year, '', ''});
		else
			set_message ('maint_doi_inactive');
		end
		inactive = " (" .. cfg.messages['inactive'] .. ' ' .. inactive .. ')';
	end

	local registrant = mw.ustring.match (id, '^10%.([^/]+)/[^%s–]-[^%.,]$');	-- registrant set when DOI has the proper basic form

	local registrant_err_patterns = {											-- these patterns are for code ranges that are not supported 
		'^[^1-3]%d%d%d%d%.%d%d*$',												-- 5 digits with subcode (0xxxx, 40000+); accepts: 10000–39999
		'^[^1-5]%d%d%d%d$',														-- 5 digits without subcode (0xxxx, 60000+); accepts: 10000–59999
		'^[^1-9]%d%d%d%.%d%d*$',												-- 4 digits with subcode (0xxx); accepts: 1000–9999
		'^[^1-9]%d%d%d$',														-- 4 digits without subcode (0xxx); accepts: 1000–9999
		'^%d%d%d%d%d%d+',														-- 6 or more digits
		'^%d%d?%d?$',															-- less than 4 digits without subcode (with subcode is legitimate)
		'^5555$',																-- test registrant will never resolve
		'[^%d%.]',																-- any character that isn't a digit or a dot
		}

	if not ignore_invalid then
		if registrant then														-- when DOI has proper form
			for i, pattern in ipairs (registrant_err_patterns) do				-- spin through error patterns
				if registrant:match (pattern) then								-- to validate registrant codes
					err_flag = set_message ('err_bad_doi');						-- when found, mark this DOI as bad
					break;														-- and done
				end
			end
		else
			err_flag = set_message ('err_bad_doi');								-- invalid directory or malformed
		end
	else
		set_message ('maint_doi_ignore');
	end

	if err_flag then
		options.coins_list_t['DOI'] = nil;										-- when error, unset so not included in COinS
	end
	
	text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode, access = access,
		auto_link = not (err_flag or is_set (inactive) or ignore_invalid) and 'doi' or nil -- do not auto-link when |doi-broken-date= has a value or when there is a DOI error or (to play it safe, after all, auto-linking is not essential) when invalid DOIs are ignored
		}) .. (inactive or '');

	return text;
end


--[[--------------------------< H D L >------------------------------------------------------------------------

Formats an HDL with minor error checking.

HDL names contain two parts: prefix and suffix separated by a forward slash.
	Prefix: character string using any character in the UCS-2 character set except '/'
	Suffix: character string of any length using any character in the UCS-2 character set chosen by the registrant

This function checks a HDL name for: prefix/suffix.  If the HDL name contains spaces, endashes, or, if it ends
with a period or a comma, this function will emit a bad_hdl error message.

HDL names are case-insensitive and can incorporate any printable Unicode characters so the test for endashes and
terminal punctuation may not be technically correct but it appears, that in practice these characters are rarely
if ever used in HDLs.

Query string parameters are named here: http://www.handle.net/proxy_servlet.html.  query strings are not displayed
but since '?' is an allowed character in an HDL, '?' followed by one of the query parameters is the only way we
have to detect the query string so that it isn't URL-encoded with the rest of the identifier.

]]

local function hdl (options)
	local id = options.id;
	local access = options.access;
	local handler = options.handler;
	local query_params = {														-- list of known query parameters from http://www.handle.net/proxy_servlet.html
		'noredirect',
		'ignore_aliases',
		'auth',
		'cert',
		'index',
		'type',
		'urlappend',
		'locatt',
		'action',
		}
	
	local hdl, suffix, param = id:match ('(.-)(%?(%a+).+)$');					-- look for query string
	local found;

	if hdl then																	-- when there are query strings, this is the handle identifier portion
		for _, q in ipairs (query_params) do									-- spin through the list of query parameters
			if param:match ('^' .. q) then										-- if the query string begins with one of the parameters
				found = true;													-- announce a find
				break;															-- and stop looking
			end
		end
	end

	if found then
		id = hdl;																-- found so replace id with the handle portion; this will be URL-encoded, suffix will not
	else
		suffix = '';															-- make sure suffix is empty string for concatenation else
	end

	local text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, suffix = suffix, separator = handler.separator, encode = handler.encode, access = access})

	if nil == id:match("^[^%s–]-/[^%s–]-[^%.,]$") then							-- HDL must contain a forward slash, must not contain spaces, endashes, and must not end with period or comma
		set_message ('err_bad_hdl' );
		options.coins_list_t['HDL'] = nil;										-- when error, unset so not included in COinS
	end

	return text;
end


--[[--------------------------< I S B N >----------------------------------------------------------------------

Determines whether an ISBN string is valid

]]

local function isbn (options)
	local isbn_str = options.id;
	local ignore_invalid = options.accept;
	local handler = options.handler;

	local function return_result (check, err_type)								-- local function to handle the various returns
		local ISBN = internal_link_id ({link = handler.link, label = handler.label, redirect = handler.redirect,
						prefix = handler.prefix, id = isbn_str, separator = handler.separator});
		if ignore_invalid then													-- if ignoring ISBN errors
			set_message ('maint_isbn_ignore');									-- add a maint category even when there is no error
		else																	-- here when not ignoring
			if not check then													-- and there is an error
				options.coins_list_t['ISBN'] = nil;								-- when error, unset so not included in COinS
				set_message ('err_bad_isbn', err_type);							-- set an error message
				return ISBN;										 			-- return id text
			end
		end
		return ISBN;															-- return id text
	end

	if nil ~= isbn_str:match ('[^%s-0-9X]') then
		return return_result (false, cfg.err_msg_supl.char);					-- fail if isbn_str contains anything but digits, hyphens, or the uppercase X
	end

	local id = isbn_str:gsub ('[%s-]', '');										-- remove hyphens and whitespace

	local len = id:len();
 
	if len ~= 10 and len ~= 13 then
		return return_result (false, cfg.err_msg_supl.length);					-- fail if incorrect length
	end

	if len == 10 then
		if id:match ('^%d*X?$') == nil then										-- fail if isbn_str has 'X' anywhere but last position
			return return_result (false, cfg.err_msg_supl.form);									
		end
		if not is_valid_isxn (id, 10) then										-- test isbn-10 for numerical validity
			return return_result (false, cfg.err_msg_supl.check);				-- fail if isbn-10 is not numerically valid
		end
		if id:find ('^63[01]') then												-- 630xxxxxxx and 631xxxxxxx are (apparently) not valid isbn group ids but are used by amazon as numeric identifiers (asin)
			return return_result (false, cfg.err_msg_supl.group);				-- fail if isbn-10 begins with 630/1
		end
		return return_result (true, cfg.err_msg_supl.check);					-- pass if isbn-10 is numerically valid
	else
		if id:match ('^%d+$') == nil then
			return return_result (false, cfg.err_msg_supl.char);				-- fail if ISBN-13 is not all digits
		end
		if id:match ('^97[89]%d*$') == nil then
			return return_result (false, cfg.err_msg_supl.prefix);				-- fail when ISBN-13 does not begin with 978 or 979
		end
		if id:match ('^9790') then
			return return_result (false, cfg.err_msg_supl.group);				-- group identifier '0' is reserved to ISMN
		end
		return return_result (is_valid_isxn_13 (id), cfg.err_msg_supl.check);
	end
end


--[[--------------------------< A S I N >----------------------------------------------------------------------

Formats a link to Amazon.  Do simple error checking: ASIN must be mix of 10 numeric or uppercase alpha
characters.  If a mix, first character must be uppercase alpha; if all numeric, ASINs must be 10-digit
ISBN. If 10-digit ISBN, add a maintenance category so a bot or AWB script can replace |asin= with |isbn=.
Error message if not 10 characters, if not ISBN-10, if mixed and first character is a digit.

|asin=630....... and |asin=631....... are (apparently) not a legitimate ISBN though it checksums as one; these
do not cause this function to emit the maint_asin message

This function is positioned here because it calls isbn()

]]

local function asin (options)
	local id = options.id;
	local domain = options.ASINTLD;
	
	local err_flag;

	if not id:match("^[%d%u][%d%u][%d%u][%d%u][%d%u][%d%u][%d%u][%d%u][%d%u][%d%u]$") then
		err_flag = set_message ('err_bad_asin');								-- ASIN is not a mix of 10 uppercase alpha and numeric characters
	else
		if id:match("^%d%d%d%d%d%d%d%d%d[%dX]$") then							-- if 10-digit numeric (or 9 digits with terminal X)
			if is_valid_isxn (id, 10) then										-- see if ASIN value is or validates as ISBN-10
				if not id:find ('^63[01]') then									-- 630xxxxxxx and 631xxxxxxx are (apparently) not a valid isbn prefixes but are used by amazon as a numeric identifier
					err_flag = set_message ('err_bad_asin');					-- ASIN has ISBN-10 form but begins with something other than 630/1 so probably an isbn 
				end
			elseif not is_set (err_flag) then
				err_flag = set_message ('err_bad_asin');						-- ASIN is not ISBN-10
			end
		elseif not id:match("^%u[%d%u]+$") then
			err_flag = set_message ('err_bad_asin');							-- asin doesn't begin with uppercase alpha
		end
	end
	if (not is_set (domain)) or in_array (domain, {'us'}) then					-- default: United States
		domain = "com";
	elseif in_array (domain, {'jp', 'uk'}) then									-- Japan, United Kingdom
		domain = "co." .. domain;
	elseif in_array (domain, {'z.cn'}) then 									-- China
		domain = "cn";
	elseif in_array (domain, {'au', 'br', 'mx', 'sg', 'tr'}) then				-- Australia, Brazil, Mexico, Singapore, Turkey
		domain = "com." .. domain;
	elseif not in_array (domain, {'ae', 'ca', 'cn', 'de', 'es', 'fr', 'in', 'it', 'nl', 'pl', 'sa', 'se', 'co.jp', 'co.uk', 'com', 'com.au', 'com.br', 'com.mx', 'com.sg', 'com.tr'}) then -- Arabic Emirates, Canada, China, Germany, Spain, France, Indonesia, Italy, Netherlands, Poland, Saudi Arabia, Sweden (as of 2021-03 Austria (.at), Liechtenstein (.li) and Switzerland (.ch) still redirect to the German site (.de) with special settings, so don't maintain local ASINs for them)
		err_flag = set_message ('err_bad_asin_tld');							-- unsupported asin-tld value
	end
	local handler = options.handler;

	if not is_set (err_flag) then
		options.coins_list_t['ASIN'] = handler.prefix .. domain .. "/dp/" .. id;	-- asin for coins
	else
		options.coins_list_t['ASIN'] = nil;										-- when error, unset so not included in COinS
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix .. domain .. "/dp/",
		id = id, encode = handler.encode, separator = handler.separator})
end


--[[--------------------------< I S M N >----------------------------------------------------------------------

Determines whether an ISMN string is valid.  Similar to ISBN-13, ISMN is 13 digits beginning 979-0-... and uses the
same check digit calculations.  See http://www.ismn-international.org/download/Web_ISMN_Users_Manual_2008-6.pdf
section 2, pages 9–12.

ismn value not made part of COinS metadata because we don't have a url or isn't a COinS-defined identifier (rft.xxx)
or an identifier registered at info-uri.info (info:)

]]

local function ismn (options)
	local id = options.id;
	local handler = options.handler;
	local text;
	local valid_ismn = true;
	local id_copy;

	id_copy = id;																-- save a copy because this testing is destructive
	id = id:gsub ('[%s-]', '');													-- remove hyphens and white space

	if 13 ~= id:len() or id:match ("^9790%d*$" ) == nil then					-- ISMN must be 13 digits and begin with 9790
		valid_ismn = false;
	else
		valid_ismn=is_valid_isxn_13 (id);										-- validate ISMN
	end

	--	text = internal_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,		-- use this (or external version) when there is some place to link to
	--		prefix = handler.prefix, id = id_copy, separator = handler.separator, encode = handler.encode})

	text = table.concat (														-- because no place to link to yet
		{
		make_wikilink (link_label_make (handler), handler.label),
		handler.separator,
		id_copy
		});

	if false == valid_ismn then
		options.coins_list_t['ISMN'] = nil;										-- when error, unset so not included in COinS; not really necessary here because ismn not made part of COinS
		set_message ('err_bad_ismn');											-- create an error message if the ISMN is invalid
	end 
	
	return text;
end


--[[--------------------------< I S S N >----------------------------------------------------------------------

Validate and format an ISSN.  This code fixes the case where an editor has included an ISSN in the citation but
has separated the two groups of four digits with a space.  When that condition occurred, the resulting link looked
like this:

	|issn=0819 4327 gives: [http://www.worldcat.org/issn/0819 4327 0819 4327]	-- can't have spaces in an external link
	
This code now prevents that by inserting a hyphen at the ISSN midpoint.  It also validates the ISSN for length
and makes sure that the checkdigit agrees with the calculated value.  Incorrect length (8 digits), characters
other than 0-9 and X, or checkdigit / calculated value mismatch will all cause a check ISSN error message.  The
ISSN is always displayed with a hyphen, even if the ISSN was given as a single group of 8 digits.

]]

local function issn (options)
	local id = options.id;
	local handler = options.handler;
	local ignore_invalid = options.accept;

	local issn_copy = id;														-- save a copy of unadulterated ISSN; use this version for display if ISSN does not validate
	local text;
	local valid_issn = true;

	id = id:gsub ('[%s-]', '');													-- remove hyphens and whitespace

	if 8 ~= id:len() or nil == id:match ("^%d*X?$" ) then						-- validate the ISSN: 8 digits long, containing only 0-9 or X in the last position
		valid_issn = false;														-- wrong length or improper character
	else
		valid_issn = is_valid_isxn (id, 8);										-- validate ISSN
	end

	if true == valid_issn then
		id = string.sub (id, 1, 4 ) .. "-" .. string.sub (id, 5 );				-- if valid, display correctly formatted version
	else
		id = issn_copy;															-- if not valid, show the invalid ISSN with error message
	end

	text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode})

	if ignore_invalid then
		set_message ('maint_issn_ignore');
	else
		if false == valid_issn then
			options.coins_list_t['ISSN'] = nil;									-- when error, unset so not included in COinS
			set_message ('err_bad_issn', (options.hkey == 'EISSN') and 'e' or '');	-- create an error message if the ISSN is invalid
		end 
	end
	
	return text;
end


--[[--------------------------< J F M >-----------------------------------------------------------------------

A numerical identifier in the form nn.nnnn.nn

]]

local function jfm (options)
	local id = options.id;
	local handler = options.handler;
	local id_num;

	id_num = id:match ('^[Jj][Ff][Mm](.*)$');									-- identifier with jfm prefix; extract identifier

	if is_set (id_num) then
		set_message ('maint_jfm_format');
	else																		-- plain number without JFM prefix
		id_num = id;															-- if here id does not have prefix
	end

	if id_num and id_num:match('^%d%d%.%d%d%d%d%.%d%d$') then
		id = id_num;															-- jfm matches pattern
	else
		set_message ('err_bad_jfm' );											-- set an error message
		options.coins_list_t['JFM'] = nil;										-- when error, unset so not included in COinS
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode});
end


--[[--------------------------< J S T O R >--------------------------------------------------------------------

Format a JSTOR with some error checking

]]

local function jstor (options)
	local id = options.id;
	local access = options.access;
	local handler = options.handler;

	if id:find ('[Jj][Ss][Tt][Oo][Rr]') or id:find ('^https?://') or id:find ('%s') then
		set_message ('err_bad_jstor');											-- set an error message
		options.coins_list_t['JSTOR'] = nil;									-- when error, unset so not included in COinS
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode, access = access});
end


--[[--------------------------< L C C N >----------------------------------------------------------------------

Format LCCN link and do simple error checking.  LCCN is a character string 8-12 characters long. The length of
the LCCN dictates the character type of the first 1-3 characters; the rightmost eight are always digits.
http://info-uri.info/registry/OAIHandler?verb=GetRecord&metadataPrefix=reg&identifier=info:lccn/

length = 8 then all digits
length = 9 then lccn[1] is lowercase alpha
length = 10 then lccn[1] and lccn[2] are both lowercase alpha or both digits
length = 11 then lccn[1] is lower case alpha, lccn[2] and lccn[3] are both lowercase alpha or both digits
length = 12 then lccn[1] and lccn[2] are both lowercase alpha

]]

local function lccn (options)
	local lccn = options.id;
	local handler = options.handler;
	local err_flag;																-- presume that LCCN is valid
	local id = lccn;															-- local copy of the LCCN

	id = normalize_lccn (id);													-- get canonical form (no whitespace, hyphens, forward slashes)
	local len = id:len();														-- get the length of the LCCN

	if 8 == len then
		if id:match("[^%d]") then												-- if LCCN has anything but digits (nil if only digits)
			err_flag = set_message ('err_bad_lccn');							-- set an error message
		end
	elseif 9 == len then														-- LCCN should be adddddddd
		if nil == id:match("%l%d%d%d%d%d%d%d%d") then							-- does it match our pattern?
			err_flag = set_message ('err_bad_lccn');							-- set an error message
		end
	elseif 10 == len then														-- LCCN should be aadddddddd or dddddddddd
		if id:match("[^%d]") then												-- if LCCN has anything but digits (nil if only digits) ...
			if nil == id:match("^%l%l%d%d%d%d%d%d%d%d") then					-- ... see if it matches our pattern
				err_flag = set_message ('err_bad_lccn');						-- no match, set an error message
			end
		end
	elseif 11 == len then														-- LCCN should be aaadddddddd or adddddddddd
		if not (id:match("^%l%l%l%d%d%d%d%d%d%d%d") or id:match("^%l%d%d%d%d%d%d%d%d%d%d")) then	-- see if it matches one of our patterns
			err_flag = set_message ('err_bad_lccn');							-- no match, set an error message
		end
	elseif 12 == len then														-- LCCN should be aadddddddddd
		if not id:match("^%l%l%d%d%d%d%d%d%d%d%d%d") then						-- see if it matches our pattern
			err_flag = set_message ('err_bad_lccn');							-- no match, set an error message
		end
	else
		err_flag = set_message ('err_bad_lccn');								-- wrong length, set an error message
	end

	if not is_set (err_flag) and nil ~= lccn:find ('%s') then
		err_flag = set_message ('err_bad_lccn');								-- lccn contains a space, set an error message
	end

	if is_set (err_flag) then
		options.coins_list_t['LCCN'] = nil;										-- when error, unset so not included in COinS
	end

	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = lccn, separator = handler.separator, encode = handler.encode});
end


--[[--------------------------< M R >--------------------------------------------------------------------------

A seven digit number; if not seven digits, zero-fill leading digits to make seven digits.

]]

local function mr (options)
	local id = options.id;
	local handler = options.handler;
	local id_num;
	local id_len;

	id_num = id:match ('^[Mm][Rr](%d+)$');										-- identifier with mr prefix

	if is_set (id_num) then
		set_message ('maint_mr_format');										-- add maint cat
	else																		-- plain number without mr prefix
		id_num = id:match ('^%d+$');											-- if here id is all digits
	end

	id_len = id_num and id_num:len() or 0;
	if (7 >= id_len) and (0 ~= id_len) then
		id = string.rep ('0', 7-id_len) .. id_num;								-- zero-fill leading digits
	else
		set_message ('err_bad_mr');												-- set an error message
		options.coins_list_t['MR'] = nil;										-- when error, unset so not included in COinS
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode});
end


--[[--------------------------< O C L C >----------------------------------------------------------------------

Validate and format an OCLC ID.  https://www.oclc.org/batchload/controlnumber.en.html {{dead link}}
archived at: https://web.archive.org/web/20161228233804/https://www.oclc.org/batchload/controlnumber.en.html

]]

local function oclc (options)
	local id = options.id;
	local handler = options.handler;
	local number;

	if id:match('^ocm%d%d%d%d%d%d%d%d$') then									-- ocm prefix and 8 digits; 001 field (12 characters)
		number = id:match('ocm(%d+)');											-- get the number
	elseif id:match('^ocn%d%d%d%d%d%d%d%d%d$') then								-- ocn prefix and 9 digits; 001 field (12 characters)
		number = id:match('ocn(%d+)');											-- get the number
	elseif id:match('^on%d%d%d%d%d%d%d%d%d%d+$') then							-- on prefix and 10 or more digits; 001 field (12 characters)
		number = id:match('^on(%d%d%d%d%d%d%d%d%d%d+)$');						-- get the number
	elseif id:match('^%(OCoLC%)[1-9]%d*$') then									-- (OCoLC) prefix and variable number digits; no leading zeros; 035 field
		number = id:match('%(OCoLC%)([1-9]%d*)');								-- get the number
		if 9 < number:len() then
			number = nil;														-- constrain to 1 to 9 digits; change this when OCLC issues 10-digit numbers
		end
	elseif id:match('^%d+$') then												-- no prefix
		number = id;															-- get the number
		if 10 < number:len() then
			number = nil;														-- constrain to 1 to 10 digits; change this when OCLC issues 11-digit numbers
		end
	end

	if number then																-- proper format
		id = number;															-- exclude prefix, if any, from external link
	else
		set_message ('err_bad_oclc')											-- add an error message if the id is malformed
		options.coins_list_t['OCLC'] = nil;										-- when error, unset so not included in COinS
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode});
end


--[[--------------------------< O P E N L I B R A R Y >--------------------------------------------------------

Formats an OpenLibrary link, and checks for associated errors.

]]

local function openlibrary (options)
	local id = options.id;
	local access = options.access;
	local handler = options.handler;
	local ident, code = id:gsub('^OL', ''):match("^(%d+([AMW]))$");				-- strip optional OL prefix followed immediately by digits followed by 'A', 'M', or 'W';
	local err_flag;
	local prefix = {															-- these are appended to the handler.prefix according to code
		['A']='authors/OL',
		['M']='books/OL',
		['W']='works/OL',
		['X']='OL'																-- not a code; spoof when 'code' in id is invalid
		};

	if not ident then
		code = 'X';																-- no code or id completely invalid
		ident = id;																-- copy id to ident so that we display the flawed identifier
		err_flag = set_message ('err_bad_ol');
	end

	if not is_set (err_flag) then
		options.coins_list_t['OL'] = handler.prefix .. prefix[code] .. ident;	-- experiment for ol coins
	else
		options.coins_list_t['OL'] = nil;										-- when error, unset so not included in COinS
	end

	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix .. prefix[code],
		id = ident, separator = handler.separator, encode = handler.encode,
		access = access});
end


--[[--------------------------< O S T I >----------------------------------------------------------------------

Format OSTI and do simple error checking. OSTIs are sequential numbers beginning at 1 and counting up.  This
code checks the OSTI to see that it contains only digits and is less than test_limit specified in the configuration;
the value in test_limit will need to be updated periodically as more OSTIs are issued.

NB. 1018 is the lowest OSTI number found in the wild (so far) and resolving OK on the OSTI site

]]

local function osti (options)
	local id = options.id;
	local access = options.access;
	local handler = options.handler;

	if id:match("[^%d]") then													-- if OSTI has anything but digits
		set_message ('err_bad_osti');											-- set an error message
		options.coins_list_t['OSTI'] = nil;										-- when error, unset so not included in COinS
	else																		-- OSTI is only digits
		local id_num = tonumber (id);											-- convert id to a number for range testing
		if 1018 > id_num or handler.id_limit < id_num then						-- if OSTI is outside test limit boundaries
			set_message ('err_bad_osti');										-- set an error message
			options.coins_list_t['OSTI'] = nil;									-- when error, unset so not included in COinS
		end
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode, access = access});
end


--[[--------------------------< P M C >------------------------------------------------------------------------

Format a PMC, do simple error checking, and check for embargoed articles.

The embargo parameter takes a date for a value. If the embargo date is in the future the PMC identifier will not
be linked to the article.  If the embargo date is today or in the past, or if it is empty or omitted, then the
PMC identifier is linked to the article through the link at cfg.id_handlers['PMC'].prefix.

PMC embargo date testing is done in function is_embargoed () which is called earlier because when the citation
has |pmc=<value> but does not have a |url= then |title= is linked with the PMC link.  Function is_embargoed ()
returns the embargo date if the PMC article is still embargoed, otherwise it returns an empty string.

PMCs are sequential numbers beginning at 1 and counting up.  This code checks the PMC to see that it contains only digits and is less
than test_limit; the value in local variable test_limit will need to be updated periodically as more PMCs are issued.

]]

local function pmc (options)
	local id = options.id;
	local embargo = options.Embargo;											-- TODO: lowercase?
	local handler = options.handler;
	local err_flag;
	local id_num;
	local text;

	id_num = id:match ('^[Pp][Mm][Cc](%d+)$');									-- identifier with PMC prefix

	if is_set (id_num) then
		set_message ('maint_pmc_format');
	else																		-- plain number without PMC prefix
		id_num = id:match ('^%d+$');											-- if here id is all digits
	end

	if is_set (id_num) then														-- id_num has a value so test it
		id_num = tonumber (id_num);												-- convert id_num to a number for range testing
		if 1 > id_num or handler.id_limit < id_num then							-- if PMC is outside test limit boundaries
			err_flag = set_message ('err_bad_pmc');								-- set an error message
		else
			id = tostring (id_num);												-- make sure id is a string
		end
	else																		-- when id format incorrect
		err_flag = set_message ('err_bad_pmc');									-- set an error message
	end
	
	if is_set (embargo) and is_set (is_embargoed (embargo)) then				-- is PMC is still embargoed?
		text = table.concat (													-- still embargoed so no external link
			{
			make_wikilink (link_label_make (handler), handler.label),
			handler.separator,
			id,
			});
	else
		text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,	-- no embargo date or embargo has expired, ok to link to article
			prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode, access = handler.access,
			auto_link = not err_flag and 'pmc' or nil							-- do not auto-link when PMC has error
			});
	end

	if err_flag then
		options.coins_list_t['PMC'] = nil;										-- when error, unset so not included in COinS
	end

	return text;
end


--[[--------------------------< P M I D >----------------------------------------------------------------------

Format PMID and do simple error checking.  PMIDs are sequential numbers beginning at 1 and counting up.  This
code checks the PMID to see that it contains only digits and is less than test_limit; the value in local variable
test_limit will need to be updated periodically as more PMIDs are issued.

]]

local function pmid (options)
	local id = options.id;
	local handler = options.handler;

	if id:match("[^%d]") then													-- if PMID has anything but digits
		set_message ('err_bad_pmid');											-- set an error message
		options.coins_list_t['PMID'] = nil;										-- when error, unset so not included in COinS
	else																		-- PMID is only digits
		local id_num = tonumber (id);											-- convert id to a number for range testing
		if 1 > id_num or handler.id_limit < id_num then							-- if PMID is outside test limit boundaries
			set_message ('err_bad_pmid');										-- set an error message
			options.coins_list_t['PMID'] = nil;									-- when error, unset so not included in COinS
		end
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode});
end


--[[--------------------------< R F C >------------------------------------------------------------------------

Format RFC and do simple error checking. RFCs are sequential numbers beginning at 1 and counting up.  This
code checks the RFC to see that it contains only digits and is less than test_limit specified in the configuration;
the value in test_limit will need to be updated periodically as more RFCs are issued.

An index of all RFCs is here: https://tools.ietf.org/rfc/

]]

local function rfc (options)
	local id = options.id;
	local handler = options.handler;

	if id:match("[^%d]") then													-- if RFC has anything but digits
		set_message ('err_bad_rfc');											-- set an error message
		options.coins_list_t['RFC'] = nil;										-- when error, unset so not included in COinS
	else																		-- RFC is only digits
		local id_num = tonumber (id);											-- convert id to a number for range testing
		if 1 > id_num or handler.id_limit < id_num then							-- if RFC is outside test limit boundaries
			set_message ('err_bad_rfc');										-- set an error message
			options.coins_list_t['RFC'] = nil;									-- when error, unset so not included in COinS
		end
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode, access = handler.access});
end


--[[--------------------------< S 2 C I D >--------------------------------------------------------------------

Format an S2CID, do simple error checking

S2CIDs are sequential numbers beginning at 1 and counting up.  This code checks the S2CID to see that it is only
digits and is less than test_limit; the value in local variable test_limit will need to be updated periodically
as more S2CIDs are issued.

]]

local function s2cid (options)
	local id = options.id;
	local access = options.access;
	local handler = options.handler;
	local id_num;
	local text;
	
	id_num = id:match ('^[1-9]%d*$');											-- id must be all digits; must not begin with 0; no open access flag

 	if is_set (id_num) then														-- id_num has a value so test it
		id_num = tonumber (id_num);												-- convert id_num to a number for range testing
		if handler.id_limit < id_num then										-- if S2CID is outside test limit boundaries
			set_message ('err_bad_s2cid');										-- set an error message
			options.coins_list_t['S2CID'] = nil;								-- when error, unset so not included in COinS
		end
	else																		-- when id format incorrect
		set_message ('err_bad_s2cid');											-- set an error message
		options.coins_list_t['S2CID'] = nil;									-- when error, unset so not included in COinS
	end

	text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode, access = access});

	return text;
end


--[[--------------------------< S B N >------------------------------------------------------------------------

9-digit form of ISBN-10; uses same check-digit validation when SBN is prefixed with an additional '0' to make 10 digits

sbn value not made part of COinS metadata because we don't have a url or isn't a COinS-defined identifier (rft.xxx)
or an identifier registered at info-uri.info (info:)

]]

local function sbn (options)
	local id = options.id;
	local ignore_invalid = options.accept;
	local handler = options.handler;
	local function return_result (check, err_type)								-- local function to handle the various returns
		local SBN = internal_link_id ({link = handler.link, label = handler.label, redirect = handler.redirect,
						prefix = handler.prefix, id = id, separator = handler.separator});
		if not ignore_invalid then												-- if not ignoring SBN errors
			if not check then
				options.coins_list_t['SBN'] = nil;								-- when error, unset so not included in COinS; not really necessary here because sbn not made part of COinS
				set_message ('err_bad_sbn', {err_type});						-- display an error message
				return SBN; 
			end
		else
			set_message ('maint_isbn_ignore');									-- add a maint category even when there is no error (ToDo: Possibly switch to separate message for SBNs only)
		end
		return SBN;
	end

	if id:match ('[^%s-0-9X]') then
		return return_result (false, cfg.err_msg_supl.char);					-- fail if SBN contains anything but digits, hyphens, or the uppercase X
	end

	local ident = id:gsub ('[%s-]', '');										-- remove hyphens and whitespace; they interfere with the rest of the tests

	if  9 ~= ident:len() then
		return return_result (false, cfg.err_msg_supl.length);					-- fail if incorrect length
	end

	if ident:match ('^%d*X?$') == nil then
		return return_result (false, cfg.err_msg_supl.form);					-- fail if SBN has 'X' anywhere but last position
	end

	return return_result (is_valid_isxn ('0' .. ident, 10), cfg.err_msg_supl.check);
end


--[[--------------------------< S S R N >----------------------------------------------------------------------

Format an SSRN, do simple error checking

SSRNs are sequential numbers beginning at 100? and counting up.  This code checks the SSRN to see that it is
only digits and is greater than 99 and less than test_limit; the value in local variable test_limit will need
to be updated periodically as more SSRNs are issued.

]]

local function ssrn (options)
	local id = options.id;
	local handler = options.handler;
	local id_num;
	local text;
	
	id_num = id:match ('^%d+$');												-- id must be all digits

	if is_set (id_num) then														-- id_num has a value so test it
		id_num = tonumber (id_num);												-- convert id_num to a number for range testing
		if 100 > id_num or handler.id_limit < id_num then						-- if SSRN is outside test limit boundaries
			set_message ('err_bad_ssrn');										-- set an error message
			options.coins_list_t['SSRN'] = nil;									-- when error, unset so not included in COinS
		end
	else																		-- when id format incorrect
		set_message ('err_bad_ssrn');											-- set an error message
		options.coins_list_t['SSRN'] = nil;										-- when error, unset so not included in COinS
	end
	
	text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode, access = options.access});

	return text;
end


--[[--------------------------< U S E N E T _ I D >------------------------------------------------------------

Validate and format a usenet message id.  Simple error checking, looks for 'id-left@id-right' not enclosed in
'<' and/or '>' angle brackets.

]]

local function usenet_id (options)
	local id = options.id;
	local handler = options.handler;

	local text = external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
		prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode})
 
	if not id:match('^.+@.+$') or not id:match('^[^<].*[^>]$') then				-- doesn't have '@' or has one or first or last character is '< or '>'
		set_message ('err_bad_usenet_id')										-- add an error message if the message id is invalid
		options.coins_list_t['USENETID'] = nil;									-- when error, unset so not included in COinS
	end 
	
	return text;
end


--[[--------------------------< Z B L >-----------------------------------------------------------------------

A numerical identifier in the form nnnn.nnnnn - leading zeros in the first quartet optional

format described here: http://emis.mi.sanu.ac.rs/ZMATH/zmath/en/help/search/

temporary format is apparently eight digits.  Anything else is an error

]]

local function zbl (options)
	local id = options.id;
	local handler = options.handler;

	if id:match('^%d%d%d%d%d%d%d%d$') then										-- is this identifier using temporary format?
		set_message ('maint_zbl');												-- yes, add maint cat
	elseif not id:match('^%d?%d?%d?%d%.%d%d%d%d%d$') then						-- not temporary, is it normal format?
		set_message ('err_bad_zbl');											-- no, set an error message
		options.coins_list_t['ZBL'] = nil;										-- when error, unset so not included in COinS
	end
	
	return external_link_id ({link = handler.link, label = handler.label, q = handler.q, redirect = handler.redirect,
			prefix = handler.prefix, id = id, separator = handler.separator, encode = handler.encode});
end


--============================<< I N T E R F A C E   F U N C T I O N S >>==========================================

--[[--------------------------< E X T R A C T _ I D S >------------------------------------------------------------

Populates ID table from arguments using configuration settings. Loops through cfg.id_handlers and searches args for
any of the parameters listed in each cfg.id_handlers['...'].parameters.  If found, adds the parameter and value to
the identifier list.  Emits redundant error message if more than one alias exists in args

]]

local function extract_ids (args)
	local id_list = {};															-- list of identifiers found in args
	for k, v in pairs (cfg.id_handlers) do										-- k is uppercase identifier name as index to cfg.id_handlers; e.g. cfg.id_handlers['ISBN'], v is a table
		v = select_one (args, v.parameters, 'err_redundant_parameters' );		-- v.parameters is a table of aliases for k; here we pick one from args if present
		if is_set (v) then id_list[k] = v; end									-- if found in args, add identifier to our list
	end
	return id_list;
end


--[[--------------------------< E X T R A C T _ I D _ A C C E S S _ L E V E L S >--------------------------------------

Fetches custom id access levels from arguments using configuration settings. Parameters which have a predefined access
level (e.g. arxiv) do not use this function as they are directly rendered as free without using an additional parameter.

returns a table of k/v pairs where k is same as the identifier's key in cfg.id_handlers and v is the assigned (valid) keyword

access-level values must match the case used in cfg.keywords_lists['id-access'] (lowercase unless there is some special reason for something else)

]]

local function extract_id_access_levels (args, id_list)
	local id_accesses_list = {};
	for k, v in pairs (cfg.id_handlers) do
		local access_param = v.custom_access;									-- name of identifier's access-level parameter
		if is_set (access_param) then
			local access_level = args[access_param];							-- get the assigned value if there is one
			if is_set (access_level) then
				if not in_array (access_level, cfg.keywords_lists['id-access']) then	-- exact match required
					set_message ('err_invalid_param_val', {access_param, access_level});	
					access_level = nil;											-- invalid so unset
				end
				if not is_set (id_list[k]) then									-- identifier access-level must have a matching identifier
					set_message ('err_param_access_requires_param', {k:lower()});	-- parameter name is uppercase in cfg.id_handlers (k); lowercase for error message
				end
				id_accesses_list[k] = cfg.keywords_xlate[access_level];			-- get translated keyword
			end
		end
	end
	return id_accesses_list;
end


--[[--------------------------< B U I L D _ I D _ L I S T >----------------------------------------------------

render the identifiers into a sorted sequence table

<ID_list_coins_t> is a table of k/v pairs where k is same as key in cfg.id_handlers and v is the assigned value
<options_t> is a table of various k/v option pairs provided in the call to new_build_id_list();
	modified by	this function and passed to all identifier rendering functions
<access_levels_t> is a table of k/v pairs where k is same as key in cfg.id_handlers and v is the assigned value (if valid)

returns a sequence table of sorted (by hkey - 'handler' key) rendered identifier strings

]]

local function build_id_list (ID_list_coins_t, options_t, access_levels_t)
	local ID_list_t = {};
	local accept;
	local func_map = {															--function map points to functions associated with hkey identifier
		['ARXIV'] = arxiv,
		['ASIN'] = asin,
		['BIBCODE'] = bibcode,
		['BIORXIV'] = biorxiv,
		['CITESEERX'] = citeseerx,
		['DOI'] = doi,
		['EISSN'] = issn,
		['HDL'] = hdl,
		['ISBN'] = isbn,
		['ISMN'] = ismn,
		['ISSN'] = issn,
		['JFM'] = jfm,
		['JSTOR'] = jstor,
		['LCCN'] = lccn,
		['MR'] = mr,
		['OCLC'] = oclc,
		['OL'] = openlibrary,
		['OSTI'] = osti,
		['PMC'] = pmc,
		['PMID'] = pmid,
		['RFC']  = rfc,
		['S2CID'] = s2cid,
		['SBN'] = sbn,
		['SSRN'] = ssrn,
		['USENETID'] = usenet_id,
		['ZBL'] = zbl,
		}

	for hkey, v in pairs (ID_list_coins_t) do
		v, accept = has_accept_as_written (v);									-- remove accept-as-written markup if present; accept is boolean true when markup removed; false else
																				-- every function gets the options table with value v and accept boolean
		options_t.hkey = hkey;													-- ~/Configuration handler key
		options_t.id = v;														-- add that identifier value to the options table
		options_t.accept = accept;												-- add the accept boolean flag
		options_t.access = access_levels_t[hkey];								-- add the access level for those that have an |<identifier-access= parameter
		options_t.handler = cfg.id_handlers[hkey];
		options_t.coins_list_t = ID_list_coins_t;								-- pointer to ID_list_coins_t; for |asin= and |ol=; also to keep erroneous values out of the citation's metadata
		options_t.coins_list_t[hkey] = v;										-- id value without accept-as-written markup for metadata
		
		if options_t.handler.access and not in_array (options_t.handler.access, cfg.keywords_lists['id-access']) then
			error (cfg.messages['unknown_ID_access'] .. options_t.handler.access);	-- here when handler access key set to a value not listed in list of allowed id access keywords
		end

		if func_map[hkey] then
			local id_text = func_map[hkey] (options_t);							-- call the function to get identifier text and any error message
			table.insert (ID_list_t, {hkey, id_text});							-- add identifier text to the output sequence table
		else
			error (cfg.messages['unknown_ID_key'] .. hkey);						-- here when func_map doesn't have a function for hkey
		end
	end

	local function comp (a, b)													-- used by following table.sort()
		return a[1]:lower() < b[1]:lower();										-- sort by hkey
	end

	table.sort (ID_list_t, comp);												-- sequence table of tables sort	
	for k, v in ipairs (ID_list_t) do											-- convert sequence table of tables to simple sequence table of strings
		ID_list_t[k] = v[2];													-- v[2] is the identifier rendering from the call to the various functions in func_map{}
	end
	
	return ID_list_t;
end


--[[--------------------------< O P T I O N S _ C H E C K >----------------------------------------------------

check that certain option parameters have their associated identifier parameters with values

<ID_list_coins_t> is a table of k/v pairs where k is same as key in cfg.id_handlers and v is the assigned value
<ID_support_t> is a sequence table of tables created in citation0() where each subtable has four elements:
	[1] is the support parameter's assigned value; empty string if not set
	[2] is a text string same as key in cfg.id_handlers
	[3] is cfg.error_conditions key used to create error message
	[4] is original ID support parameter name used to create error message
	
returns nothing; on error emits an appropriate error message

]]

local function options_check (ID_list_coins_t, ID_support_t)
	for _, v in ipairs (ID_support_t) do
		if is_set (v[1]) and not ID_list_coins_t[v[2]] then						-- when support parameter has a value but matching identifier parameter is missing or empty
			set_message (v[3], (v[4]));											-- emit the appropriate error message
		end
	end
end


--[[--------------------------< I D E N T I F I E R _ L I S T S _ G E T >--------------------------------------

Creates two identifier lists: a k/v table of identifiers and their values to be used locally and for use in the
COinS metadata, and a sequence table of the rendered identifier strings that will be included in the rendered
citation.

]]

local function identifier_lists_get (args_t, options_t, ID_support_t)
	local ID_list_coins_t = extract_ids (args_t);										-- get a table of identifiers and their values for use locally and for use in COinS
	options_check (ID_list_coins_t, ID_support_t);										-- ID support parameters must have matching identifier parameters 
	local ID_access_levels_t = extract_id_access_levels (args_t, ID_list_coins_t);		-- get a table of identifier access levels
	local ID_list_t = build_id_list (ID_list_coins_t, options_t, ID_access_levels_t);	-- get a sequence table of rendered identifier strings

	return ID_list_t, ID_list_coins_t;											-- return the tables
end


--[[--------------------------< S E T _ S E L E C T E D _ M O D U L E S >--------------------------------------

Sets local cfg table and imported functions table to same (live or sandbox) as that used by the other modules.

]]

local function set_selected_modules (cfg_table_ptr, utilities_page_ptr)
	cfg = cfg_table_ptr;

	has_accept_as_written = utilities_page_ptr.has_accept_as_written;			-- import functions from select Module:Citation/CS1/Utilities module
	is_set = utilities_page_ptr.is_set;								
	in_array = utilities_page_ptr.in_array;
	set_message = utilities_page_ptr.set_message;
	select_one = utilities_page_ptr.select_one;
	substitute = utilities_page_ptr.substitute;
	make_wikilink = utilities_page_ptr.make_wikilink;

	z = utilities_page_ptr.z;													-- table of tables in Module:Citation/CS1/Utilities
end


--[[--------------------------< E X P O R T E D   F U N C T I O N S >------------------------------------------
]]

return {
	auto_link_urls = auto_link_urls,											-- table of identifier URLs to be used when auto-linking |title=
	
	identifier_lists_get = identifier_lists_get,								-- experiment to replace individual calls to build_id_list(), extract_ids, extract_id_access_levels
	is_embargoed = is_embargoed;
	set_selected_modules = set_selected_modules;
	}
