--[[--------------------------< S U P P O R T E D   P A R A M E T E R S >--------------------------------------

Because a steady-state signal conveys no useful information, whitelist.basic_arguments[] list items can have three values:
	true - these parameters are valid and supported parameters
	false - these parameters are deprecated but still supported
	tracked - these parameters are valid and supported parameters tracked in an eponymous properties category
	nil - these parameters are no longer supported. remove entirely
	
]]

local basic_arguments = {
	['accessdate'] = true,
	['access-date'] = true,
	['agency'] = true,
	['archivedate'] = true,
	['archive-date'] = true,
	['archive-format'] = true,
	['archiveurl'] = true,
	['archive-url'] = true,
	['article'] = true,
	['article-format'] = true,
	['article-url'] = true,
	['article-url-access'] = true,
	['arxiv'] = true,															-- cite arxiv; here because allowed in cite ... as identifier
	['asin'] = true,
	['ASIN'] = true,
	['asin-tld'] = true,
	['at'] = true,
	['author'] = true,
	['author-first'] = true,
	['author-given'] = true,
	['author-last'] = true,
	['author-surname'] = true,
	['authorlink'] = true,
	['author-link'] = true,
	['author-mask'] = true,
	['authors'] = true,
	['bibcode'] = true,
	['bibcode-access'] = true,
	['biorxiv'] = true,															-- cite biorxiv; here because allowed in cite ... as identifier
	['chapter'] = true,
	['chapter-format'] = true,
	['chapter-url'] = true,
	['chapter-url-access'] = true,
	['citeseerx'] = true,														-- cite citeseerx; here because allowed in cite ... as identifier
	['collaboration'] = true,
	['contribution'] = true,
	['contribution-format'] = true,
	['contribution-url'] = true,
	['contribution-url-access'] = true,
	['contributor'] = true,
	['contributor-first'] = true,
	['contributor-given'] = true,
	['contributor-last'] = true,
	['contributor-surname'] = true,
	['contributor-link'] = true,
	['contributor-mask'] = true,
	['date'] = true,
	['department'] = true,
	['df'] = true,
	['dictionary'] = true,
	['display-authors'] = true,
	['display-contributors'] = true,
	['display-editors'] = true,
	['display-interviewers'] = true,
	['display-subjects'] = true,
	['display-translators'] = true,
	['doi'] = true,
	['DOI'] = true,
	['doi-access'] = true,
	['doi-broken-date'] = true,
	['edition'] = true,
	['editor'] = true,
	['editor-first'] = true,
	['editor-given'] = true,
	['editor-last'] = true,
	['editor-surname'] = true,
	['editor-link'] = true,
	['editor-mask'] = true,
	['eissn'] = true,
	['EISSN'] = true,
	['encyclopaedia'] = true,
	['encyclopedia'] = true,
	['entry'] = true,
	['entry-format'] = true,
	['entry-url'] = true,
	['entry-url-access'] = true,
	['eprint'] = true,															-- cite arxiv; here because allowed in cite ... as identifier
	['first'] = true,
	['format'] = true,
	['given'] = true,
	['hdl'] = true,
	['HDL'] = true,
	['hdl-access'] = true,
	['host'] = true,															-- unique to certain templates?
	['id'] = true,
	['ID'] = true,
	['institution'] = true,														-- constrain to cite thesis?
	['interviewer'] = true,
	['interviewer-first'] = true,
	['interviewer-given'] = true,
	['interviewer-last'] = true,
	['interviewer-surname'] = true,
	['interviewer-link'] = true,
	['interviewer-mask'] = true,
	['isbn'] = true,
	['ISBN'] = true,
	['ismn'] = true,
	['ISMN'] = true,
	['issn'] = true,
	['ISSN'] = true,
	['issue'] = true,
	['jfm'] = true,
	['JFM'] = true,
	['journal'] = true,
	['jstor'] = true,
	['JSTOR'] = true,
	['jstor-access'] = true,
	['lang'] = true,
	['language'] = true,
	['last'] = true,
	['lay-date'] = false,
	['lay-format'] = false,
	['lay-source'] = false,
	['lay-url'] = false,
	['lccn'] = true,
	['LCCN'] = true,
	['location'] = true,
	['magazine'] = true,
	['medium'] = true,
	['minutes'] = true,															-- constrain to cite AV media and podcast?
	['mode'] = true,
	['mr'] = true,
	['MR'] = true,
	['name-list-style'] = true,
	['newspaper'] = true,
	['no-pp'] = true,
	['no-tracking'] = true,
	['number'] = true,
	['oclc'] = true,
	['OCLC'] = true,
	['ol'] = true,
	['OL'] = true,
	['ol-access'] = true,
	['orig-date'] = true,
	['origyear'] = true,
	['orig-year'] = true,
	['osti'] = true,
	['OSTI'] = true,
	['osti-access'] = true,
	['others'] = true,
	['p'] = true,
	['page'] = true,
	['pages'] = true,
	['people'] = true,
	['periodical'] = true,
	['place'] = true,
	['pmc'] = true,
	['PMC'] = true,
	['pmc-embargo-date'] = true,
	['pmid'] = true,
	['PMID'] = true,
	['postscript'] = true,
	['pp'] = true,
	['publication-date'] = true,
	['publication-place'] = true,
	['publisher'] = true,
	['quotation'] = true,
	['quote'] = true,
	['quote-page'] = true,
	['quote-pages'] = true,
	['ref'] = true,
	['rfc'] = true,
	['RFC'] = true,
	['sbn'] = true,
	['SBN'] = true,
	['scale'] = true,
	['script-article'] = true,
	['script-chapter'] = true,
	['script-contribution'] = true,
	['script-entry'] = true,
	['script-journal'] = true,
	['script-magazine'] = true,
	['script-newspaper'] = true,
	['script-periodical'] = true,
	['script-quote'] = true,
	['script-section'] = true,
	['script-title'] = true,
	['script-website'] = true,
	['script-work'] = true,
	['section'] = true,
	['section-format'] = true,
	['section-url'] = true,
	['section-url-access'] = true,
	['series'] = true,
	['ssrn'] = true,															-- cite ssrn; these three here because allowed in cite ... as identifier
	['SSRN'] = true,
	['ssrn-access'] = true,
	['subject'] = true,
	['subject-link'] = true,
	['subject-mask'] = true,
	['surname'] = true,
	['s2cid'] = true,
	['S2CID'] = true,
	['s2cid-access'] = true,
	['template-doc-demo'] = true,
	['time'] = true,															-- constrain to cite av media and podcast?
	['time-caption'] = true,													-- constrain to cite av media and podcast?
	['title'] = true,
	['title-link'] = true,
	['translator'] = true,
	['translator-first'] = true,
	['translator-given'] = true,
	['translator-last'] = true,	
	['translator-surname'] = true,
	['translator-link'] = true,
	['translator-mask'] = true,
	['trans-article'] = true,
	['trans-chapter'] = true,
	['trans-contribution'] = true,
	['trans-entry'] = true,
	['trans-journal'] = true,
	['trans-magazine'] = true,
	['trans-newspaper'] = true,
	['trans-periodical'] = true,
	['trans-quote'] = true,
	['trans-section'] = true,
	['trans-title'] = true,
	['trans-website'] = true,
	['trans-work'] = true,
	['type'] = true,
	['url'] = true,
	['URL'] = true,
	['url-access'] = true,
	['url-status'] = true,
	['vauthors'] = true,
	['veditors'] = true,
	['version'] = true,
	['via'] = true,
	['volume'] = true,
	['website'] = true,
	['work'] = true,
	['year'] = true,
	['zbl'] = true,
	['ZBL'] = true,
	}

