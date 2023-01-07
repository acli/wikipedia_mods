local lang_obj = mw.language.getContentLanguage();								-- make a language object for the local language; used here for languages and dates 

--[[--------------------------< U N C A T E G O R I Z E D _ N A M E S P A C E S >------------------------------

List of namespaces that should not be included in citation error categories.
Same as setting notracking = true by default.

Note: Namespace names should use underscores instead of spaces.

]]

local uncategorized_namespaces = { 'User', 'Talk', 'User_talk', 'Wikipedia_talk',
	'File_talk', 'Template_talk', 'Help_talk', 'Category_talk', 'Portal_talk',
	'Book_talk', 'Draft_talk', 'Education_Program_talk', 'Module_talk', 'MediaWiki_talk' };
local uncategorized_subpages = {'/[Ss]andbox', '/[Tt]estcases', '/[^/]*[Ll]og', '/[Aa]rchive'};		-- list of Lua patterns found in page names of pages we should not categorize


--[[--------------------------< M E S S A G E S >--------------------------------------------------------------

Translation table

The following contains fixed text that may be output as part of a citation.
This is separated from the main body to aid in future translations of this
module.

]]

local messages = {
	['agency'] = '$1 $2',														-- $1 is sepc, $2 is agency
	['archived-dead'] = '$1喺$2歸檔',
	['archived-live'] = '原先內容$1喺$2',
	['archived-missing'] = '原先內容$1喺$2歸檔',
	['archived-unfit'] = '歸檔時間',
	['archived'] = '歸檔',
	['by'] = '作者',																-- contributions to authored works: introduction, foreword, afterword
	['cartography'] = '地圖作者$1',
	['editor'] = '編',
	['editors'] = '編',
	['edition'] = '(第$1版)',
	['episode'] = '第$1集',
	['et al'] = '等',
	['in'] = '出自',																-- edited works
	['inactive'] = '失效',
	['inset'] = '$1頁內',
	['interview'] = '$1採訪',										
	['lay summary'] = '通俗摘要',
	['newsgroup'] = '[[新聞組]]：$1',
	['original'] = '原著',
	['origdate'] = ' [$1]',
	['published'] = ' ($1出版)',
	['retrieved'] = '喺$1搵到',
	['season'] = '第$1季',
	['section'] = '§ $1',
	['sections'] = '§§ $1',
	['series'] = '$1 $2',														-- $1 is sepc, $2 is series
	['seriesnum'] = '第$1系列',
	['translated'] = '$1翻譯',
	['type'] = ' ($1)',															-- for titletype
	['written'] = '寫喺$1',

	['vol'] = '$1第$2卷',												-- $1 is sepc; bold journal style volume is in presentation{}
	['vol-no'] = '$1第$2卷第$3號',									-- sepc, volume, issue
	['issue'] = '$1第$2號',												-- $1 is sepc

	['j-vol'] = '$1 $2',														-- sepc, volume; bold journal volume is in presentation{}
	['j-issue'] = ' ($1)',

	['nopp'] = '$1 $2';															-- page(s) without prefix; $1 is sepc

	['p-prefix'] = "$1 p.&nbsp;$2",												-- $1 is sepc
	['pp-prefix'] = "$1 pp.&nbsp;$2",											-- $1 is sepc
	['j-page(s)'] = ': $1',														-- same for page and pages

	['sheet'] = '$1第$2頁',												-- $1 is sepc
	['sheets'] = '$1第$2頁',											-- $1 is sepc
	['j-sheet'] = '：第$1頁',
	['j-sheets'] = '：第$1頁',
	
	['language'] = '($1)',
	['via'] = " &ndash;透過$1",
	['event'] = '時間',		-- 指 time 參數，引用影片/錄音乜嘢時間開始嘅部分
	['minutes'] = '分鐘',	-- 指 minutes 參數，引用影片/錄音第幾分鐘開始嘅部分
	
	-- Determines the location of the help page
	['help page link'] = 'Help:CS1 errors',
	['help page label'] = 'help',
	
	-- categories
	['cat wikilink'] = '[[Category:$1]]',										-- $1 is the category name
	[':cat wikilink'] = '[[:Category:$1|link]]',								-- category name as maintenance message wikilink; $1 is the category name

	-- Internal errors (should only occur if configuration is bad)
	['undefined_error'] = 'Called with an undefined error condition',
	['unknown_ID_key'] = 'Unrecognized ID key: ',								-- an ID key in id_handlers not found in ~/Identifiers func_map{}
	['unknown_ID_access'] = 'Unrecognized ID access keyword: ',					-- an ID access keyword in id_handlers not found in keywords_lists['id-access']{}
	['unknown_argument_map'] = 'Argument map not defined for this variable',
	['bare_url_no_origin'] = 'Bare URL found but origin indicator is nil or empty',
	
	['warning_msg_e'] = '<span style="color:#d33">One or more <code style="color: inherit; background: inherit; border: none; padding: inherit;">&#123;{$1}}</code> templates have errors</span>; messages may be hidden ([[Help:CS1_errors#Controlling_error_message_display|help]]).';	-- $1 is template link
	['warning_msg_m'] = '<span style="color:#3a3">One or more <code style="color: inherit; background: inherit; border: none; padding: inherit;">&#123;{$1}}</code> templates have maintenance messages</span>; messages may be hidden ([[Help:CS1_errors#Controlling_error_message_display|help]]).';	-- $1 is template link
	}


--[[--------------------------< C I T A T I O N _ C L A S S _ M A P >------------------------------------------

this table maps the value assigned to |CitationClass= in the cs1|2 templates to the canonical template name when
the value assigned to |CitationClass= is different from the canonical template name.  |CitationClass= values are
used as class attributes in the <cite> tag that encloses the citation so these names may not contain spaces while
the canonical template name may.  These names are used in warning_msg_e and warning_msg_m to create links to the
template's documentation when an article is displayed in preivew mode.

Most cs1|2 template |CitationClass= values at en.wiki match their canonical template names so are not listed here.

]]

	local citation_class_map_t = {												-- TODO: if kept, these and all other config.CitationClass 'names' require some sort of i18n
		['audio-visual'] = 'AV media',											-- TODO: move to ~/Configuration
		['AV-media-notes'] = 'AV media notes',
		['encyclopaedia'] = 'encyclopedia',
		['mailinglist'] = 'mailing list',
		['pressrelease'] = 'press release'
		}


--[=[-------------------------< E T _ A L _ P A T T E R N S >--------------------------------------------------

This table provides Lua patterns for the phrase "et al" and variants in name text
(author, editor, etc.). The main module uses these to identify and emit the 'etal' message.

]=]

local et_al_patterns = {
	"[;,]? *[\"']*%f[%a][Ee][Tt]%.? *[Aa][Ll][%.;,\"']*$",						-- variations on the 'et al' theme
	"[;,]? *[\"']*%f[%a][Ee][Tt]%.? *[Aa][Ll][Ii][AaIi][Ee]?[%.;,\"']*$",		-- variations on the 'et alia', 'et alii' and 'et aliae' themes (false positive 'et aliie' unlikely to match)
	"[;,]? *%f[%a]and [Oo]thers",												-- an alternative to et al.
	"%[%[ *[Ee][Tt]%.? *[Aa][Ll]%.? *%]%]",										-- a wikilinked form
	"%(%( *[Ee][Tt]%.? *[Aa][Ll]%.? *%)%)",										-- a double-bracketed form (to counter partial removal of ((...)) syntax)
	"[%(%[] *[Ee][Tt]%.? *[Aa][Ll]%.? *[%)%]]",									-- a bracketed form
	}


--[[--------------------------< P R E S E N T A T I O N >------------------------

Fixed presentation markup.  Originally part of citation_config.messages it has
been moved into its own, more semantically correct place.

]]

local presentation = 
	{
	-- .citation-comment class is specified at Help:CS1_errors#Controlling_error_message_display
	['hidden-error'] = '<span class="cs1-hidden-error citation-comment">$1</span>',
	['visible-error'] = '<span class="cs1-visible-error citation-comment">$1</span>',
	['hidden-maint'] = '<span class="cs1-maint citation-comment">$1</span>',
	
	['accessdate'] = '<span class="reference-accessdate">$1$2</span>',			-- to allow editors to hide accessdate using personal CSS

	['bdi'] = '<bdi$1>$2</bdi>',												-- bidirectional isolation used with |script-title= and the like

	['cite'] = '<cite class="$1">$2</cite>';									-- for use when citation does not have a namelist and |ref= not set so no id="..." attribute
	['cite-id'] = '<cite id="$1" class="$2">$3</cite>';							-- for use when when |ref= is set or when citation has a namelist

	['format'] = ' <span class="cs1-format">($1)</span>',						-- for |format=, |chapter-format=, etc.

	-- various access levels, for |access=, |doi-access=, |arxiv=, ...
	-- narrow no-break space &#8239; may work better than nowrap CSS. Or not? Browser support?

	['ext-link-access-signal'] = '<span class="$1" title="$2">$3</span>',		-- external link with appropriate lock icon
		['free'] = {class='cs1-lock-free', title='Freely accessible'},			-- classes defined in Module:Citation/CS1/styles.css
		['registration'] = {class='cs1-lock-registration', title='Free registration required'},
		['limited'] = {class='cs1-lock-limited', title='Free access subject to limited trial, subscription normally required'},
		['subscription'] = {class='cs1-lock-subscription', title='Paid subscription required'},

	['interwiki-icon'] = '<span class="$1" title="$2">$3</span>',
		['class-wikisource'] = 'cs1-ws-icon',

	['italic-title'] = "''$1''",

	['kern-left'] = '<span class="cs1-kern-left"></span>$1',					-- spacing to use when title contains leading single or double quote mark
	['kern-right'] = '$1<span class="cs1-kern-right"></span>',					-- spacing to use when title contains trailing single or double quote mark

	['nowrap1'] = '<span class="nowrap">$1</span>',								-- for nowrapping an item: <span ...>yyyy-mm-dd</span>
	['nowrap2'] = '<span class="nowrap">$1</span> $2',							-- for nowrapping portions of an item: <span ...>dd mmmm</span> yyyy (note white space)

	['ocins'] = '<span title="$1" class="Z3988"></span>',
	
	['parameter'] = '<code class="cs1-code">&#124;$1=</code>',
	
	['ps_cs1'] = '.';															-- CS1 style postscript (terminal) character
	['ps_cs2'] = '';															-- CS2 style postscript (terminal) character (empty string)

	['quoted-text'] = '<q>$1</q>',												-- for wrapping |quote= content
	['quoted-title'] = '"$1"',

	['sep_cs1'] = '.',															-- CS1 element separator
	['sep_cs2'] = ',',															-- CS2 separator
	['sep_nl'] = ';',															-- CS1|2 style name-list separator between names is a semicolon
	['sep_nl_and'] = ' and ',													-- used as last nl sep when |name-list-style=and and list has 2 items
	['sep_nl_end'] = '; and ',													-- used as last nl sep when |name-list-style=and and list has 3+ names
	['sep_name'] = ', ',														-- CS1|2 style last/first separator is <comma><space>
	['sep_nl_vanc'] = ',',														-- Vancouver style name-list separator between authors is a comma
	['sep_name_vanc'] = ' ',													-- Vancouver style last/first separator is a space

	['sep_list'] = ', ',														-- used for |language= when list has 3+ items except for last sep which uses sep_list_end
	['sep_list_pair'] = ' and ',												-- used for |language= when list has 2 items
	['sep_list_end'] = ', and ',												-- used as last list sep for |language= when list has 3+ items
	
	['trans-italic-title'] = "&#91;''$1''&#93;",
	['trans-quoted-title'] = "&#91;$1&#93;",									-- for |trans-title= and |trans-quote=
	['vol-bold'] = '$1 <b>$2</b>',												-- sepc, volume; for bold journal cites; for other cites ['vol'] in messages{}
	}

	
--[[--------------------------< A L I A S E S >---------------------------------

Aliases table for commonly passed parameters.

Parameter names on the right side in the assignments in this table must have been
defined in the Whitelist before they will be recognized as valid parameter names

]]

