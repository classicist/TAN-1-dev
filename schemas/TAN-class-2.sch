<?xml version="1.0" encoding="UTF-8"?>
<!-- To do: 
   add rule to <tokenization>: for any tokenization not already recommended by 
a source, run the same test as run on recommended-tokenizations within class 1 validation. 
That is, ensure that tokenization on the source text in both ways of handling modifying 
characters is identical.
   add rule to <tok>: if the value is a question mark provide a list of distinct word tokens that
would be valid, along with the number of times each word appears. Keep it in document order 
(distinct values mean some alteration is necessary). -->

<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Schematron tests for class 2 TAN files.</title>

   <rule context="tan:source">
      <let name="this-pos" value="count(preceding-sibling::tan:source) + 1"/>
      <let name="all-flatrefs" value="$src-1st-da-data[$this-pos]/tan:div[@lang]/@ref"/>
      <let name="ldur-violations"
         value="if (count($all-flatrefs) ne count(distinct-values($all-flatrefs)) ) then true() else false()"/>
      <let name="exists-new-version"
         value="$src-1st-da-heads[$this-pos]/tan:see-also[tan:relationship = 'new version']"/>
      <report test="$ldur-violations">After declarations are applied, source breaks the Leaf Div
         Uniqueness Rule (to diagnose open source and validate)</report>
      <!-- alternative variable and report, very time-consuming for long source documents (n ^ 2 operations) -->
      <!--<let name="ldur-violations"
         value="for $i in $src-1st-da-data[$this-pos]/tan:div[@lang]/@ref return
         if(count($src-1st-da-data[$this-pos]/tan:div[@ref = $i]) gt 1)
         then $i else ()"/>
         <report test="exists($ldur-violations-verbose)">After declarations are applied, source breaks the
         Leaf Div Uniqueness Rule at <value-of select="string-join($ldur-violations-verbose,', ')"/></report>
      -->
      <report test="$exists-new-version" role="warning" sqf:fix="use-new-edition">New version
         exists. IRI: <value-of select="$exists-new-version/tan:IRI"/> Name: <value-of
            select="$exists-new-version/tan:name"/>
         <value-of select="$exists-new-version/tan:desc"/> Location: <value-of
            select="$exists-new-version/tan:location"/></report>
      <sqf:fix id="use-new-edition">
         <sqf:description>
            <sqf:title>Replace with new version</sqf:title>
         </sqf:description>
         <sqf:delete match="child::*"/>
         <sqf:add match="."
            select="$exists-new-version/* except $exists-new-version/tan:relationship"/>
      </sqf:fix>
   </rule>
   <rule context="tan:tokenization">
      <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
      <let name="pos-per-source"
         value="for $i in $this-src-list return count(preceding-sibling::tan:tokenization[$i = tan:src-ids-to-nos(@src)]) + 1"/>
      <let name="error-check"
         value="for $i in $this-src-list return $tokenizations-per-source[$i]/tan:tokenization[$pos-per-source[index-of($this-src-list,$i)]]/tan:location"/>
      <report test="some $i in $error-check satisfies $i = $tokenization-errors">Error: <value-of
            select="for $i in (1 to count($error-check)) return if ($error-check[$i] = $tokenization-errors) then concat($src-ids[$this-src-list[$i]],' : ',$error-check[$i]) else ()"
         />
      </report>
   </rule>
   <rule context="tan:suppress-div-types|tan:div-type-ref|tan:rename-div-ns">
      <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
      <let name="this-div-types" value="tokenize(@div-type-ref,'\s+')"/>
      <let name="src-div-type-mismatch"
         value="for $i in $this-src-list, $j in $this-div-types, $k in ($rename-div-types/tan:src[$i]/tan:rename[@new = $j]/@old,$j)[1] 
         return
         if($src-1st-da-heads[$i]/tan:declarations/tan:div-type[@xml:id = $k])
         then ()
         else concat($src-ids[$i],':',$j)"/>
      <let name="src-div-type-uses-old"
         value="for $i in $this-src-list, $j in $this-div-types, $k in $rename-div-types/tan:src[$i]/tan:rename[@old = $j]
         return concat($src-ids[$i],':',$j)"/>
      <report test="count($src-div-type-mismatch) gt 0">Every div type must refer to a div type id
         in every source (<value-of select="$src-div-type-mismatch"/>).</report>
      <report test="exists($src-div-type-uses-old)">Uses old value, changed by rename element
            (<value-of select="$src-div-type-uses-old"/>).</report>
   </rule>
   <rule context="tan:implicit-div-type-refs">
      <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
      <let name="srcs-without-recommended-div-type-refs"
         value="for $i in $this-src-list return
         if ($src-1st-da-heads[$i]/tan:declarations/tan:recommended-div-type-refs) then () else $i"/>
      <let name="empty-ns"
         value="for $i in $srcs-without-recommended-div-type-refs return
         if (some $j in $src-1st-da-data[$i]//@ref satisfies matches($j,concat($separator-type-and-n-regex,'$|',$separator-hierarchy-regex,$separator-type-and-n-regex))) then $i else ()"/>
      <let name="duplicate-refs"
         value="for $i in $srcs-without-recommended-div-type-refs, $j in distinct-values($src-1st-da-data[$i]/tan:div/@impl-ref) return 
         if (count(distinct-values($src-1st-da-data[$i]/tan:div[@impl-ref = $j]/@ref)) gt 1) then concat($src-ids[$i],': ',replace($j,$separator-hierarchy-regex,' ')) else ()"/>
      <!-- alternative variable, perhaps for large texts -->
      <!--<let name="duplicate-refs"
         value="for $i in $this-src-list return if (count($src-1st-da-data[$i]/tan:div/@impl-ref) ne count(distinct-values($src-1st-da-data[$i]/tan:div/@impl-ref)) ) then $i else ()"/>-->
      <report test="exists($empty-ns)">Implicitation not allowed for sources with empty values for
         @n (<value-of select="for $i in $empty-ns return $src-ids[$i]"/>).</report>
      <report test="exists($duplicate-refs)">Implicitation not allowed for sources where ignoring
         types would result in duplicate flattened references (<value-of
            select="string-join($duplicate-refs,'; ')"/>).</report>
   </rule>
   <rule context="tan:rename-div-types">
      <report role="warning" test="@src = tokenize(../tan:implicit-div-type-refs/@src,'\s+')"
         >Renaming div types for a source where div type references are declared to be implicit has
         no effect.</report>
   </rule>
   <rule context="tan:rename[parent::tan:rename-div-types]">
      <let name="this-src-list" value="tan:src-ids-to-nos(../@src)"/>
      <let name="this-div-type" value="@old"/>
      <assert
         test="every $i in $this-src-list satisfies $src-1st-da-heads[$i]//tan:div-type[@xml:id=$this-div-type]"
         >Every div type must be found in every source.</assert>
   </rule>
   <rule context="tan:rename[parent::tan:rename-div-ns]">
      <let name="this-src-list" value="tan:src-ids-to-nos(../@src)"/>
      <let name="this-div-type-list" value="tokenize(../@div-type-ref,'\s+')"/>
      <let name="this-div-type-list-orig"
         value="for $i in $this-src-list return string-join(for $j in $this-div-type-list return 
         ($head/tan:declarations/tan:rename-div-types[tan:src-ids-to-nos(@src) = $i]/tan:rename[@new = $j]/@old,$j)[1],' ')"/>
      <let name="this-div-type-list-orig-as-regex"
         value="for $i in $this-div-type-list-orig return concat('(',replace($i,' ','|'),')')"/>
      <let name="this-div-n" value="@old"/>
      <let name="this-div-type-ord-check"
         value="for $i in (1 to count($this-src-list)) return 
         $div-type-ord-check/tan:source[position() = $this-src-list[$i]]/tan:div-type[@id = tokenize($this-div-type-list-orig[$i],' ')]"/>
      <let name="ns-are-type-i"
         value="every $i in $this-div-type-ord-check satisfies $i/@type = 'i'"/>
      <let name="ns-are-type-a"
         value="every $i in $this-div-type-ord-check satisfies $i/@type = 'a'"/>
      <let name="ns-are-what-type"
         value="for $i in $this-div-type-ord-check/@type return $n-type-label[index-of($n-type,$i)]"/>
      <assert
         test="if (matches($this-div-n,'#')) then true() else
         every $i in (1 to count($this-src-list)) satisfies $src-1st-da-data[$this-src-list[$i]]//tan:div[matches(@old-ref,concat(
         $this-div-type-list-orig-as-regex[$i],
         $separator-type-and-n-regex,
         $this-div-n,
         $separator-hierarchy-regex,
         '|',$this-div-type-list-orig-as-regex[$i],
         $separator-type-and-n-regex,
         $this-div-n,
         '$'))]"
         >Every n value must be found in at least one div type in every source.</assert>
      <assert test="matches(@old,'#') = matches(@new,'#')">If a numeration system is to be renamed,
         a numeration system pattern (#a, #i, or #1) must appear in both @old and @new</assert>
      <report test="@old = @new">@old and @new may not take the same value</report>
      <assert test="if (@old = '#a') then ($ns-are-type-a) else true()">Div types for each source
         must be predominantly letter numerals (currently <value-of select="string-join($ns-are-what-type,', ')"
         />)</assert>
      <assert test="if (@old = '#i') then ($ns-are-type-a) else true()">Div types for each source
         must be predominantly Roman numerals (currently <value-of select="string-join($ns-are-what-type,', ')"
         />)</assert>
   </rule>
   <rule context="@ref">
      <let name="these-refs" value="normalize-space(.)"/>
      <let name="ref-range-must-join-siblings"
         value="if (../parent::tan:realign or ../..[@distribute = true()] or ../..[@xml:id]) then true() else false()"/>
      <report
         test="$ref-range-must-join-siblings and (some $i in tan:ref-range-check(.) satisfies $i = false())"
         >In any @ref whose values might be distributed, every range (references joined by a hyphen)
         must begin and end with siblings.</report>
   </rule>
   <rule context="tan:tok">
      <let name="src-data-for-this-tok" value="tan:pick-tokenized-prepped-class-1-data(.)"/>
      <let name="token-ceiling"
         value="min(for $i in $src-data-for-this-tok/tan:div return number($i/@max-toks))"/>
      <let name="char-ceiling"
         value="min(for $i in $src-data-for-this-tok//tan:tok return string-length($i))"/>
      <let name="this-chars"
         value="if (@chars) then normalize-space(replace(@chars,'\?','')) else ()"/>
      <let name="this-char-max"
         value="if (exists($this-chars)) then tan:max-integer($this-chars) else 1"/>
      <let name="this-char-min-last"
         value="if (exists($this-chars) and exists($char-ceiling)) then tan:min-last($this-chars,$char-ceiling) else 1"/>
      <let name="this-src-qty-with-implicit-div-types"
         value="count($src-data-for-this-tok[position() = $src-impl-div-types][tan:div])"/>
      <let name="src-data-for-sibling-toks"
         value="for $i in (preceding-sibling::tan:tok, following-sibling::tan:tok) 
         return tan:pick-tokenized-prepped-class-1-data($i)"/>
      <let name="duplicate-tokens"
         value="for $i in $src-data-for-this-tok//tan:tok, 
         $j in $src-data-for-sibling-toks//tan:tok return
         if (deep-equal($i,$j)) then 
         if ($i/../@ref = $j/../@ref and $i/../../@id = $j/../../@id) then true() else () 
         else ()"/>
      <!-- START TESTING BLOCK -->
      <let name="test1" value="$src-data-for-this-tok"/>
      <let name="test2" value="true()"/>
      <let name="test3" value="true()"/>
      <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
            select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
      <!-- END TESTING BLOCK -->
      <report test="exists($duplicate-tokens)">Sibling tok elements may not point to the same
         token.</report>
      <report test="$src-data-for-this-tok/tan:div/@error">Every ref cited must be found in every
         source (<value-of
            select="for $i in $src-data-for-this-tok/tan:div[@error] return concat($i/../@id,': ',$i/@ref)"
         />).</report>
      <report test="some $i in $src-data-for-this-tok/tan:div satisfies $i = $tokenization-errors"
         >Tokenization error (<value-of
            select="for $i in $src-data-for-this-tok/tan:div[. = $tokenization-errors] return concat($i/@ref,': ',$i/@lang)"
         />)</report>
      <report test="not(@ord or @val)">tok must point to a string value, a sequence, or
         both.</report>
      <report test="$src-data-for-this-tok/tan:div/tan:tok[@error]">Every token picked must appear
         in every ref in every source<value-of
            select="if (tokenize(@val,'\s+') = 'last') then ' (&quot;last&quot; 
            usually goes with the attribute @ord, not @val)' else ()"
         />. Errors: <value-of
            select="for $i in $src-data-for-this-tok/tan:div[tan:tok[@error]] return 
            concat($i/../@id,':',$i/@ref,' : ',string-join($i/tan:tok/@error,' '))"
         /></report>
      <report
         test="if (exists($this-chars)) then ($this-char-max gt $char-ceiling) or ($this-char-min-last lt 1) 
         else false()"
         >Every character cited must appear in every token in every ref in every source (tokens
         chosen have <value-of select="$char-ceiling"/> characters max)</report>
      <report test="$src-data-for-this-tok/tan:div[not(@lang)]">Every tok must point to a leaf div
            (<value-of
            select="string-join(for $i in $src-data-for-this-tok/tan:div[not(@lang)] return concat($i/../@id,':',$i/@ref),', ')"
         />)</report>
      <report test="matches(@ord,'\?')" role="warning">Acceptable values 1 through <value-of
            select="$token-ceiling"/></report>
      <report test="matches(@chars,'\?')" role="warning">Acceptable values 1 through <value-of
            select="$char-ceiling"/></report>
      <report
         test="$this-src-qty-with-implicit-div-types gt 0 and 
         $this-src-qty-with-implicit-div-types ne count(tan:src-ids-to-nos(@src))"
         >Either all or none of the sources mentioned in @src should be declared in
         implicit-div-type-refs (<value-of select="$this-src-qty-with-implicit-div-types"/>,
            <value-of select="count(tan:src-ids-to-nos(@src))"/>)</report>
      <report
         test="$src-data-for-this-tok//tan:tok[@n='1'][not(@error)] and parent::tan:split-leaf-div-at"
         >No leaf div may be split at the first token.</report>
   </rule>

</pattern>