local numbered_arguments = {
	['author#'] = true,
	['author-first#'] = true,
	['author#-first'] = true,
	['author-given#'] = true,
	['author#-given'] = true,
	['author-last#'] = true,
	['author#-last'] = true,
	['author-surname#'] = true,
	['author#-surname'] = true,
	['author-link#'] = true,
	['author#-link'] = true,
	['authorlink#'] = true,
	['author#link'] = true,
	['author-mask#'] = true,
	['author#-mask'] = true,
	['contributor#'] = true,
	['contributor-first#'] = true,
	['contributor#-first'] = true,
	['contributor-given#'] = true,
	['contributor#-given'] = true,
	['contributor-last#'] = true,
	['contributor#-last'] = true,
	['contributor-surname#'] = true,
	['contributor#-surname'] = true,
	['contributor-link#'] = true,
	['contributor#-link'] = true,
	['contributor-mask#'] = true,
	['contributor#-mask'] = true,
	['editor#'] = true,
	['editor-first#'] = true,
	['editor#-first'] = true,
	['editor-given#'] = true,
	['editor#-given'] = true,
	['editor-last#'] = true,
	['editor#-last'] = true,
	['editor-surname#'] = true,
	['editor#-surname'] = true,
	['editor-link#'] = true,
	['editor#-link'] = true,
	['editor-mask#'] = true,
	['editor#-mask'] = true,
	['first#'] = true,
	['given#'] = true,
	['host#'] = true,
	['interviewer#'] = true,
	['interviewer-first#'] = true,
	['interviewer#-first'] = true,
	['interviewer-given#'] = true,
	['interviewer#-given'] = true,
	['interviewer-last#'] = true,
	['interviewer#-last'] = true,
	['interviewer-surname#'] = true,
	['interviewer#-surname'] = true,
	['interviewer-link#'] = true,
	['interviewer#-link'] = true,
	['interviewer-mask#'] = true,
	['interviewer#-mask'] = true,
	['last#'] = true,
	['subject#'] = true,
	['subject-link#'] = true,
	['subject#-link'] = true,
	['subject-mask#'] = true,
	['subject#-mask'] = true,
	['surname#'] = true,
	['translator#'] = true,
	['translator-first#'] = true,
	['translator#-first'] = true,
	['translator-given#'] = true,
	['translator#-given'] = true,
	['translator-last#'] = true,
	['translator#-last'] = true,
	['translator-surname#'] = true,
	['translator#-surname'] = true,
	['translator-link#'] = true,
	['translator#-link'] = true,
	['translator-mask#'] = true,
	['translator#-mask'] = true,
	}