local aliases = {
	['AccessDate'] = {'access-date', 'accessdate'},								-- Used by InternetArchiveBot
	['Agency'] = 'agency',
	['ArchiveDate'] = {'archive-date', 'archivedate'},							-- Used by InternetArchiveBot
	['ArchiveFormat'] = 'archive-format',
	['ArchiveURL'] = {'archive-url', 'archiveurl'},								-- Used by InternetArchiveBot
	['ASINTLD'] = 'asin-tld',
	['At'] = 'at',																-- Used by InternetArchiveBot
	['Authors'] = {'authors', 'people', 'credits'},
	['BookTitle'] = {'book-title', 'booktitle'},
	['Cartography'] = 'cartography',
	['Chapter'] = {'chapter', 'contribution', 'entry', 'article', 'section'},
	['ChapterFormat'] = {'chapter-format', 'contribution-format', 'entry-format',
		'article-format', 'section-format'};
	['ChapterURL'] = {'chapter-url', 'contribution-url', 'entry-url', 'article-url', 'section-url', 'chapterurl'},	-- Used by InternetArchiveBot
	['ChapterUrlAccess'] = {'chapter-url-access', 'contribution-url-access',
		'entry-url-access', 'article-url-access', 'section-url-access'},		-- Used by InternetArchiveBot
	['Class'] = 'class',														-- cite arxiv and arxiv identifier
	['Collaboration'] = 'collaboration',
	['Conference'] = {'conference', 'event'},
	['ConferenceFormat'] = 'conference-format',
	['ConferenceURL'] = 'conference-url',										-- Used by InternetArchiveBot
	['Date'] = {'date', 'air-date', 'airdate'},									-- air-date and airdate for cite episode and cite serial only
	['Degree'] = 'degree',
	['DF'] = 'df',
	['DisplayAuthors'] = {'display-authors', 'display-subjects'},
	['DisplayContributors'] = 'display-contributors',
	['DisplayEditors'] = 'display-editors',
	['DisplayInterviewers'] = 'display-interviewers',
	['DisplayTranslators'] = 'display-translators',
	['Docket'] = 'docket',
	['DoiBroken'] = 'doi-broken-date',
	['Edition'] = 'edition',
	['Embargo'] = 'pmc-embargo-date',
	['Encyclopedia'] = {'encyclopedia', 'encyclopaedia', 'dictionary'},			-- cite encyclopedia only
	['Episode'] = 'episode',													-- cite serial only TODO: make available to cite episode?
	['Format'] = 'format',
	['ID'] = {'id', 'ID'},
	['Inset'] = 'inset',
	['Issue'] = {'issue', 'number'},
	['Language'] = {'language', 'lang'},
	['LayDate'] = 'lay-date',
	['LayFormat'] = 'lay-format',
	['LaySource'] = 'lay-source',
	['LayURL'] = 'lay-url',
	['MailingList'] = {'mailing-list', 'mailinglist'},							-- cite mailing list only
	['Map'] = 'map',															-- cite map only
	['MapFormat'] = 'map-format',												-- cite map only
	['MapURL'] = {'map-url', 'mapurl'},											-- cite map only -- Used by InternetArchiveBot
	['MapUrlAccess'] = 'map-url-access',										-- cite map only -- Used by InternetArchiveBot
	['Minutes'] = 'minutes',
	['Mode'] = 'mode',
	['NameListStyle'] = 'name-list-style',
	['Network'] = 'network',
	['Newsgroup'] = 'newsgroup',												-- cite newsgroup only
	['NoPP'] = {'no-pp', 'nopp'},
	['NoTracking'] = {'no-tracking', 'template-doc-demo'},
	['Number'] = 'number',														-- this case only for cite techreport
	['OrigDate'] = {'orig-date', 'orig-year', 'origyear'},
	['Others'] = 'others',
	['Page'] = {'page', 'p'},													-- Used by InternetArchiveBot
	['Pages'] = {'pages', 'pp'},												-- Used by InternetArchiveBot
	['Periodical'] = {'journal', 'magazine', 'newspaper', 'periodical', 'website', 'work'},
	['Place'] = {'place', 'location'},
	['PostScript'] = 'postscript',
	['PublicationDate'] = {'publication-date', 'publicationdate'},
	['PublicationPlace'] = {'publication-place', 'publicationplace'},
	['PublisherName'] = {'publisher', 'institution'},
	['Quote'] = {'quote', 'quotation'},
	['QuotePage'] = 'quote-page',
	['QuotePages'] = 'quote-pages',
	['Ref'] = 'ref',
	['Scale'] = 'scale',
	['ScriptChapter'] = {'script-chapter', 'script-contribution', 'script-entry',
		'script-article', 'script-section'},
	['ScriptMap'] = 'script-map',
	['ScriptPeriodical'] = {'script-journal', 'script-magazine', 'script-newspaper',
		'script-periodical', 'script-website', 'script-work'},
	['ScriptQuote'] = 'script-quote',
	['ScriptTitle'] = 'script-title',											-- Used by InternetArchiveBot
	['Season'] = 'season',
	['Sections'] = 'sections',													-- cite map only
	['Series'] = {'series', 'version'},
	['SeriesLink'] = {'series-link', 'serieslink'},
	['SeriesNumber'] = {'series-number', 'series-no'},
	['Sheet'] = 'sheet',														-- cite map only
	['Sheets'] = 'sheets',														-- cite map only
	['Station'] = 'station',
	['Time'] = 'time',
	['TimeCaption'] = 'time-caption',
	['Title'] = 'title',														-- Used by InternetArchiveBot
	['TitleLink'] = {'title-link', 'episode-link', 'episodelink'},				-- Used by InternetArchiveBot
	['TitleNote'] = 'department',
	['TitleType'] = {'type', 'medium'},
	['TransChapter'] = {'trans-article', 'trans-chapter', 'trans-contribution',
		'trans-entry', 'trans-section'},
	['Transcript'] = 'transcript',
	['TranscriptFormat'] = 'transcript-format',	
	['TranscriptURL'] = {'transcript-url', 'transcripturl'},					-- Used by InternetArchiveBot
	['TransMap'] = 'trans-map',													-- cite map only
	['TransPeriodical'] = {'trans-journal', 'trans-magazine', 'trans-newspaper',
		'trans-periodical', 'trans-website', 'trans-work'},
	['TransQuote'] = 'trans-quote',
	['TransTitle'] = 'trans-title',												-- Used by InternetArchiveBot
	['URL'] = {'url', 'URL'},													-- Used by InternetArchiveBot
	['UrlAccess'] = 'url-access',												-- Used by InternetArchiveBot
	['UrlStatus'] = 'url-status',												-- Used by InternetArchiveBot
	['Vauthors'] = 'vauthors',
	['Veditors'] = 'veditors',
	['Via'] = 'via',
	['Volume'] = 'volume',
	['Year'] = 'year',

	['AuthorList-First'] = {"first#", "author-first#", "author#-first", "given#",
		"author-given#", "author#-given"},
	['AuthorList-Last'] = {"last#", "author-last#", "author#-last", "surname#",
		"author-surname#", "author#-surname", "author#", "subject#", 'host#'},
	['AuthorList-Link'] = {"author-link#", "author#-link", "subject-link#",
		"subject#-link", "authorlink#", "author#link"},
	['AuthorList-Mask'] = {"author-mask#", "author#-mask", "subject-mask#", "subject#-mask"},

	['ContributorList-First'] = {'contributor-first#', 'contributor#-first',
		'contributor-given#', 'contributor#-given'},
	['ContributorList-Last'] = {'contributor-last#', 'contributor#-last',
		'contributor-surname#', 'contributor#-surname', 'contributor#'},
	['ContributorList-Link'] = {'contributor-link#', 'contributor#-link'},
	['ContributorList-Mask'] = {'contributor-mask#', 'contributor#-mask'},

	['EditorList-First'] = {"editor-first#", "editor#-first", "editor-given#", "editor#-given"},
	['EditorList-Last'] = {"editor-last#", "editor#-last", "editor-surname#",
		"editor#-surname", "editor#"},
	['EditorList-Link'] = {"editor-link#", "editor#-link"},
	['EditorList-Mask'] = {"editor-mask#", "editor#-mask"},
	
	['InterviewerList-First'] = {'interviewer-first#', 'interviewer#-first',
		'interviewer-given#', 'interviewer#-given'},
	['InterviewerList-Last'] = {'interviewer-last#', 'interviewer#-last',
		'interviewer-surname#', 'interviewer#-surname', 'interviewer#'},
	['InterviewerList-Link'] = {'interviewer-link#', 'interviewer#-link'},
	['InterviewerList-Mask'] = {'interviewer-mask#', 'interviewer#-mask'},

	['TranslatorList-First'] = {'translator-first#', 'translator#-first',
		'translator-given#', 'translator#-given'},
	['TranslatorList-Last'] = {'translator-last#', 'translator#-last',
		'translator-surname#', 'translator#-surname', 'translator#'},
	['TranslatorList-Link'] = {'translator-link#', 'translator#-link'},
	['TranslatorList-Mask'] = {'translator-mask#', 'translator#-mask'},
	}


--[[--------------------------< P U N C T _ S K I P >---------------------------

builds a table of parameter names that the extraneous terminal punctuation check should not check.

]]

local punct_meta_params = {														-- table of aliases[] keys (meta parameters); each key has a table of parameter names for a value
	'BookTitle', 'Chapter', 'ScriptChapter', 'ScriptTitle', 'Title', 'TransChapter', 'Transcript', 'TransMap',	'TransTitle',	-- title-holding parameters
	'AuthorList-Mask', 'ContributorList-Mask', 'EditorList-Mask', 'InterviewerList-Mask', 'TranslatorList-Mask',	-- name-list mask may have name separators
	'PostScript', 'Quote', 'ScriptQuote', 'TransQuote', 'Ref',											-- miscellaneous
	'ArchiveURL', 'ChapterURL', 'ConferenceURL', 'LayURL', 'MapURL', 'TranscriptURL', 'URL',			-- URL-holding parameters
	}

local url_meta_params = {														-- table of aliases[] keys (meta parameters); each key has a table of parameter names for a value
	'ArchiveURL', 'ChapterURL', 'ConferenceURL', 'ID', 'LayURL', 'MapURL', 'TranscriptURL', 'URL',		-- parameters allowed to hold urls
	'Page', 'Pages', 'At', 'QuotePage', 'QuotePages',							-- insource locators allowed to hold urls
	}

local function build_skip_table (skip_t, meta_params)
	for _, meta_param in ipairs (meta_params) do								-- for each meta parameter key
		local params = aliases[meta_param];										-- get the parameter or the table of parameters associated with the meta parameter name
		if 'string' == type (params) then
			skip_t[params] = 1;													-- just a single parameter
		else
			for _, param in ipairs (params) do									-- get the parameter name
				skip_t[param] = 1;												-- add the parameter name to the skip table
				local count;
				param, count = param:gsub ('#', '');							-- remove enumerator marker from enumerated parameters
				if 0 ~= count then												-- if removed
					skip_t[param] = 1;											-- add param name without enumerator marker
				end
			end
		end
	end
	return skip_t;
end

local punct_skip = {};
local url_skip = {};


