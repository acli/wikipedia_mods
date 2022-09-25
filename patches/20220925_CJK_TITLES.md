diff --git a/Module/Citation/CS1/Utilities.lua b/Module/Citation/CS1/Utilities.lua
index c4da3dd..8cfde8d 100644
--- a/Module/Citation/CS1/Utilities.lua
+++ b/Module/Citation/CS1/Utilities.lua
@@ -367,6 +367,63 @@ this function is similar to but separate from wrap_msg().
 
 ]]
 
+-- LOCAL: Check if the given string is (believed to be) CJK
+-- copied from Module:書名
+local function cjk_p( s )
+	return mw.ustring.match(s, '^['
+			.. '⺀-䶿'								-- 2E80-4DBF
+			.. '一-鿿'								-- 4E00-9FFF
+			.. '가-힯'								-- AC00-D7AF
+			.. '豈-﫿'								-- F900-FAFF
+			.. '︰-﹏'								-- FE30-FE4F
+			.. '！-｠'								-- FF01-FF60
+			.. '𠀀-𯨟'								-- 20000-2FA1F
+			.. ']+$');
+end
+
+-- check if string is "predominantly" CJK - written specifically for CS1
+-- state diagram:
+--                      ↶ %w
+--                 ___ [2] <———————————.
+--            cjk /   ↗ %w  \ %W       | %w
+--         n₁ ++ |   / n₂++  |         / n₂ ++
+--                ↘ /  %W    ↓        /
+--    [START] ———> [1] ———> [3] —————<
+--         cjk    ↻ cjk  ↖  ↻ %W      | cjk
+--       n₁ ++     n₁ ++  \           | n₁ ++
+--                         `——————————'
+--
+local function predominantly_cjk_p( s )
+	local cjk_count = 0;
+	local non_cjk_count = 0;
+	local state = 0;
+	for i = 1, mw.ustring.len(s), 1 do
+		local c = mw.ustring.sub(s, i, i)
+		local cjk_p = cjk_p(c);
+		local word_p = mw.ustring.match(c, '^%w$');
+		if state == 0 or state == 1 or state == 3 then
+			if cjk_p then
+				state = 1;
+				cjk_count = cjk_count + 1;
+			elseif word_p then
+				state = 2;
+				non_cjk_count = non_cjk_count + 1
+			else
+				state = 3;
+			end
+		elseif state == 2 then
+			if cjk_p then
+				state = 1;
+				cjk_count = cjk_count + 1;
+			elseif not word_p then
+				state = 3;
+			end
+		end
+	end
+	return cjk_count > 0 and cjk_count >= non_cjk_count;
+end
+-- END LOCAL
+
 local function wrap_style (key, str)
 	if not is_set (str) then
 		return "";
@@ -374,6 +431,22 @@ local function wrap_style (key, str)
 		str = safe_for_italics (str);
 	end
 
+	-- LOCAL: CJK titles should never be italicized. Check if str looks CJK
+	local cjk_p = cjk_p(str) or	predominantly_cjk_p(str);
+	if cjk_p then
+		-- It would be ideal to use Module:書名 to format this but
+		-- that does not seem to be possible. Further investigation needed.
+		if in_array (key, {'italic-title', 'trans-italic-title'}) then
+			return '<span class=syu1ming4><span class=hoi1>《</span>'
+					.. str ..
+					'<span class=saan1>》</span></span>'
+		elseif in_array (key, {'quoted-title', 'trans-quoted-title'}) then
+			return '<span class=pin1ming4><span class=hoi1>〈</span>'
+					.. str ..
+					'<span class=saan1>〉</span></span>'
+		end
+	end
+	-- END LOCAL
 	return substitute (cfg.presentation[key], {str});
 end
 
diff --git a/patches/00HISTORY.md b/patches/00HISTORY.md
index 7acf6d1..7fb1c3a 100644
--- a/patches/00HISTORY.md
+++ b/patches/00HISTORY.md
@@ -2,6 +2,11 @@
 <tr><th>Patch<th>Purpose<th>Status
 
 <tr><td scope=row>
+20220925_CJK_TITLES
+<td>Disable italics (and add guillemets) for CJK titles
+<td>Committed to production
+
+<tr><td scope=row>
 20220922_EDITION
 <td>Handle year-based edition numbering
 <td>Committed to production
diff --git a/patches/20220925_CJK_TITLES.md b/patches/20220925_CJK_TITLES.md
new file mode 100644
index 0000000..e69de29