--[[--------------------------< P R E P R I N T   S U P P O R T E D   P A R A M E T E R S >--------------------

Cite arXiv, cite biorxiv, cite citeseerx, and cite ssrn are preprint templates that use the limited set of parameters
defined in the limited_basic_arguments and limited_numbered_arguments tables.  Those lists are supplemented with a
template-specific list of parameters that are required by the particular template and may be exclusive to one of the
preprint templates.  Some of these parameters may also be available to the general cs1|2 templates.

Same conventions for true/false/tracked/nil as above.

]]

local preprint_arguments = {
	arxiv = {
		['arxiv'] = true,														-- cite arxiv and arxiv identifiers
		['class'] = true,
		['eprint'] = true,														-- cite arxiv and arxiv identifiers
		},
	biorxiv = {
		['biorxiv'] = true,
		},
	citeseerx = {
		['citeseerx'] = true,
		},
	ssrn = {
		['ssrn'] = true,
		['SSRN'] = true,
		['ssrn-access'] = true,
		},
	}


--[[--------------------------< L I M I T E D   S U P P O R T E D   P A R A M E T E R S >----------------------

cite arxiv, cite biorxiv, cite citeseerx, and cite ssrn templates are preprint templates so are allowed only a
limited subset of parameters allowed to all other cs1|2 templates.  The limited subset is defined here.

Same conventions for true/false/tracked/nil as above.
	
]]

local limited_basic_arguments = {
	['at'] = true,
	['author'] = true,
	['author-first'] = true,
	['author-given'] = true,
	['author-last'] = true,
	['author-surname'] = true,
	['author-link'] = true,
	['authorlink'] = true,
	['author-mask'] = true,
	['authors'] = true,
	['collaboration'] = true,
	['date'] = true,
	['df'] = true,
	['display-authors'] = true,
	['first'] = true,
	['given'] = true,
	['language'] = true,
	['last'] = true,
	['mode'] = true,
	['name-list-style'] = true,
	['no-tracking'] = true,
	['p'] = true,
	['page'] = true,
	['pages'] = true,
	['postscript'] = true,
	['pp'] = true,
	['quotation'] = true,
	['quote'] = true,
	['ref'] = true,
	['surname'] = true,
	['template-doc-demo'] = true,
	['title'] = true,
	['trans-title'] = true,
	['vauthors'] = true,
	['year'] = true,
	}