--[[-----------< S P E C I A L   C A S E   T R A N S L A T I O N S >------------

This table is primarily here to support internationalization.  Translations in
this table are used, for example, when an error message, category name, etc.,
is extracted from the English alias key.  There may be other cases where
this translation table may be useful.

]]
local is_Latn = 'A-Za-z\195\128-\195\150\195\152-\195\182\195\184-\198\191\199\132-\201\143';
local special_case_translation = {
	['AuthorList'] = '作者名單',											-- used to assemble maintenance category names
	['ContributorList'] = '貢獻者名單',									-- translation of these names plus translation of the base mainenance category names in maint_cats{} table below
	['EditorList'] = '編者名單',											-- must match the names of the actual categories
	['InterviewerList'] = '採訪者名單',									-- this group or translations used by name_has_ed_markup() and name_has_mult_names()
	['TranslatorList'] = '翻譯者名單',
	
																				-- Lua patterns to match pseudo-titles used by InternetArchiveBot and others as placeholder for unknown |title= value
	['archived_copy'] = {														-- used with CS1 maint: Archive[d] copy as title
		['en'] = '^archived?%s+copy$',											-- for English; translators: keep this because templates imported from en.wiki
		['local'] = nil,														-- translators: replace ['local'] = nil with lowercase translation only when bots or tools create generic titles in your language
		},

																				-- Lua patterns to match generic titles; usually created by bots or reference filling tools
																				-- translators: replace ['local'] = nil with lowercase translation only when bots or tools create generic titles in your language
		-- generic titles and patterns in this table should be lowercase only
		-- leave ['local'] nil except when there is a matching generic title in your language
		-- boolean 'true' for plain-text searches; 'false' for pattern searches

	['generic_titles'] = {
		['accept'] = {
			},
		['reject'] = {
			{['en'] = {'^wayback%s+machine$', false},				['local'] = nil},
			{['en'] = {'are you a robot', true},					['local'] = nil},
			{['en'] = {'hugedomains.com', true},					['local'] = nil},
			{['en'] = {'^[%(%[{<]?no +title[>}%]%)]?$', false},		['local'] = nil},
			{['en'] = {'page not found', true},						['local'] = nil},
			{['en'] = {'subscribe to read', true},					['local'] = nil},
			{['en'] = {'^[%(%[{<]?unknown[>}%]%)]?$', false},		['local'] = nil},
			{['en'] = {'website is for sale', true},				['local'] = nil},
			{['en'] = {'^404', false},								['local'] = nil},
			{['en'] = {'internet archive wayback machine', true},	['local'] = nil},
			{['en'] = {'log into facebook', true},					['local'] = nil},
			{['en'] = {'login • instagram', true},					['local'] = nil},
			{['en'] = {'redirecting...', true},						['local'] = nil},
			{['en'] = {'usurped title', true},						['local'] = nil},	-- added by a GreenC bot
			{['en'] = {'webcite query result', true},				['local'] = nil},
			{['en'] = {'wikiwix\'s cache', true},					['local'] = nil},
			}
		},

		-- boolean 'true' for plain-text searches, search string must be lowercase only
		-- boolean 'false' for pattern searches
		-- leave ['local'] nil except when there is a matching generic name in your language

	['generic_names'] = {
		['accept'] = {
			{['en'] = {'%[%[[^|]*%(author%) *|[^%]]*%]%]', false},				['local'] = nil},
			},
		['reject'] = {
			{['en'] = {'about us', true},										['local'] = nil},
			{['en'] = {'%f[%a][Aa]dvisor%f[%A]', false},						['local'] = nil},
			{['en'] = {'%f[%a][Aa]uthor%f[%A]', false},							['local'] = nil},
			{['en'] = {'collaborator', true},									['local'] = nil},
			{['en'] = {'contributor', true},									['local'] = nil},
			{['en'] = {'contact us', true},										['local'] = nil},
			{['en'] = {'directory', true},										['local'] = nil},
			{['en'] = {'%f[%(%[][%(%[]%s*eds?%.?%s*[%)%]]?$', false},			['local'] = nil},
			{['en'] = {'[,%.%s]%f[e]eds?%.?$', false},							['local'] = nil},
			{['en'] = {'^eds?[%.,;]', false},									['local'] = nil},
			{['en'] = {'^[%(%[]%s*[Ee][Dd][Ss]?%.?%s*[%)%]]', false},			['local'] = nil},
			{['en'] = {'%f[%a][Ee]dited%f[%A]', false},							['local'] = nil},
			{['en'] = {'%f[%a][Ee]ditors?%f[%A]', false},						['local'] = nil},
			{['en'] = {'%f[%a]]Ee]mail%f[%A]', false},							['local'] = nil},
			{['en'] = {'facebook', true},										['local'] = nil},
			{['en'] = {'google', true},											['local'] = nil},
			{['en'] = {'home page', true},										['local'] = nil},
			{['en'] = {'instagram', true},										['local'] = nil},
			{['en'] = {'interviewer', true},									['local'] = nil},
			{['en'] = {'linkedIn', true},										['local'] = nil},
			{['en'] = {'^[Nn]ews$', false},										['local'] = nil},
			{['en'] = {'pinterest', true},										['local'] = nil},
			{['en'] = {'policy', true},											['local'] = nil},
			{['en'] = {'privacy', true},										['local'] = nil},
			{['en'] = {'translator', true},										['local'] = nil},
			{['en'] = {'tumblr', true},											['local'] = nil},
			{['en'] = {'twitter', true},										['local'] = nil},
			{['en'] = {'site name', true},										['local'] = nil},
			{['en'] = {'statement', true},										['local'] = nil},
			{['en'] = {'submitted', true},										['local'] = nil},
			{['en'] = {'super.?user', false},									['local'] = nil},
			{['en'] = {'%f['..is_Latn..'][Uu]ser%f[^'..is_Latn..']', false},	['local'] = nil},
			{['en'] = {'verfasser', true},										['local'] = nil},
			}
	}
	}