local limited_numbered_arguments = {
	['author#'] = true,
	['author-first#'] = true,
	['author#-first'] = true,
	['author-given#'] = true,
	['author#-given'] = true,
	['author-last#'] = true,
	['author#-last'] = true,
	['author-surname#'] = true,
	['author#-surname'] = true,
	['author-link#'] = true,
	['author#-link'] = true,
	['authorlink#'] = true,
	['author#link'] = true,
	['author-mask#'] = true,
	['author#-mask'] = true,
	['first#'] = true,
	['given#'] = true,
	['last#'] = true,
	['surname#'] = true,
	}


--[[--------------------------< U N I Q U E _ A R G U M E N T S >----------------------------------------------

Some templates have unique parameters.  Those templates and their unique parameters are listed here. Keys in this
table are the template's CitationClass parameter value

Same conventions for true/false/tracked/nil as above.

]]

local unique_arguments = {
	['audio-visual'] = {
		['transcript'] = true,
		['transcript-format'] = true,
		['transcript-url'] = true,
		},
	conference = {
		['book-title'] = true,
		['conference'] = true,
		['conference-format'] = true,
		['conference-url'] = true,
		['event'] = true,
		},
	episode = {
		['airdate'] = true,
		['air-date'] = true,
		['credits'] = true,
		['episode-link'] = true,												-- alias of |title-link=
		['network'] = true,
		['season'] = true,
		['series-link'] = true,
		['series-no'] = true,
		['series-number'] = true,
		['station'] = true,
		['transcript'] = true,
		['transcript-format'] = true,
		['transcripturl'] = false,
		['transcript-url'] = true,
		},
	mailinglist = {
		['mailing-list'] = true,
		},
	map = {
		['cartography'] = true,
		['inset'] = true,
		['map'] = true,
		['map-format'] = true,
		['map-url'] = true,
		['map-url-access'] = true,
		['script-map'] = true,
		['sections'] = true,
		['sheet'] = true,
		['sheets'] = true,
		['trans-map'] = true,
		},
	newsgroup = {
		['message-id'] = true,
		['newsgroup'] = true,
		},
	report = {
		['docket'] = true,
		},
	serial = {
		['airdate'] = true,
		['air-date'] = true,
		['credits'] = true,
		['episode'] = true,														-- cite serial only TODO: make available to cite episode?
		['episode-link'] = true,												-- alias of |title-link=
		['network'] = true,
		['series-link'] = true,
		['station'] = true,
		},
	speech = {
		['conference'] = true,
		['conference-format'] = true,
		['conference-url'] = true,
		['event'] = true,
		},
	thesis = {
		['degree'] = true,
		['docket'] = true,
		},
	}


--[[--------------------------< T E M P L A T E _ L I S T _ G E T >--------------------------------------------

gets a list of the templates from table t

]]

local function template_list_get (t)
	local out = {};																-- a table for output
	for k, _ in pairs (t) do													-- spin through the table and collect the keys
		table.insert (out, k)													-- add each key to the output table
	end
	return out;																	-- and done
end


--[[--------------------------< E X P O R T E D   T A B L E S >------------------------------------------------
]]

return {
	basic_arguments = basic_arguments,
	numbered_arguments = numbered_arguments,
	limited_basic_arguments = limited_basic_arguments,
	limited_numbered_arguments = limited_numbered_arguments,

	preprint_arguments = preprint_arguments,
	preprint_template_list = template_list_get (preprint_arguments),			-- make a template list from preprint_arguments{} table
	unique_arguments = unique_arguments,
	unique_param_template_list = template_list_get (unique_arguments),			-- make a template list from unique_arguments{} table
	};