--[[--------------------------< D A T E _ N A M E S >----------------------------------------------------------

This table of tables lists local language date names and fallback English date names.
The code in Date_validation will look first in the local table for valid date names.
If date names are not found in the local table, the code will look in the English table.

Because citations can be copied to the local wiki from en.wiki, the English is
required when the date-name translation function date_name_xlate() is used.

In these tables, season numbering is defined by
Extended Date/Time Format (EDTF) Specification (https://www.loc.gov/standards/datetime/)
which became part of ISO 8601 in 2019.  See '§Sub-year groupings'. The standard
defines various divisions using numbers 21-41. CS1|2 only supports generic seasons.
EDTF does support the distinction between north and south hemisphere seasons
but CS1|2 has no way to make that distinction.

33-36 = Quarter 1, Quarter 2, Quarter 3, Quarter 4 (3 months each)

The standard does not address 'named' dates so, for the purposes of CS1|2,
Easter and Christmas are defined here as 98 and 99, which should be out of the
ISO 8601 (EDTF) range of uses for a while.

local_date_names_from_mediawiki is a boolean.  When set to:
	true – module will fetch local month names from MediaWiki for both date_names['local']['long'] and date_names['local']['short']
	false – module will *not* fetch local month names from MediaWiki

Caveat lector:  There is no guarantee that MediaWiki will provide short month names.  At your wiki you can test
the results of the MediaWiki fetch in the debug console with this command (the result is alpha sorted):
	=mw.dumpObject (p.date_names['local'])

While the module can fetch month names from MediaWiki, it cannot fetch the quarter, season, and named date names
from MediaWiki.  Those must be translated manually.

]]

local local_date_names_from_mediawiki = true;									-- when false, manual translation required for date_names['local']['long'] and date_names['local']['short']
																				-- when true, module fetches long and short month names from MediaWiki
local date_names = {
	['en'] = {																	-- English
		['long']	= {['January'] = 1, ['February'] = 2, ['March'] = 3, ['April'] = 4, ['May'] = 5, ['June'] = 6, ['July'] = 7, ['August'] = 8, ['September'] = 9, ['October'] = 10, ['November'] = 11, ['December'] = 12},
		['short']	= {['Jan'] = 1, ['Feb'] = 2, ['Mar'] = 3, ['Apr'] = 4, ['May'] = 5, ['Jun'] = 6, ['Jul'] = 7, ['Aug'] = 8, ['Sep'] = 9, ['Oct'] = 10, ['Nov'] = 11, ['Dec'] = 12},
		['quarter'] = {['First Quarter'] = 33, ['Second Quarter'] = 34, ['Third Quarter'] = 35, ['Fourth Quarter'] = 36},
		['season']	= {['Winter'] = 24, ['Spring'] = 21, ['Summer'] = 22, ['Fall'] = 23, ['Autumn'] = 23},
		['named']	= {['Easter'] = 98, ['Christmas'] = 99},
		},
																				-- when local_date_names_from_mediawiki = false
	['local'] = {																-- replace these English date names with the local language equivalents
		['long']	= {['January'] = 1, ['February'] = 2, ['March'] = 3, ['April'] = 4, ['May'] = 5, ['June'] = 6, ['July'] = 7, ['August'] = 8, ['September'] = 9, ['October'] = 10, ['November'] = 11, ['December'] = 12},
		['short']	= {['Jan'] = 1, ['Feb'] = 2, ['Mar'] = 3, ['Apr'] = 4, ['May'] = 5, ['Jun'] = 6, ['Jul'] = 7, ['Aug'] = 8, ['Sep'] = 9, ['Oct'] = 10, ['Nov'] = 11, ['Dec'] = 12},
		['quarter'] = {['First Quarter'] = 33, ['Second Quarter'] = 34, ['Third Quarter'] = 35, ['Fourth Quarter'] = 36},
		['season']	= {['冬'] = 24, ['春'] = 21, ['夏'] = 22, ['秋'] = 23},
		['named']	= {['Easter'] = 98, ['Christmas'] = 99},
		},
	['inv_local_long'] = {},													-- used in date reformatting & translation; copy of date_names['local'].long where k/v are inverted: [1]='<local name>' etc.
	['inv_local_short'] = {},													-- used in date reformatting & translation; copy of date_names['local'].short where k/v are inverted: [1]='<local name>' etc.
	['inv_local_quarter'] = {},													-- used in date translation; copy of date_names['local'].quarter where k/v are inverted: [1]='<local name>' etc.
	['inv_local_season'] = {},													-- used in date translation; copy of date_names['local'].season where k/v are inverted: [1]='<local name>' etc.
	['inv_local_named'] = {},													-- used in date translation; copy of date_names['local'].named where k/v are inverted: [1]='<local name>' etc.
	['local_digits'] = {['0'] = '0', ['1'] = '1', ['2'] = '2', ['3'] = '3', ['4'] = '4', ['5'] = '5', ['6'] = '6', ['7'] = '7', ['8'] = '8', ['9'] = '9'},	-- used to convert local language digits to Western 0-9
	['xlate_digits'] = {},
	}

if local_date_names_from_mediawiki then											-- if fetching local month names from MediaWiki is enabled
	local long_t = {};
	local short_t = {};
	for i=1, 12 do																-- loop 12x and 
		local name = lang_obj:formatDate('F', '2022-' .. i .. '-1');			-- get long month name for each i
		long_t[name] = i;														-- save it
		name = lang_obj:formatDate('M', '2022-' .. i .. '-1');					-- get short month name for each i
		short_t[name] = i;														-- save it
	end
	date_names['local']['long'] = long_t;										-- write the long table – overwrites manual translation
	date_names['local']['short'] = short_t;										-- write the short table – overwrites manual translation
end
																				-- create inverted date-name tables for reformatting and/or translation
for _, invert_t in pairs {{'long', 'inv_local_long'}, {'short', 'inv_local_short'}, {'quarter', 'inv_local_quarter'}, {'season', 'inv_local_season'}, {'named', 'inv_local_named'}} do
	for name, i in pairs (date_names['local'][invert_t[1]]) do					-- this table is ['name'] = i
		date_names[invert_t[2]][i] = name;										-- invert to get [i] = 'name' for conversions from ymd
	end
end

for ld, ed in pairs (date_names.local_digits) do								-- make a digit translation table for simple date translation from en to local language using local_digits table
	date_names.xlate_digits [ed] = ld;											-- en digit becomes index with local digit as the value
end

local df_template_patterns = {													-- table of redirects to {{Use dmy dates}} and {{Use mdy dates}}
	'{{ *[Uu]se +(dmy) +dates *[|}]',	-- 1159k								-- sorted by approximate transclusion count
	'{{ *[Uu]se +(mdy) +dates *[|}]',	-- 212k
	'{{ *[Uu]se +(MDY) +dates *[|}]',	-- 788
	'{{ *[Uu]se +(DMY) +dates *[|}]',	-- 343
	'{{ *([Mm]dy) *[|}]',				-- 176
	'{{ *[Uu]se *(dmy) *[|}]',			-- 156 + 18
	'{{ *[Uu]se *(mdy) *[|}]',			-- 149 + 11
	'{{ *([Dd]my) *[|}]',				-- 56
	'{{ *[Uu]se +(MDY) *[|}]',			-- 5
	'{{ *([Dd]MY) *[|}]',				-- 3
	'{{ *[Uu]se(mdy)dates *[|}]',		-- 1
	'{{ *[Uu]se +(DMY) *[|}]',			-- 0
	'{{ *([Mm]DY) *[|}]',				-- 0
	}

local function get_date_format ()
	local title_object = mw.title.getCurrentTitle();
	if title_object.namespace == 10 then										-- not in template space so that unused templates appear in unused-template-reports; 
		return nil;																-- auto-formatting does not work in Template space so don't set global_df
	end
	local content = title_object:getContent() or '';							-- get the content of the article or ''; new pages edited w/ve do not have 'content' until saved; ve does not preview; phab:T221625
	for _, pattern in ipairs (df_template_patterns) do							-- loop through the patterns looking for {{Use dmy dates}} or {{Use mdy dates}} or any of their redirects
		local start, _, match = content:find(pattern);							-- match is the three letters indicating desired date format
		if match then
			content = content:match ('%b{}', start);							-- get the whole template
			if content:match ('| *cs1%-dates *= *[lsy][sy]?') then				-- look for |cs1-dates=publication date length access-/archive-date length
				return match:lower() .. '-' .. content:match ('| *cs1%-dates *= *([lsy][sy]?)');
			else
				return match:lower() .. '-all';									-- no |cs1-dates= k/v pair; return value appropriate for use in |df=
			end
		end
	end
end

local global_df;


--[[-----------------< V O L U M E ,  I S S U E ,  P A G E S >------------------

These tables hold cite class values (from the template invocation) and identify those templates that support
|volume=, |issue=, and |page(s)= parameters.  Cite conference and cite map require further qualification which
is handled in the main module.

]]

local templates_using_volume = {'citation', 'audio-visual', 'book', 'conference', 'encyclopaedia', 'interview', 'journal', 'magazine', 'map', 'news', 'report', 'techreport', 'thesis'}
local templates_using_issue = {'citation', 'conference', 'episode', 'interview', 'journal', 'magazine', 'map', 'news', 'podcast'}
local templates_not_using_page = {'audio-visual', 'episode', 'mailinglist', 'newsgroup', 'podcast', 'serial', 'sign', 'speech'}

--[[

These tables control when it is appropriate for {{citation}} to render |volume= and/or |issue=.  The parameter
names in the tables constrain {{citation}} so that its renderings match the renderings of the equivalent cs1
templates.  For example, {{cite web}} does not support |volume= so the equivalent {{citation |website=...}} must
not support |volume=.

]]

local citation_no_volume_t = {													-- {{citation}} does not render |volume= when these parameters are used
	'website', 'mailinglist', 'script-website',
	}
local citation_issue_t = {														-- {{citation}} may render |issue= when these parameters are used
	'journal', 'magazine', 'newspaper', 'periodical', 'work',
	'script-journal', 'script-magazine', 'script-newspaper', 'script-periodical', 'script-work',
	}

--[[

Patterns for finding extra text in |volume=, |issue=, |page=, |pages=

]]

local vol_iss_pg_patterns = {
	good_ppattern = '^P[^%.PpGg]',												-- OK to begin with uppercase P: P7 (page 7 of section P), but not p123 (page 123); TODO: this allows 'Pages' which it should not
	bad_ppatterns = {															-- patterns for |page= and |pages=
		'^[Pp][PpGg]?%.?[ %d]',
		'^[Pp][Pp]?%.&nbsp;',													-- from {{p.}} and {{pp.}} templates
		'^[Pp]ages?',
		'^[Pp]gs.?',
		},
	vpatterns = {																-- patterns for |volume=
		'^volumes?',
		'^vols?[%.:=]?'
		},
	ipatterns = {																-- patterns for |issue=
		'^issues?',
		'^iss[%.:=]?',
		'^numbers?',
		'^nos?%A',																-- don't match 'november' or 'nostradamus'
		'^nr[%.:=]?',
		'^n[%.:= ]'																-- might be a valid issue without separator (space char is sep char here)
		}
	}

--[[--------------------------< K E Y W O R D S >-------------------------------

These tables hold keywords for those parameters that have defined sets of acceptable keywords.

]]

--[[-------------------< K E Y W O R D S   T A B L E >--------------------------

this is a list of keywords; each key in the list is associated with a table of
synonymous keywords possibly from different languages.

for I18N: add local-language keywords to value table; do not change the key.
For example, adding the German keyword 'ja':
	['affirmative'] = {'yes', 'true', 'y', 'ja'},

Because CS1|2 templates from en.wiki articles are often copied to other local wikis,
it is recommended that the English keywords remain in these tables.

]]

local keywords = {
	['amp'] = {'&', 'amp', 'ampersand'}, 										-- |name-list-style=
	['and'] = {'and', 'serial'},												-- |name-list-style=
	['affirmative'] = {'yes', 'true', 'y'},										-- |no-tracking=, |no-pp= -- Used by InternetArchiveBot
	['afterword'] = {'afterword'},												-- |contribution=
	['bot: unknown'] = {'bot: unknown'},										-- |url-status= -- Used by InternetArchiveBot
	['cs1'] = {'cs1'},															-- |mode=
	['cs2'] = {'cs2'},															-- |mode=
	['dead'] = {'dead', 'deviated'},											-- |url-status= -- Used by InternetArchiveBot
	['dmy'] = {'dmy'},															-- |df=
	['dmy-all'] = {'dmy-all'},													-- |df=
	['foreword'] = {'foreword'},												-- |contribution=
	['free'] = {'free'},														-- |<id>-access= -- Used by InternetArchiveBot
	['harv'] = {'harv'},														-- |ref=; this no longer supported; is_valid_parameter_value() called with <invert> = true
	['introduction'] = {'introduction'},										-- |contribution=
	['limited'] = {'limited'},													-- |url-access= -- Used by InternetArchiveBot
	['live'] = {'live'},														-- |url-status= -- Used by InternetArchiveBot
	['mdy'] = {'mdy'},															-- |df=
	['mdy-all'] = {'mdy-all'},													-- |df=
	['none'] = {'none'},														-- |postscript=, |ref=, |title=, |type= -- Used by InternetArchiveBot
	['off'] = {'off'},															-- |title= (potentially also: |title-link=, |postscript=, |ref=, |type=)
	['preface'] = {'preface'},													-- |contribution=
	['registration'] = {'registration'},										-- |url-access= -- Used by InternetArchiveBot
	['subscription'] = {'subscription'},										-- |url-access= -- Used by InternetArchiveBot
	['unfit'] = {'unfit'},														-- |url-status= -- Used by InternetArchiveBot
	['usurped'] = {'usurped'},													-- |url-status= -- Used by InternetArchiveBot
	['vanc'] = {'vanc'},														-- |name-list-style=
	['ymd'] = {'ymd'},															-- |df=
	['ymd-all'] = {'ymd-all'},													-- |df=
	--	['yMd'] = {'yMd'},														-- |df=; not supported at en.wiki
	--	['yMd-all'] = {'yMd-all'},												-- |df=; not supported at en.wiki
	}


--[[------------------------< X L A T E _ K E Y W O R D S >---------------------

this function builds a list, keywords_xlate{}, of the keywords found in keywords{} where the values from keywords{}
become the keys in keywords_xlate{} and the keys from keywords{} become the values in keywords_xlate{}:
	['affirmative'] = {'yes', 'true', 'y'},		-- in keywords{}
becomes
	['yes'] = 'affirmative',					-- in keywords_xlate{}
	['true'] = 'affirmative',
	['y'] = 'affirmative',

the purpose of this function is to act as a translator between a non-English keyword and its English equivalent
that may be used in other modules of this suite

]]

local function xlate_keywords ()
	local out_table = {};														-- output goes here
	for k, keywords_t in pairs (keywords) do									-- spin through the keywords table
		for _, keyword in ipairs (keywords_t) do								-- for each keyword
			out_table[keyword] = k;												-- create an entry in the output table where keyword is the key
		end
	end
	
	return out_table;
end

local keywords_xlate = xlate_keywords ();										-- the list of translated keywords


--[[----------------< M A K E _ K E Y W O R D S _ L I S T >---------------------

this function assembles, for parameter-value validation, the list of keywords appropriate to that parameter.

keywords_lists{}, is a table of tables from keywords{}

]]

local function make_keywords_list (keywords_lists)
	local out_table = {};														-- output goes here
	
	for _, keyword_list in ipairs (keywords_lists) do							-- spin through keywords_lists{} and get a table of keywords
		for _, keyword in ipairs (keyword_list) do								-- spin through keyword_list{} and add each keyword, ...
			table.insert (out_table, keyword);									-- ... as plain text, to the output list
		end
	end
	return out_table;
end


--[[----------------< K E Y W O R D S _ L I S T S >-----------------------------

this is a list of lists of valid keywords for the various parameters in [key].
Generally the keys in this table are the canonical en.wiki parameter names though
some are contrived because of use in multiple differently named parameters:
['yes_true_y'], ['id-access'].

The function make_keywords_list() extracts the individual keywords from the
appropriate list in keywords{}.

The lists in this table are used to validate the keyword assignment for the
parameters named in this table's keys.

]]

local keywords_lists = {
	['yes_true_y'] = make_keywords_list ({keywords.affirmative}),
	['contribution'] = make_keywords_list ({keywords.afterword, keywords.foreword, keywords.introduction, keywords.preface}),
	['df'] = make_keywords_list ({keywords.dmy, keywords['dmy-all'], keywords.mdy, keywords['mdy-all'], keywords.ymd, keywords['ymd-all']}),
	--	['df'] = make_keywords_list ({keywords.dmy, keywords['dmy-all'], keywords.mdy, keywords['mdy-all'], keywords.ymd, keywords['ymd-all'], keywords.yMd, keywords['yMd-all']}),	-- not supported at en.wiki
	['mode'] = make_keywords_list ({keywords.cs1, keywords.cs2}),
	['name-list-style'] = make_keywords_list ({keywords.amp, keywords['and'], keywords.vanc}),
	['ref'] = make_keywords_list ({keywords.harv}),								-- inverted check; |ref=harv no longer supported
	['url-access'] = make_keywords_list ({keywords.subscription, keywords.limited, keywords.registration}),
	['url-status'] = make_keywords_list ({keywords.dead, keywords.live, keywords.unfit, keywords.usurped, keywords['bot: unknown']}),
	['id-access'] = make_keywords_list ({keywords.free}),
	}


--[[---------------------< S T R I P M A R K E R S >----------------------------

Common pattern definition location for stripmarkers so that we don't have to go
hunting for them if (when) MediaWiki changes their form.

]]

local stripmarkers = {
	['any'] = '\127[^\127]*UNIQ%-%-(%a+)%-[%a%d]+%-QINU[^\127]*\127',			-- capture returns name of stripmarker
	['math'] = '\127[^\127]*UNIQ%-%-math%-[%a%d]+%-QINU[^\127]*\127'			-- math stripmarkers used in coins_cleanup() and coins_replace_math_stripmarker()
	}


--[[------------< I N V I S I B L E _ C H A R A C T E R S >---------------------

This table holds non-printing or invisible characters indexed either by name or
by Unicode group. Values are decimal representations of UTF-8 codes.  The table
is organized as a table of tables because the Lua pairs keyword returns table
data in an arbitrary order.  Here, we want to process the table from top to bottom
because the entries at the top of the table are also found in the ranges specified
by the entries at the bottom of the table.

Also here is a pattern that recognizes stripmarkers that begin and end with the
delete characters.  The nowiki stripmarker is not an error but some others are
because the parameter values that include them become part of the template's
metadata before stripmarker replacement.

]]

local invisible_defs = {
	del = '\127',																-- used to distinguish between stripmarker and del char
	zwj = '\226\128\141',														-- used with capture because zwj may be allowed
	}

local invisible_chars = {
	{'replacement', '\239\191\189'},											-- U+FFFD, EF BF BD
	{'zero width joiner', '('.. invisible_defs.zwj .. ')'},						-- U+200D, E2 80 8D; capture because zwj may be allowed
	{'zero width space', '\226\128\139'},										-- U+200B, E2 80 8B
	{'hair space', '\226\128\138'},												-- U+200A, E2 80 8A
	{'soft hyphen', '\194\173'},												-- U+00AD, C2 AD
	{'horizontal tab', '\009'},													-- U+0009 (HT), 09
	{'line feed', '\010'},														-- U+000A (LF), 0A
	{'no-break space', '\194\160'},												-- U+00A0 (NBSP), C2 A0
	{'carriage return', '\013'},												-- U+000D (CR), 0D
	{'stripmarker', stripmarkers.any},											-- stripmarker; may or may not be an error; capture returns the stripmaker type
	{'delete', '('.. invisible_defs.del .. ')'},								-- U+007F (DEL), 7F; must be done after stripmarker test; capture to distinguish isolated del chars not part of stripmarker
	{'C0 control', '[\000-\008\011\012\014-\031]'},								-- U+0000–U+001F (NULL–US), 00–1F (except HT, LF, CR (09, 0A, 0D))
	{'C1 control', '[\194\128-\194\159]'},										-- U+0080–U+009F (XXX–APC), C2 80 – C2 9F
	--	{'Specials', '[\239\191\185-\239\191\191]'},								-- U+FFF9-U+FFFF, EF BF B9 – EF BF BF
	--	{'Private use area', '[\238\128\128-\239\163\191]'},						-- U+E000–U+F8FF, EE 80 80 – EF A3 BF
	--	{'Supplementary Private Use Area-A', '[\243\176\128\128-\243\191\191\189]'},	-- U+F0000–U+FFFFD, F3 B0 80 80 – F3 BF BF BD
	--	{'Supplementary Private Use Area-B', '[\244\128\128\128-\244\143\191\189]'},	-- U+100000–U+10FFFD, F4 80 80 80 – F4 8F BF BD
	}

--[[

Indic script makes use of zero width joiner as a character modifier so zwj
characters must be left in.  This pattern covers all of the unicode characters
for these languages:
	Devanagari					0900–097F – https://unicode.org/charts/PDF/U0900.pdf
		Devanagari extended		A8E0–A8FF – https://unicode.org/charts/PDF/UA8E0.pdf
	Bengali						0980–09FF – https://unicode.org/charts/PDF/U0980.pdf
	Gurmukhi					0A00–0A7F – https://unicode.org/charts/PDF/U0A00.pdf
	Gujarati					0A80–0AFF – https://unicode.org/charts/PDF/U0A80.pdf
	Oriya						0B00–0B7F – https://unicode.org/charts/PDF/U0B00.pdf
	Tamil						0B80–0BFF – https://unicode.org/charts/PDF/U0B80.pdf
	Telugu						0C00–0C7F – https://unicode.org/charts/PDF/U0C00.pdf
	Kannada						0C80–0CFF – https://unicode.org/charts/PDF/U0C80.pdf
	Malayalam					0D00–0D7F – https://unicode.org/charts/PDF/U0D00.pdf
plus the not-necessarily Indic scripts for Sinhala and Burmese:
	Sinhala						0D80-0DFF - https://unicode.org/charts/PDF/U0D80.pdf
	Myanmar						1000-109F - https://unicode.org/charts/PDF/U1000.pdf
		Myanmar extended A		AA60-AA7F - https://unicode.org/charts/PDF/UAA60.pdf
		Myanmar extended B		A9E0-A9FF - https://unicode.org/charts/PDF/UA9E0.pdf
the pattern is used by has_invisible_chars() and coins_cleanup()

]]

local indic_script = '[\224\164\128-\224\181\191\224\163\160-\224\183\191\225\128\128-\225\130\159\234\167\160-\234\167\191\234\169\160-\234\169\191]';

-- list of emoji that use zwj character (U+200D) to combine with another emoji
local emoji = {																	-- indexes are decimal forms of the hex values in U+xxxx
	[127752] = true,															-- U+1F308 🌈 rainbow
	[127806] = true,															-- U+1F33E 🌾 ear of rice
	[127859] = true,															-- U+1F373 🍳 cooking
	[127891] = true,															-- U+1F393 🎓 graduation cap
	[127908] = true,															-- U+1F3A4 🎤 microphone
	[127912] = true,															-- U+1F3A8 🎨 artist palette
	[127979] = true,															-- U+1F3EB 🏫 school
	[127981] = true,															-- U+1F3ED 🏭 factory
	[128102] = true,															-- U+1F466 👦 boy
	[128103] = true,															-- U+1F467 👧 girl
	[128104] = true,															-- U+1F468 👨 man
	[128105] = true,															-- U+1F469 👩 woman
	[128139] = true,															-- U+1F48B 💋 kiss mark
	[128187] = true,															-- U+1F4BB 💻 personal computer
	[128188] = true,															-- U+1F4BC 💼 brief case
	[128295] = true,															-- U+1F527 🔧 wrench
	[128300] = true,															-- U+1F52C 🔬 microscope
	[128488] = true,															-- U+1F5E8 🗨 left speech bubble
	[128640] = true,															-- U+1F680 🚀 rocket
	[128658] = true,															-- U+1F692 🚒 fire engine
	[129309] = true,															-- U+1F91D 🤝 handshake
	[129455] = true,															-- U+1F9AF 🦯 probing cane
	[129456] = true,															-- U+1F9B0 🦰 emoji component red hair
	[129457] = true,															-- U+1F9B1 🦱 emoji component curly hair
	[129458] = true,															-- U+1F9B2 🦲 emoji component bald
	[129459] = true,															-- U+1F9B3 🦳 emoji component white hair
	[129466] = true,															-- U+1F9BA 🦺 safety vest
	[129468] = true,															-- U+1F9BC 🦼 motorized wheelchair
	[129469] = true,															-- U+1F9BD 🦽 manual wheelchair
	[129489] = true,															-- U+1F9D1 🧑 adult
	[9760] = true,																-- U+2620 ☠ skull and crossbones
	[9792] = true,																-- U+2640 ♀ female sign
	[9794] = true,																-- U+2642 ♂ male sign
	[9877] = true,																-- U+2695 ⚕ staff of aesculapius
	[9878] = true,																-- U+2696 ⚖ scales
	[9992] = true,																-- U+2708 ✈ airplane
	[10084] = true,																-- U+2764 ❤ heavy black heart
	}


--[[----------------------< L A N G U A G E   S U P P O R T >-------------------

These tables and constants support various language-specific functionality.

]]

--local this_wiki_code = mw.getContentLanguage():getCode();						-- get this wiki's language code
local this_wiki_code = lang_obj:getCode();										-- get this wiki's language code
if string.match (mw.site.server, 'wikidata') then
		this_wiki_code = mw.getCurrentFrame():preprocess('{{int:lang}}');		-- on Wikidata so use interface language setting instead
	end

local mw_languages_by_tag_t = mw.language.fetchLanguageNames (this_wiki_code, 'all');	-- get a table of language tag/name pairs known to Wikimedia; used for interwiki tests
local mw_languages_by_name_t = {};
	for k, v in pairs (mw_languages_by_tag_t) do								-- build a 'reversed' table name/tag language pairs know to MediaWiki; used for |language=
		v = mw.ustring.lower (v);												-- lowercase for tag fetch; get name's proper case from mw_languages_by_tag_t[<tag>]
		if mw_languages_by_name_t[v] then										-- when name already in the table
			if 2 == #k or 3 == #k then											-- if tag does not have subtags
				mw_languages_by_name_t[v] = k;									-- prefer the shortest tag for this name
			end
		else																	-- here when name not in the table
			mw_languages_by_name_t[v] = k;										-- so add name and matching tag
		end
	end

local inter_wiki_map = {};														-- map of interwiki prefixes that are language-code prefixes
	for k, v in pairs (mw.site.interwikiMap ('local')) do						-- spin through the base interwiki map (limited to local)
		if mw_languages_by_tag_t[v["prefix"]] then								-- if the prefix matches a known language tag
			inter_wiki_map[v["prefix"]] = true;									-- add it to our local map
		end
	end


--[[--------------------< S C R I P T _ L A N G _ C O D E S >-------------------

This table is used to hold ISO 639-1 two-character and ISO 639-3 three-character
language codes that apply only to |script-title= and |script-chapter=

]]

local script_lang_codes = {
	'ab', 'am', 'ar', 'be', 'bg', 'bn', 'bo', 'bs', 'dv', 'dz', 'el', 'fa', 'gu', 
	'he', 'hi', 'hy', 'ja', 'ka', 'kk', 'km', 'kn', 'ko', 'ku', 'ky', 'lo', 'mk',
	'ml', 'mn', 'mr', 'my', 'ne', 'or', 'ota', 'ps', 'ru', 'sd', 'si', 'sr', 'syc',
	'ta', 'te', 'tg', 'th', 'ti', 'ug', 'uk', 'ur', 'uz', 'yi', 'yue', 'zh'
	};


--[[---------------< L A N G U A G E   R E M A P P I N G >----------------------

These tables hold language information that is different (correct) from MediaWiki's definitions

For each ['code'] = 'language name' in lang_code_remap{} there must be a matching ['language name'] = {'language name', 'code'} in lang_name_remap{}

lang_code_remap{}:
	key is always lowercase ISO 639-1, -2, -3 language code or a valid lowercase IETF language tag
	value is properly spelled and capitalized language name associated with key
	only one language name per key;
	key/value pair must have matching entry in lang_name_remap{}

lang_name_remap{}:
	key is always lowercase language name
	value is a table the holds correctly spelled and capitalized language name [1] and associated code [2] (code must match a code key in lang_code_remap{})
	may have multiple keys referring to a common preferred name and code; For example:
		['kolsch'] and ['kölsch'] both refer to 'Kölsch' and 'ksh'

]]

local lang_code_remap = {														-- used for |language= and |script-title= / |script-chapter=
	['als'] = 'Tosk Albanian',													-- MediaWiki returns Alemannisch 
	['bh'] = 'Bihari',															-- MediaWiki uses 'bh' as a subdomain name for Bhojpuri Wikipedia: bh.wikipedia.org
	['bla'] = 'Blackfoot',														-- MediaWiki/IANA/ISO 639: Siksika; use en.wiki preferred name
	['bn'] = 'Bengali',															-- MediaWiki returns Bangla
	['ca-valencia'] = 'Valencian',												-- IETF variant of Catalan
	['cmn-cn'] = '中國普通話',
	['cmn-tw'] = '台灣國語',
	['ilo'] = 'Ilocano',														-- MediaWiki/IANA/ISO 639: Iloko; use en.wiki preferred name
	['ksh'] = 'Kölsch',															-- MediaWiki: Colognian; use IANA/ISO 639 preferred name
	['ksh-x-colog'] = 'Colognian',												-- override MediaWiki ksh; no IANA/ISO 639 code for Colognian; IETF private code created at Module:Lang/data
	['mis-x-ripuar'] = 'Ripuarian',												-- override MediaWiki ksh; no IANA/ISO 639 code for Ripuarian; IETF private code created at Module:Lang/data
	['nan-tw'] = 'Taiwanese Hokkien',											-- make room for MediaWiki/IANA/ISO 639 nan: Min Nan Chinese and support en.wiki preferred name
	}

local lang_name_remap = {														-- used for |language=; names require proper capitalization; tags must be lowercase
	['alemannisch'] = {'Swiss German', 'gsw'},									-- not an ISO or IANA language name; MediaWiki uses 'als' as a subdomain name for Alemannic Wikipedia: als.wikipedia.org
	['bangla'] = {'Bengali', 'bn'},												-- MediaWiki returns Bangla (the endonym) but we want Bengali (the exonym); here we remap
	['bengali'] = {'Bengali', 'bn'},											-- MediaWiki doesn't use exonym so here we provide correct language name and 639-1 code
	['bhojpuri'] = {'Bhojpuri', 'bho'},											-- MediaWiki uses 'bh' as a subdomain name for Bhojpuri Wikipedia: bh.wikipedia.org
	['bihari'] = {'Bihari', 'bh'},												-- MediaWiki replaces 'Bihari' with 'Bhojpuri' so 'Bihari' cannot be found
	['blackfoot'] = {'Blackfoot', 'bla'},										-- MediaWiki/IANA/ISO 639: Siksika; use en.wiki preferred name
	['cantonese'] = {'Cantonese', 'yue'},
	['colognian'] = {'Colognian', 'ksh-x-colog'},								-- MediaWiki preferred name for ksh
	['ilocano'] = {'Ilocano', 'ilo'},											-- MediaWiki/IANA/ISO 639: Iloko; use en.wiki preferred name
	['kolsch'] = {'Kölsch', 'ksh'},												-- use IANA/ISO 639 preferred name (use non-diacritical o instead of umlaut ö)
	['kölsch'] = {'Kölsch', 'ksh'},												-- use IANA/ISO 639 preferred name
	['ripuarian'] = {'Ripuarian', 'mis-x-ripuar'},								-- group of dialects; no code in MediaWiki or in IANA/ISO 63
	['taiwanese hokkien'] = {'Taiwanese Hokkien', 'nan-tw'},					-- make room for MediaWiki/IANA/ISO 639 nan: Min Nan Chinese 
	['tosk albanian'] = {'Tosk Albanian', 'als'},								-- MediaWiki replaces 'Tosk Albanian' with 'Alemannisch' so 'Tosk Albanian' cannot be found
	['valencian'] = {'Valencian', 'ca'},										-- variant of Catalan; categorizes as Catalan
	['中國普通話'] = {'中國普通話', 'cmn-cn'},
	['台灣國語'] = {'台灣國語', 'cmn-tw'},
	}


--[[---------------< P R O P E R T I E S _ C A T E G O R I E S >----------------

Properties categories. These are used for investigating qualities of citations.

]]

local prop_cats = {
	['foreign-lang-source'] = 'CS1$1語言來源 ($2)',					-- |language= categories; $1 is foreign-language name, $2 is ISO639-1 code
	['foreign-lang-source-2'] = 'CS1外地語言來源 (ISO 639-2)|$1',	-- |language= category; a cat for ISO639-2 languages; $1 is the ISO 639-2 code used as a sort key
	['jul-greg-uncertainty'] = 'CS1: 年份分唔到係儒略曆定國瑞曆',				-- probably temporary cat to identify scope of template with dates 1 October 1582 – 1 January 1926
	['local-lang-source'] = 'CS1用$1語言文字 ($2)',						-- |language= categories; $1 is local-language name, $2 is ISO639-1 code; not emitted when local_lang_cat_enable is false
	['location-test'] = 'CS1 location test',
	['long-vol'] = 'CS1: long volume value',									-- probably temporary cat to identify scope of |volume= values longer than 4 charachters
	['script'] = 'CS1用$1語言文字 ($2)',					-- |script-title=xx: has matching category; $1 is language name, $2 is ISO639-1 code
	['tracked-param'] = 'CS1 tracked parameter: $1',							-- $1 is base (enumerators removed) parameter name
	['year-range-abbreviated'] = 'CS1: abbreviated year range',					-- probably temporary cat to identify scope of |date=, |year= values using YYYY–YY form
	}


--[[-------------------< T I T L E _ T Y P E S >--------------------------------

Here we map a template's CitationClass to TitleType (default values for |type= parameter)

]]

local title_types = {
	['AV-media-notes'] = 'Media notes',
	['interview'] = '採訪',
	['mailinglist'] = '電郵羣組',
	['map'] = '地圖',
	['podcast'] = 'Podcast',
	['pressrelease'] = '新聞稿',
	['report'] = '報告',
	['techreport'] = '技術報告',
	['thesis'] = '論文',
	}


--[[===================<< E R R O R   M E S S A G I N G >>======================
]]

--[[----------< E R R O R   M E S S A G E   S U P P L I M E N T S >-------------

I18N for those messages that are supplemented with additional specific text that
describes the reason for the error

TODO: merge this with special_case_translations{}?
]]

local err_msg_supl = {
	['char'] = 'invalid character',												-- |isbn=, |sbn=
	['check'] = 'checksum',														-- |isbn=, |sbn=
	['flag'] = 'flag',															-- |archive-url=
	['form'] = 'invalid form',													-- |isbn=, |sbn=
	['group'] = 'invalid group id',												-- |isbn=
	['initials'] = 'initials',													-- Vancouver
	['invalid language code'] = 'invalid language code',						-- |script-<param>=
	['journal'] = 'journal',													-- |bibcode=
	['length'] = 'length',														-- |isbn=, |bibcode=, |sbn=
	['liveweb'] = 'liveweb',													-- |archive-url=
	['missing comma'] = 'missing comma',										-- Vancouver
	['missing prefix'] = 'missing prefix',										-- |script-<param>=
	['missing title part'] = 'missing title part',								-- |script-<param>=
	['name'] = 'name',															-- Vancouver
	['non-Latin char'] = 'non-Latin character',									-- Vancouver
	['path'] = 'path',															-- |archive-url=
	['prefix'] = 'invalid prefix',												-- |isbn=
	['punctuation'] = 'punctuation',											-- Vancouver
	['save'] = 'save command',													-- |archive-url=
	['suffix'] = 'suffix',														-- Vancouver
	['timestamp'] = 'timestamp',												-- |archive-url=
	['unknown language code'] = 'unknown language code',						-- |script-<param>=
	['value'] = 'value',														-- |bibcode=
	['year'] = 'year',															-- |bibcode=
	}


--[[--------------< E R R O R _ C O N D I T I O N S >---------------------------

Error condition table.  This table has two sections: errors at the top, maintenance
at the bottom.  Maint 'messaging' does not have a 'message' (message=nil)

The following contains a list of IDs for various error conditions defined in the
code.  For each ID, we specify a text message to display, an error category to
include, and whether the error message should be wrapped as a hidden comment.

Anchor changes require identical changes to matching anchor in Help:CS1 errors

TODO: rename error_conditions{} to something more generic; create separate error
and maint tables inside that?

]]

local error_conditions = {
	err_accessdate_missing_url = {
		message = '<code class="cs1-code">&#124;access-date=</code> requires <code class="cs1-code">&#124;url=</code>',
		anchor = 'accessdate_missing_url',
		category = 'CS1 errors: access-date without URL',
		hidden = false
 		},
	err_apostrophe_markup = {
		message = 'Italic or bold markup not allowed in: <code class="cs1-code">&#124;$1=</code>',	-- $1 is parameter name
		anchor = 'apostrophe_markup',
		category = 'CS1 errors: markup',
		hidden = false
 		},
	err_archive_missing_date = {
		message = '<code class="cs1-code">&#124;archive-url=</code> requires <code class="cs1-code">&#124;archive-date=</code>',
		anchor = 'archive_missing_date',
		category = 'CS1 errors: archive-url',
		hidden = false
		},
	err_archive_missing_url = {
		message = '<code class="cs1-code">&#124;archive-url=</code> requires <code class="cs1-code">&#124;url=</code>',
		anchor = 'archive_missing_url',
		category = 'CS1 errors: archive-url',
		hidden = false
		},
	err_archive_url = {
		message = '<code class="cs1-code">&#124;archive-url=</code> is malformed: $1',	-- $1 is error message detail
		anchor = 'archive_url',
		category = 'CS1 errors: archive-url',
		hidden = false
		},
	err_arxiv_missing = {
		message = '<code class="cs1-code">&#124;arxiv=</code> required',
		anchor = 'arxiv_missing',
		category = 'CS1 errors: arXiv',											-- same as bad arxiv
		hidden = false
		},
	err_asintld_missing_asin = {
		message = '<code class="cs1-code">&#124;$1=</code> requires <code class="cs1-code">&#124;asin=</code>',	-- $1 is parameter name
		anchor = 'asintld_missing_asin',
		category = 'CS1 errors: ASIN TLD',
		hidden = false
		},
	err_bad_arxiv = {
		message = 'Check <code class="cs1-code">&#124;arxiv=</code> value',
		anchor = 'bad_arxiv',
		category = 'CS1 errors: arXiv',
		hidden = false
		},
	err_bad_asin = {
		message = 'Check <code class="cs1-code">&#124;asin=</code> value',
		anchor = 'bad_asin',
		category ='CS1 errors: ASIN',
		hidden = false
		},
	err_bad_asin_tld = {
		message = 'Check <code class="cs1-code">&#124;asin-tld=</code> value',
		anchor = 'bad_asin_tld',
		category ='CS1 errors: ASIN TLD',
		hidden = false
		},
	err_bad_bibcode = {
		message = 'Check <code class="cs1-code">&#124;bibcode=</code> $1',		-- $1 is error message detail
		anchor = 'bad_bibcode',
		category = 'CS1 errors: bibcode',
		hidden = false
		},
	err_bad_biorxiv = {
		message = 'Check <code class="cs1-code">&#124;biorxiv=</code> value',
		anchor = 'bad_biorxiv',
		category = 'CS1 errors: bioRxiv',
		hidden = false
		},
	err_bad_citeseerx = {
		message = 'Check <code class="cs1-code">&#124;citeseerx=</code> value',
		anchor = 'bad_citeseerx',
		category = 'CS1 errors: citeseerx',
		hidden = false
		},
	err_bad_date = {
		message = 'Check date values in: $1',									-- $1 is a parameter name list
		anchor = 'bad_date',
		category = 'CS1 errors: dates',
		hidden = false
		},
	err_bad_doi = {
		message = 'Check <code class="cs1-code">&#124;doi=</code> value',
		anchor = 'bad_doi',
		category = 'CS1 errors: DOI',
		hidden = false
		},
	err_bad_hdl = {
		message = 'Check <code class="cs1-code">&#124;hdl=</code> value',
		anchor = 'bad_hdl',
		category = 'CS1 errors: HDL',
		hidden = false
		},
	err_bad_isbn = {
		message = 'Check <code class="cs1-code">&#124;isbn=</code> value: $1',	-- $1 is error message detail
		anchor = 'bad_isbn',
		category = 'CS1 errors: ISBN',
		hidden = false
		},
	err_bad_ismn = {
		message = 'Check <code class="cs1-code">&#124;ismn=</code> value',
		anchor = 'bad_ismn',
		category = 'CS1 errors: ISMN',
		hidden = false
		},
	err_bad_issn = {
		message = 'Check <code class="cs1-code">&#124;$1issn=</code> value',	-- $1 is 'e' or '' for eissn or issn
		anchor = 'bad_issn',
		category = 'CS1 errors: ISSN',
		hidden = false
		},
	err_bad_jfm = {
		message = 'Check <code class="cs1-code">&#124;jfm=</code> value',
		anchor = 'bad_jfm',
		category = 'CS1 errors: JFM',
		hidden = false
		},
	err_bad_jstor = {
		message = 'Check <code class="cs1-code">&#124;jstor=</code> value',
		anchor = 'bad_jstor',
		category = 'CS1 errors: JSTOR',
		hidden = false
		},
	err_bad_lccn = {
		message = 'Check <code class="cs1-code">&#124;lccn=</code> value',
		anchor = 'bad_lccn',
		category = 'CS1 errors: LCCN',
		hidden = false
		},
	err_bad_mr = {
		message = 'Check <code class="cs1-code">&#124;mr=</code> value',
		anchor = 'bad_mr',
		category = 'CS1 errors: MR',
		hidden = false
		},
	err_bad_oclc = {
		message = 'Check <code class="cs1-code">&#124;oclc=</code> value',
		anchor = 'bad_oclc',
		category = 'CS1 errors: OCLC',
		hidden = false
		},
	err_bad_ol = {
		message = 'Check <code class="cs1-code">&#124;ol=</code> value',
		anchor = 'bad_ol',
		category = 'CS1 errors: OL',
		hidden = false
		},
	err_bad_osti = {
		message = 'Check <code class="cs1-code">&#124;osti=</code> value',
		anchor = 'bad_osti',
		category = 'CS1 errors: OSTI',
		hidden = false
		},
	err_bad_paramlink = {														-- for |title-link=, |author/editor/translator-link=, |series-link=, |episode-link=
		message = 'Check <code class="cs1-code">&#124;$1=</code> value',		-- $1 is parameter name
		anchor = 'bad_paramlink',
		category = 'CS1 errors: parameter link',
		hidden = false
		},
	err_bad_pmc = {
		message = 'Check <code class="cs1-code">&#124;pmc=</code> value',
		anchor = 'bad_pmc',
		category = 'CS1 errors: PMC',
		hidden = false
		},
	err_bad_pmid = {
		message = 'Check <code class="cs1-code">&#124;pmid=</code> value',
		anchor = 'bad_pmid',
		category = 'CS1 errors: PMID',
		hidden = false
		},
	err_bad_rfc = {
		message = 'Check <code class="cs1-code">&#124;rfc=</code> value',
		anchor = 'bad_rfc',
		category = 'CS1 errors: RFC',
		hidden = false
		},
	err_bad_s2cid = {
		message = 'Check <code class="cs1-code">&#124;s2cid=</code> value',
		anchor = 'bad_s2cid',
		category = 'CS1 errors: S2CID',
		hidden = false
		},
	err_bad_sbn = {
		message = 'Check <code class="cs1-code">&#124;sbn=</code> value: $1',	-- $1 is error message detail
		anchor = 'bad_sbn',
		category = 'CS1 errors: SBN',
		hidden = false
		},
	err_bad_ssrn = {
		message = 'Check <code class="cs1-code">&#124;ssrn=</code> value',
		anchor = 'bad_ssrn',
		category = 'CS1 errors: SSRN',
		hidden = false
		},
	err_bad_url = {
		message = 'Check $1 value',												-- $1 is parameter name
		anchor = 'bad_url',
		category = 'CS1 errors: URL',
		hidden = false
		},
	err_bad_usenet_id = {
		message = 'Check <code class="cs1-code">&#124;message-id=</code> value',
		anchor = 'bad_message_id',
		category = 'CS1 errors: message-id',
		hidden = false
		},
	err_bad_zbl = {
		message = 'Check <code class="cs1-code">&#124;zbl=</code> value',
		anchor = 'bad_zbl',
		category = 'CS1 errors: Zbl',
		hidden = false
		},
	err_bare_url_missing_title = {
		message = '$1 missing title',											-- $1 is parameter name
		anchor = 'bare_url_missing_title',
		category = 'CS1 errors: bare URL',
		hidden = false
		},
	err_biorxiv_missing = {
		message = '<code class="cs1-code">&#124;biorxiv=</code> required',
		anchor = 'biorxiv_missing',
		category = 'CS1 errors: bioRxiv',										-- same as bad bioRxiv
		hidden = false
		},
	err_chapter_ignored = {
		message = '<code class="cs1-code">&#124;$1=</code> ignored',			-- $1 is parameter name
		anchor = 'chapter_ignored',
		category = 'CS1 errors: chapter ignored',
		hidden = false
		},
	err_citation_missing_title = {
		message = 'Missing or empty <code class="cs1-code">&#124;$1=</code>',	-- $1 is parameter name
		anchor = 'citation_missing_title',
		category = 'CS1 errors: missing title',
		hidden = false
		},
	err_citeseerx_missing = {
		message = '<code class="cs1-code">&#124;citeseerx=</code> required',
		anchor = 'citeseerx_missing',
		category = 'CS1 errors: citeseerx',										-- same as bad citeseerx
		hidden = false
		},
	err_cite_web_url = {														-- this error applies to cite web and to cite podcast
		message = 'Missing or empty <code class="cs1-code">&#124;url=</code>',
		anchor = 'cite_web_url',
		category = 'CS1 errors: requires URL',
		hidden = false
		},
	err_class_ignored = {
		message = '<code class="cs1-code">&#124;class=</code> ignored',
		anchor = 'class_ignored',
		category = 'CS1 errors: class',
		hidden = false
		},
	err_contributor_ignored = {
		message = '<code class="cs1-code">&#124;contributor=</code> ignored',
		anchor = 'contributor_ignored',
		category = 'CS1 errors: contributor',
		hidden = false
		},
	err_contributor_missing_required_param = {
		message = '<code class="cs1-code">&#124;contributor=</code> requires <code class="cs1-code">&#124;$1=</code>',	-- $1 is parameter name
		anchor = 'contributor_missing_required_param',
		category = 'CS1 errors: contributor',
		hidden = false
		},
	err_deprecated_params = {
		message = 'Cite uses deprecated parameter <code class="cs1-code">&#124;$1=</code>',	-- $1 is parameter name
		anchor = 'deprecated_params',
		category = 'CS1 errors: deprecated parameters',
		hidden = false
		},
	err_disp_name = {
		message = 'Invalid <code class="cs1-code">&#124;$1=$2</code>',			-- $1 is parameter name; $2 is the assigned value
		anchor = 'disp_name',
		category = 'CS1 errors: display-names',
		hidden = false,
		},
	err_doibroken_missing_doi = {
		message = '<code class="cs1-code">&#124;$1=</code> requires <code class="cs1-code">&#124;doi=</code>',	-- $1 is parameter name
		anchor = 'doibroken_missing_doi',
		category = 'CS1 errors: DOI',
		hidden = false
		},
	err_embargo_missing_pmc = {
		message = '<code class="cs1-code">&#124;$1=</code> requires <code class="cs1-code">&#124;pmc=</code>',	-- $1 is parameter name
		anchor = 'embargo_missing_pmc',
		category = 'CS1 errors: PMC embargo',
		hidden = false
		},
	err_empty_citation = {
		message = 'Empty citation',
		anchor = 'empty_citation',
		category = 'CS1 errors: empty citation',
		hidden = false
		},
	err_etal = {
		message = 'Explicit use of et al. in: <code class="cs1-code">&#124;$1=</code>',	-- $1 is parameter name
		anchor = 'explicit_et_al',
		category = 'CS1 errors: explicit use of et al.',
		hidden = false
		},
	err_extra_text_edition = {
		message = '<code class="cs1-code">&#124;edition=</code> has extra text',
		anchor = 'extra_text_edition',
		category = 'CS1 errors: extra text: edition',
		hidden = false,
		},
	err_extra_text_issue = {
		message = '<code class="cs1-code">&#124;$1=</code> has extra text',		-- $1 is parameter name
		anchor = 'extra_text_issue',
		category = 'CS1 errors: extra text: issue',
		hidden = false,
		},
	err_extra_text_pages = {
		message = '<code class="cs1-code">&#124;$1=</code> has extra text',		-- $1 is parameter name
		anchor = 'extra_text_pages',
		category = 'CS1 errors: extra text: pages',
		hidden = false,
		},
	err_extra_text_volume = {
		message = '<code class="cs1-code">&#124;$1=</code> has extra text',		-- $1 is parameter name
		anchor = 'extra_text_volume',
		category = 'CS1 errors: extra text: volume',
		hidden = true,
		},
	err_first_missing_last = {
		message = '<code class="cs1-code">&#124;$1=</code> missing <code class="cs1-code">&#124;$2=</code>',	-- $1 is first alias, $2 is matching last alias
		anchor = 'first_missing_last',
		category = 'CS1 errors: missing name', -- author, contributor, editor, interviewer, translator
		hidden = false
		},
	err_format_missing_url = {
		message = '<code class="cs1-code">&#124;$1=</code> requires <code class="cs1-code">&#124;$2=</code>',	-- $1 is format parameter $2 is url parameter
		anchor = 'format_missing_url',
		category = 'CS1 errors: format without URL',
		hidden = false
		},
	err_generic_name = {
		message = '<code class="cs1-code">&#124;$1=</code> has generic name',	-- $1 is parameter name
		anchor = 'generic_name',
		category = 'CS1 errors: generic name',
		hidden = false,
		},
	err_generic_title = {
		message = 'Cite uses generic title',
		anchor = 'generic_title',
		category = 'CS1 errors: generic title',
		hidden = false,
		},
	err_invalid_param_val = {
		message = 'Invalid <code class="cs1-code">&#124;$1=$2</code>',			-- $1 is parameter name $2 is parameter value
		anchor = 'invalid_param_val',
		category = 'CS1 errors: invalid parameter value',
		hidden = false
		},
	err_invisible_char = {
		message = '$1 in $2 at position $3',									-- $1 is invisible char $2 is parameter name $3 is position number
		anchor = 'invisible_char',
		category = 'CS1 errors: invisible characters',
		hidden = false
		},
	err_missing_name = {
		message = 'Missing <code class="cs1-code">&#124;$1$2=</code>',			-- $1 is modified NameList; $2 is enumerator
		anchor = 'missing_name',
		category = 'CS1 errors: missing name',									-- author, contributor, editor, interviewer, translator
		hidden = false
		},
	err_missing_periodical = {
		message = 'Cite $1 requires <code class="cs1-code">&#124;$2=</code>',	-- $1 is cs1 template name; $2 is canonical periodical parameter name for cite $1
		anchor = 'missing_periodical',
		category = 'CS1 errors: missing periodical',
		hidden = true
		},
	err_missing_pipe = {
		message = 'Missing pipe in: <code class="cs1-code">&#124;$1=</code>',	-- $1 is parameter name
		anchor = 'missing_pipe',
		category = 'CS1 errors: missing pipe',
		hidden = false
		},
	err_param_access_requires_param = {
		message = '<code class="cs1-code">&#124;$1-access=</code> requires <code class="cs1-code">&#124;$1=</code>',	-- $1 is parameter name
		anchor = 'param_access_requires_param',
		category = 'CS1 errors: param-access',
		hidden = false
		},
	err_param_has_ext_link = {
		message = 'External link in <code class="cs1-code">$1</code>',			-- $1 is parameter name
		anchor = 'param_has_ext_link',
		category = 'CS1 errors: external links',
		hidden = false
		},
	err_parameter_ignored = {
		message = 'Unknown parameter <code class="cs1-code">&#124;$1=</code> ignored',	-- $1 is parameter name
		anchor = 'parameter_ignored',
		category = 'CS1 errors: unsupported parameter',
		hidden = false
		},
	err_parameter_ignored_suggest = {
		message = 'Unknown parameter <code class="cs1-code">&#124;$1=</code> ignored (<code class="cs1-code">&#124;$2=</code> suggested)',	-- $1 is unknown parameter $2 is suggested parameter name
		anchor = 'parameter_ignored_suggest',
		category = 'CS1 errors: unsupported parameter',
		hidden = false
		},
	err_redundant_parameters = {
		message = 'More than one of $1 specified',								-- $1 is error message detail
		anchor = 'redundant_parameters',
		category = 'CS1 errors: redundant parameter',
		hidden = false
		},
	err_script_parameter = {
		message = 'Invalid <code class="cs1-code">&#124;$1=</code>: $2',		-- $1 is parameter name $2 is script language code or error detail
		anchor = 'script_parameter',
		category = 'CS1 errors: script parameters',
		hidden = false
		},
	err_ssrn_missing = {
		message = '<code class="cs1-code">&#124;ssrn=</code> required',
		anchor = 'ssrn_missing',
		category = 'CS1 errors: SSRN',											-- same as bad arxiv
		hidden = false
		},
	err_text_ignored = {
		message = 'Text "$1" ignored',											-- $1 is ignored text
		anchor = 'text_ignored',
		category = 'CS1 errors: unrecognized parameter',
		hidden = false
		},
	err_trans_missing_title = {
		message = '<code class="cs1-code">&#124;trans-$1=</code> requires <code class="cs1-code">&#124;$1=</code> or <code class="cs1-code">&#124;script-$1=</code>',	-- $1 is base parameter name
		anchor = 'trans_missing_title',
		category = 'CS1 errors: translated title',
		hidden = false
		},
	err_param_unknown_empty = {
		message = 'Cite has empty unknown parameter$1: $2',						-- $1 is 's' or empty space; $2 is emty unknown param list
		anchor = 'param_unknown_empty',
		category = 'CS1 errors: empty unknown parameters',
		hidden = false
		},
	err_vancouver = {
		message = 'Vancouver style error: $1 in name $2',						-- $1 is error detail, $2 is the nth name
		anchor = 'vancouver',
		category = 'CS1 errors: Vancouver style',
		hidden = false
		},
	err_wikilink_in_url = {
		message = 'URL–wikilink conflict',										-- uses ndash
		anchor = 'wikilink_in_url',
		category = 'CS1 errors: URL–wikilink conflict',							-- uses ndash
		hidden = false
		},


--[[--------------------------< M A I N T >-------------------------------------

maint messages do not have a message (message = nil); otherwise the structure
is the same as error messages

]]

	maint_archived_copy = {
		message = nil,
		anchor = 'archived_copy',
		category = 'CS1 maint: archived copy as title',
		hidden = true,
		},
	maint_authors = {
		message = nil,
		anchor = 'authors',
		category = 'CS1 maint: uses authors parameter',
		hidden = true,
		},
	maint_bot_unknown = {
		message = nil,
		anchor = 'bot:_unknown',
		category = 'CS1 maint: bot: original URL status unknown',
		hidden = true,
		},
	maint_date_auto_xlated = {													-- date auto-translation not supported by en.wiki
		message = nil,
		anchor = 'date_auto_xlated',
		category = 'CS1 maint: date auto-translated',
		hidden = true,
		},
	maint_date_format = {
		message = nil,
		anchor = 'date_format',
		category = 'CS1 maint: date format',
		hidden = true,
		},
	maint_date_year = {
		message = nil,
		anchor = 'date_year',
		category = 'CS1 maint: date and year',
		hidden = true,
		},
	maint_doi_ignore = {
		message = nil,
		anchor = 'doi_ignore',
		category = 'CS1 maint: ignored DOI errors',
		hidden = true,
		},
	maint_doi_inactive = {
		message = nil,
		anchor = 'doi_inactive',
		category = 'CS1 maint: DOI inactive',
		hidden = true,
		},
	maint_doi_inactive_dated = {
		message = nil,
		anchor = 'doi_inactive_dated',
		category = 'CS1 maint: DOI inactive as of $2$3$1',						-- $1 is year, $2 is month-name or empty string, $3 is space or empty string
		hidden = true,
		},
	maint_extra_punct = {
		message = nil,
		anchor = 'extra_punct',
		category = 'CS1 maint: extra punctuation',
		hidden = true,
		},
	maint_isbn_ignore = {
		message = nil,
		anchor = 'ignore_isbn_err',
		category = 'CS1 maint: ignored ISBN errors',
		hidden = true,
		},
	maint_issn_ignore = {
		message = nil,
		anchor = 'ignore_issn',
		category = 'CS1 maint: ignored ISSN errors',
		hidden = true,
		},
	maint_jfm_format = {
		message = nil,
		anchor = 'jfm_format',
		category = 'CS1 maint: JFM format',
		hidden = true,
		},
	maint_location = {
		message = nil,
		anchor = 'location',
		category = 'CS1 maint: location',
		hidden = true,
	},
	maint_mr_format = {
		message = nil,
		anchor = 'mr_format',
		category = 'CS1 maint: MR format',
		hidden = true,
	},
	maint_mult_names = {
		message = nil,
		anchor = 'mult_names',
		category = 'CS1 maint: multiple names: $1',								-- $1 is '<name>s list'; gets value from special_case_translation table
		hidden = true,
		},
	maint_numeric_names = {
		message = nil,
		anchor = 'numeric_names',
		category = 'CS1 maint: numeric names: $1',								-- $1 is '<name>s list'; gets value from special_case_translation table
		hidden = true,
		},
	maint_others = {
		message = nil,
		anchor = 'others',
		category = 'CS1 maint: others',
		hidden = true,
		},
	maint_others_avm = {
		message = nil,
		anchor = 'others_avm',
		category = 'CS1 maint: others in cite AV media (notes)',
		hidden = true,
	},
	maint_pmc_embargo = {
		message = nil,
		anchor = 'embargo',
		category = 'CS1 maint: PMC embargo expired',
		hidden = true,
		},
	maint_pmc_format = {
		message = nil,
		anchor = 'pmc_format',
		category = 'CS1 maint: PMC format',
		hidden = true,
		},
	maint_postscript = {
		message = nil,
		anchor = 'postscript',
		category = 'CS1 maint: postscript',
		hidden = true,
	},
	maint_ref_duplicates_default = {
		message = nil,
		anchor = 'ref_default',
		category = 'CS1 maint: ref duplicates default',
		hidden = true,
	},
	maint_unfit = {
		message = nil,
		anchor = 'unfit',
		category = 'CS1 maint: unfit URL',
		hidden = true,
		},
	maint_unknown_lang = {
		message = nil,
		anchor = 'unknown_lang',
		category = 'CS1 maint: unrecognized language',
		hidden = true,
		},
	maint_untitled = {
		message = nil,
		anchor = 'untitled',
		category = 'CS1 maint: untitled periodical',
		hidden = true,
		},
	maint_url_status = {
		message = nil,
		anchor = 'url_status',
		category = 'CS1 maint: url-status',
		hidden = true,
		},
	maint_zbl = {
		message = nil,
		anchor = 'zbl',
		category = 'CS1 maint: Zbl',
		hidden = true,
		},
	}


--[[--------------------------< I D _ H A N D L E R S >--------------------------------------------------------

The following contains a list of values for various defined identifiers.  For each
identifier we specify a variety of information necessary to properly render the
identifier in the citation.

	parameters: a list of parameter aliases for this identifier; first in the list is the canonical form
	link: Wikipedia article name
	redirect: a local redirect to a local Wikipedia article name;  at en.wiki, 'ISBN (identifier)' is a redirect to 'International Standard Book Number'
	q: Wikidata q number for the identifier
	label: the label preceeding the identifier; label is linked to a Wikipedia article (in this order):
		redirect from id_handlers['<id>'].redirect when use_identifier_redirects is true
		Wikidata-supplied article name for the local wiki from id_handlers['<id>'].q
		local article name from id_handlers['<id>'].link
	prefix: the first part of a URL that will be concatenated with a second part which usually contains the identifier
	suffix: optional third part to be added after the identifier
	encode: true if URI should be percent-encoded; otherwise false
	COinS: identifier link or keyword for use in COinS:
		for identifiers registered at info-uri.info use: info:.... where '...' is the appropriate identifier label 
		for identifiers that have COinS keywords, use the keyword: rft.isbn, rft.issn, rft.eissn
		for |asin= and |ol=, which require assembly, use the keyword: url
		for others make a URL using the value in prefix/suffix and #label, use the keyword: pre (not checked; any text other than 'info', 'rft', or 'url' works here)
		set to nil to leave the identifier out of the COinS
	separator: character or text between label and the identifier in the rendered citation
	id_limit: for those identifiers with established limits, this property holds the upper limit
	access: use this parameter to set the access level for all instances of this identifier.
		the value must be a valid access level for an identifier (see ['id-access'] in this file).
	custom_access: to enable custom access level for an identifier, set this parameter
		to the parameter that should control it (normally 'id-access')
		
]]

local id_handlers = {
	['ARXIV'] = {
		parameters = {'arxiv', 'eprint'},
		link = 'arXiv',
		redirect = 'arXiv (identifier)',
		q = 'Q118398',
		label = 'arXiv',
		prefix = '//arxiv.org/abs/', 											-- protocol-relative tested 2013-09-04
		encode = false,
		COinS = 'info:arxiv',
		separator = ':',
		access = 'free',														-- free to read
		},
	['ASIN'] = {
		parameters = { 'asin', 'ASIN' },
		link = 'Amazon Standard Identification Number',
		redirect = 'ASIN (identifier)',
		q = 'Q1753278',
		label = 'ASIN',
		prefix = '//www.amazon.',
		COinS = 'url',
		separator = '&nbsp;',
		encode = false;
		},
	['BIBCODE'] = {
		parameters = {'bibcode'},
		link = 'Bibcode',
		redirect = 'Bibcode (identifier)',
		q = 'Q25754',
		label = 'Bibcode',
		prefix = 'https://ui.adsabs.harvard.edu/abs/',
		encode = false,
		COinS = 'info:bibcode',
		separator = ':',
		custom_access = 'bibcode-access',
		},
	['BIORXIV'] = {
		parameters = {'biorxiv'},
		link = 'bioRxiv',
		redirect = 'bioRxiv (identifier)',
		q = 'Q19835482',
		label = 'bioRxiv',
		prefix = '//doi.org/',
		COinS = 'pre',															-- use prefix value
		access = 'free',														-- free to read
		encode = true,
		separator = '&nbsp;',
		},
	['CITESEERX'] = {
		parameters = {'citeseerx'},
		link = 'CiteSeerX',
		redirect = 'CiteSeerX (identifier)',
		q = 'Q2715061',
		label = 'CiteSeerX',
		prefix = '//citeseerx.ist.psu.edu/viewdoc/summary?doi=',
		COinS =  'pre',															-- use prefix value
		access = 'free',														-- free to read
		encode = true,
		separator = '&nbsp;',
		},
	['DOI'] = {																	-- Used by InternetArchiveBot
		parameters = { 'doi', 'DOI'},
		link = 'Digital object identifier',
		redirect = 'doi (identifier)',
		q = 'Q25670',
		label = 'doi',
		prefix = '//doi.org/',
		COinS = 'info:doi',
		separator = ':',
		encode = true,
		custom_access = 'doi-access',
		},
	['EISSN'] = {
		parameters = {'eissn', 'EISSN'},
		link = 'International Standard Serial Number#Electronic ISSN',
		redirect = 'eISSN (identifier)',
		q = 'Q46339674',
		label = 'eISSN',
		prefix = '//www.worldcat.org/issn/',
		COinS = 'rft.eissn',
		encode = false,
		separator = '&nbsp;',
		},
	['HDL'] = {
		parameters = { 'hdl', 'HDL' },
		link = 'Handle System',
		redirect = 'hdl (identifier)',
		q = 'Q3126718',
		label = 'hdl',
		prefix = '//hdl.handle.net/',
		COinS = 'info:hdl',
		separator = ':',
		encode = true,
		custom_access = 'hdl-access',
		},
	['ISBN'] = {																-- Used by InternetArchiveBot
		parameters = {'isbn', 'ISBN'},
		link = 'International Standard Book Number',
		redirect = 'ISBN (identifier)',
		q = 'Q33057',
		label = 'ISBN',
		prefix = 'Special:BookSources/',
		COinS = 'rft.isbn',
		separator = '&nbsp;',
		},
	['ISMN'] = {
		parameters = {'ismn', 'ISMN'},
		link = 'International Standard Music Number',
		redirect = 'ISMN (identifier)',
		q = 'Q1666938',
		label = 'ISMN',
		prefix = '',															-- not currently used;
		COinS = nil,															-- nil because we can't use pre or rft or info:
		separator = '&nbsp;',
		},
	['ISSN'] = {
		parameters = {'issn', 'ISSN'},
		link = 'International Standard Serial Number',
		redirect = 'ISSN (identifier)',
		q = 'Q131276',
		label = 'ISSN',
		prefix = '//www.worldcat.org/issn/',
		COinS = 'rft.issn',
		encode = false,
		separator = '&nbsp;',
		},
	['JFM'] = {
		parameters = {'jfm', 'JFM'},
		link = 'Jahrbuch über die Fortschritte der Mathematik',
		redirect = 'JFM (identifier)',
		q = '',
		label = 'JFM',
		prefix = '//zbmath.org/?format=complete&q=an:',
		COinS = 'pre',															-- use prefix value
		encode = true,
		separator = '&nbsp;',
		},
	['JSTOR'] = {
		parameters = {'jstor', 'JSTOR'},
		link = 'JSTOR',
		redirect = 'JSTOR (identifier)',
		q = 'Q1420342',
		label = 'JSTOR',
		prefix = '//www.jstor.org/stable/', 									-- protocol-relative tested 2013-09-04
		COinS = 'pre',															-- use prefix value
		encode = false,
		separator = '&nbsp;',
		custom_access = 'jstor-access',
		},
	['LCCN'] = {
		parameters = {'lccn', 'LCCN'},
		link = 'Library of Congress Control Number',
		redirect = 'LCCN (identifier)',
		q = 'Q620946',
		label = 'LCCN',
		prefix = '//lccn.loc.gov/', 											-- protocol-relative tested 2015-12-28
		COinS = 'info:lccn',
		encode = false,
		separator = '&nbsp;',
		},
	['MR'] = {
		parameters = {'mr', 'MR'},
		link = 'Mathematical Reviews',
		redirect = 'MR (identifier)',
		q = 'Q211172',
		label = 'MR',
		prefix = '//www.ams.org/mathscinet-getitem?mr=', 						-- protocol-relative tested 2013-09-04
		COinS = 'pre',															-- use prefix value
		encode = true,
		separator = '&nbsp;',
		},
	['OCLC'] = {
		parameters = {'oclc', 'OCLC'},
		link = 'OCLC',
		redirect = 'OCLC (identifier)',
		q = 'Q190593',
		label = 'OCLC',
		prefix = '//www.worldcat.org/oclc/',
		COinS = 'info:oclcnum',
		encode = true,
		separator = '&nbsp;',
		id_limit = 9999999999,													-- 10-digits
		},
	['OL'] = {
		parameters = { 'ol', 'OL' },
		link = 'Open Library',
		redirect = 'OL (identifier)',
		q = 'Q1201876',
		label = 'OL',
		prefix = '//openlibrary.org/',
		COinS = 'url',
		separator = '&nbsp;',
		encode = true,
		custom_access = 'ol-access',
		},
	['OSTI'] = {
		parameters = {'osti', 'OSTI'},
		link = 'Office of Scientific and Technical Information',
		redirect = 'OSTI (identifier)',
		q = 'Q2015776',
		label = 'OSTI',
		prefix = '//www.osti.gov/biblio/',										-- protocol-relative tested 2018-09-12
		COinS = 'pre',															-- use prefix value
		encode = true,
		separator = '&nbsp;',
		id_limit = 23010000,
		custom_access = 'osti-access',
		},
	['PMC'] = {
		parameters = {'pmc', 'PMC'},
		link = 'PubMed Central',
		redirect = 'PMC (identifier)',
		q = 'Q229883',
		label = 'PMC',
		prefix = '//www.ncbi.nlm.nih.gov/pmc/articles/PMC',
		suffix = '',
		COinS = 'pre',															-- use prefix value
		encode = true,
		separator = '&nbsp;',
		id_limit = 9500000,
		access = 'free',														-- free to read
		},
	['PMID'] = {
		parameters = {'pmid', 'PMID'},
		link = 'PubMed Identifier',
		redirect = 'PMID (identifier)',
		q = 'Q2082879',
		label = 'PMID',
		prefix = '//pubmed.ncbi.nlm.nih.gov/',
		COinS = 'info:pmid',
		encode = false,
		separator = '&nbsp;',
		id_limit = 36400000,
		},
	['RFC'] = {
		parameters = {'rfc', 'RFC'},
		link = 'Request for Comments',
		redirect = 'RFC (identifier)',
		q = 'Q212971',
		label = 'RFC',
		prefix = '//tools.ietf.org/html/rfc',
		COinS = 'pre',															-- use prefix value
		encode = false,
		separator = '&nbsp;',
		id_limit = 9300,
		access = 'free',														-- free to read
		},
	['SBN'] = {
		parameters = {'sbn', 'SBN'},
		link = 'Standard Book Number',											-- redirect to International_Standard_Book_Number#History
		redirect = 'SBN (identifier)',
		label = 'SBN',
		prefix = 'Special:BookSources/0-',										-- prefix has leading zero necessary to make 9-digit sbn a 10-digit isbn
		COinS = nil,															-- nil because we can't use pre or rft or info:
		separator = '&nbsp;',
		},
	['SSRN'] = {
		parameters = {'ssrn', 'SSRN'},
		link = 'Social Science Research Network',
		redirect = 'SSRN (identifier)',
		q = 'Q7550801',
		label = 'SSRN',
		prefix = '//ssrn.com/abstract=', 										-- protocol-relative tested 2013-09-04
		COinS = 'pre',															-- use prefix value
		encode = true,
		separator = '&nbsp;',
		id_limit = 4200000,
		custom_access = 'ssrn-access',
		},
	['S2CID'] = {
		parameters = {'s2cid', 'S2CID'},
		link = 'Semantic Scholar',
		redirect = 'S2CID (identifier)',
		q = 'Q22908627',
		label = 'S2CID',
		prefix = 'https://api.semanticscholar.org/CorpusID:',
		COinS = 'pre',															-- use prefix value
		encode = false,
		separator = '&nbsp;',
		id_limit = 254000000,
		custom_access = 's2cid-access',
		},
	['USENETID'] = {
		parameters = {'message-id'},
		link = 'Usenet',
		redirect = 'Usenet (identifier)',
		q = 'Q193162',
		label = 'Usenet:',
		prefix = 'news:',
		encode = false,
		COinS = 'pre',															-- use prefix value
		separator = '&nbsp;',
		},
	['ZBL'] = {
		parameters = {'zbl', 'ZBL' },
		link = 'Zentralblatt MATH',
		redirect = 'Zbl (identifier)',
		q = 'Q190269',
		label = 'Zbl',
		prefix = '//zbmath.org/?format=complete&q=an:',
		COinS = 'pre',															-- use prefix value
		encode = true,
		separator = '&nbsp;',
		},
	}


--[[--------------------------< E X P O R T S >---------------------------------
]]

return 	{
	use_identifier_redirects = true,											-- when true use redirect name for identifier label links; always true at en.wiki
	local_lang_cat_enable = false;												-- when true categorizes pages where |language=<local wiki's language>; always false at en.wiki
	date_name_auto_xlate_enable = false;										-- when true translates English month-names to the local-wiki's language month names; always false at en.wiki
	date_digit_auto_xlate_enable = false;										-- when true translates Western date digit to the local-wiki's language digits (date_names['local_digits']); always false at en.wiki
	
	global_df = get_date_format (),												-- tables and variables created when this module is loaded
	punct_skip = build_skip_table (punct_skip, punct_meta_params),
	url_skip = build_skip_table (url_skip, url_meta_params),

	aliases = aliases,
	special_case_translation = special_case_translation,
	date_names = date_names,
	err_msg_supl = err_msg_supl,
	error_conditions = error_conditions,
	editor_markup_patterns = editor_markup_patterns,
	et_al_patterns = et_al_patterns,
	id_handlers = id_handlers,
	keywords_lists = keywords_lists,
	keywords_xlate = keywords_xlate,
	stripmarkers=stripmarkers,
	invisible_chars = invisible_chars,
	invisible_defs = invisible_defs,
	indic_script = indic_script,
	emoji = emoji,
	maint_cats = maint_cats,
	messages = messages,
	presentation = presentation,
	prop_cats = prop_cats,
	script_lang_codes = script_lang_codes,
	lang_code_remap = lang_code_remap,
	lang_name_remap = lang_name_remap,
	this_wiki_code = this_wiki_code,
	title_types = title_types,
	uncategorized_namespaces = uncategorized_namespaces,
	uncategorized_subpages = uncategorized_subpages,
	templates_using_volume = templates_using_volume,
	templates_using_issue = templates_using_issue,
	templates_not_using_page = templates_not_using_page,
	vol_iss_pg_patterns = vol_iss_pg_patterns,
	
	inter_wiki_map = inter_wiki_map,
	mw_languages_by_tag_t = mw_languages_by_tag_t,
	mw_languages_by_name_t = mw_languages_by_name_t,
	citation_class_map_t = citation_class_map_t,

	citation_issue_t = citation_issue_t,
	citation_no_volume_t = citation_no_volume_t,
	}
