<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core tests for class 1 TAN files.</title>
   <let name="leafdiv-flatrefs" value="$prep-body/tan:div/@ref"/>
   <let name="transcription-langs" value="$prep-body//@xml:lang"/>
   <let name="divs-with-modifiers" value="$prep-body/tan:div[matches(.,'\p{M}')]"></let>
   <let name="relevant-tokz" value="$rec-tokz-1st-da-resolved[.//tan:tokenize]"/>
   <let name="modifier-check-1"
      value="for $i in $divs-with-modifiers, $j in $relevant-tokz return
      count(tan:tokenize(tan:replace-sequence(replace($i,'\p{M}',''), $j//tan:replace), $j//tan:tokenize))
      "/>
   <let name="modifier-check-2"
      value="for $i in $divs-with-modifiers, $j in $relevant-tokz return
      count(tan:tokenize(tan:replace-sequence(replace($i,'\p{M}','M'), $j//tan:replace), $j//tan:tokenize))
      "/>
   <let name="this-tokz-fails-modifiers-at-what-div" value="for $i in (1 to count($modifier-check-1))
      return
      if ($modifier-check-1[$i] = $modifier-check-2[$i]) then () else $divs-with-modifiers[$i mod count($relevant-tokz)]"/>
   <let name="tokz-error-refs"
      value="for $i in $this-tokz-fails-modifiers-at-what-div return $i/@ref"/>
   <let name="tokz-error-vals"
      value="for $i in $this-tokz-fails-modifiers-at-what-div return tan:locate-modifiers($i)"/>
   <rule context="tan:see-also">
      <let name="this-resolved" value="tan:resolve-include(.)"/>
      <let name="first-locs" value="for $i in $this-resolved return tan:first-loc-available($i)/@href"/>
      <let name="first-docs" value="for $i in $first-locs return doc(resolve-uri($i,$doc-uri))"/>
      <let name="is-alternatively-divided-edition"
         value="for $i in $this-resolved return $i/tan:relationship = 'alternatively divided edition'"/>
      <let name="is-alternatively-normalized-edition"
         value="for $i in $this-resolved return $i/tan:relationship = 'alternatively normalized edition'"/>
      <let name="is-strict-alternative"
         value="for $i in count($this-resolved) return ($is-alternatively-divided-edition[$i] or $is-alternatively-normalized-edition[$i])"/>
      <let name="shares-same-source"
         value="for $i in count($this-resolved) return $head/tan:source/tan:IRI = $first-docs[$i]/*/tan:head/tan:source/tan:IRI"/>
      <let name="shares-same-work"
         value="for $i in count($this-resolved) return $head/tan:declarations/tan:work/tan:IRI = $first-docs[$i]/*/tan:head/tan:declarations/tan:work/tan:IRI"/>
      <let name="shares-same-work-version"
         value="for $i in count($this-resolved) return if ($head/tan:declarations/tan:version/tan:IRI and $first-docs[$i]/*/tan:head/tan:declarations/tan:version/tan:IRI) then $head/tan:declarations/tan:version/tan:IRI = $first-docs[$i]/*/tan:head/tan:declarations/tan:version/tan:IRI else true()"/>
      <let name="shares-same-language"
         value="for $i in count($this-resolved) return $body/@xml:lang = $first-docs[$i]//(tan:body, tei:body)/@xml:lang"/>
      <let name="this-text" value="normalize-space(string-join($body//text(),''))"/>
      <let name="resolved-bodies" value="for $i in $first-docs/(tan:TAN-T/tan:body) return tan:resolve-element($i)"/>
      <let name="alternative-text"
         value="for $i in $resolved-bodies return normalize-space(string-join($i//text(),''))"/>
      <let name="is-same-text" value="for $i in count($this-resolved) return if ($this-text = $alternative-text[$i]) then true() else false()"/>
      <let name="discrepancies-here"
         value="for $i in count($this-resolved) return string-join(for $j in //(tan:div, tei:div)[not((tan:div, tei:div))] return 
         if (contains($alternative-text[$i],normalize-space(string-join($j//text(),'')))) then () else tan:flatref($j),', ')"/>
      <let name="discrepancies-there"
         value="for $i in count($this-resolved) return string-join(for $j in $first-docs[$i]//(tan:div, tei:div)[not((tan:div, tei:div))] return 
         if (contains($this-text,normalize-space(string-join($j//text(),'')))) then () else tan:flatref($j),', ')"/>
      <report test="for $i in count($this-resolved) return $is-strict-alternative[$i] and not($shares-same-source[$i])">In class 1 files, alternative editions must
         share the same source.</report>
      <report test="for $i in count($this-resolved) return $is-strict-alternative[$i] and not($shares-same-work[$i])">In class 1 files, alternative editions must
         share the same work.</report>
      <report test="for $i in count($this-resolved) return $is-strict-alternative[$i] and not($shares-same-work-version[$i])">In class 1 files, alternative editions
         must share the same work-version.</report>
      <report test="for $i in count($this-resolved) return $is-alternatively-divided-edition[$i] and not($is-same-text[$i])">In class 1 files, alternatively divided
         editions must preserve identical transcriptions. <value-of select="true()"/> <value-of
            select="if (exists($discrepancies-here)) then concat('Discrepancies here: ',string-join(($discrepancies-here),', '),'. ') else ()"
            /><value-of
            select="if (exists($discrepancies-there)) then concat('Discrepancies in alternative edition: ',string-join(($discrepancies-there),', '),'. ') else ()"
         /></report>
   </rule>
   <rule context="tan:work">
      <report test="$head/tan:declarations/tan:work[2]">There may be no more than one work
         element.</report>
      <!-- unclear why we need this next report; not deleting until it can be determined that it's already covered with tests on @include -->
      <!--<report test="$head/tan:declarations/tan:work/@error" >Error: <value-of
            select="string-join(for $i in $head/tan:declarations/tan:work/@error
         return $inclusion-errors[number($i)],', ')"
         /></report>-->
   </rule>
   <rule context="tan:div-type">
      <let name="escaped-which" value="tan:escape(@which)"/>
      <let name="close-matches-to-which" value="$div-type-keywords[matches(.,$escaped-which)]"/>
      <assert sqf:fix="get-first-keyword get-all-keywords"
         test="
            if (@which) then
               @which = $div-type-keywords
            else
               true()"
         >@which must point to a reserved keyword (try: <value-of select="$close-matches-to-which"
         />)</assert>
      <sqf:fix id="get-first-keyword">
         <sqf:description>
            <sqf:title>Get first valid keyword</sqf:title>
         </sqf:description>
         <sqf:replace match="@which" node-type="attribute" target="which"
            select="$close-matches-to-which[1]"/>
      </sqf:fix>
      <sqf:fix id="get-all-keywords">
         <sqf:description>
            <sqf:title>Get all valid keywords</sqf:title>
         </sqf:description>
         <sqf:replace match="@which" node-type="attribute" target="which"
            select="string-join($close-matches-to-which,' ')"/>
      </sqf:fix>
   </rule>
   <rule context="tan:recommended-tokenization">
      <let name="this-resolved" value="tan:resolve-include(.)"/>
      <let name="this-count" value="(1 to count($this-resolved))"/>
      <let name="this-which-is-reserved"
         value="for $i in $this-resolved return if ($i/@which = $tokenization-which-reserved) then true() else false()"/>
      <let name="tokz-mismatch-1" value="for $i in $recommended-tokenizations[tan:for-lang] return 
         if ($i/tan:for-lang = '*' or $i/tan:for-lang = $languages-used) then () else $i"/>
      <!-- START TESTING BLOCK -->
      <let name="test1" value="count($divs-with-modifiers)"/>
      <let name="test2" value="$modifier-check-1"/>
      <let name="test3" value="$modifier-check-2"/>
      <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
            select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
      <!-- END TESTING BLOCK -->
      <report
         test="some $i in $this-count satisfies $this-resolved[$i]/@which and $this-which-is-reserved[$i] = false()"
         >@which may take only one of the reserved tokenization names (<value-of
            select="string-join($tokenization-which-reserved,', ')"/>)</report>
      <report test="some $i in $this-count satisfies $this-resolved[$i]/@xml:id = $tokenization-which-reserved">@xml:id values may not use a reserved
         tokenization name</report>
      <assert test="every $i in $rec-tokz-1st-da satisfies name($i/*) = 'TAN-R-tok'">Recommended
         tokenization must point to a TAN-R-tok file. <xsl:value-of select='$recommended-tokenizations'></xsl:value-of></assert>
      <report role="warning" test="exists($tokz-mismatch-1)">If pointing to a TAN-R-tok file meant for specific
         languages, at least one of them must be used in the body of the transcription (tokenization languages: 
         <value-of select="$tokz-mismatch-1/tan:for-lang"/>; languages used: <value-of select="$languages-used"/>).</report>
      <report
         test="not('*' = $recommended-tokenizations/tan:for-lang) and $languages-used[not(. = $recommended-tokenizations/tan:for-lang)]"
         >Every language used in the transcription must be accommodated by at least one recommended
         tokenization patterns (unsupported: <value-of
            select="$transcription-langs[not(. = $recommended-tokenizations/tan:for-lang)]"/>;
         currently supported: <value-of select="$recommended-tokenizations/tan:for-lang"
         />).</report>
      <report test="exists($this-tokz-fails-modifiers-at-what-div)">Tokenization patterns must be able to predictably handle any combining characters (error at <value-of
            select="for $i in (1 to count($tokz-error-refs)) 
            return concat($tokz-error-refs[$i],' ',string-join(for $j in $tokz-error-vals[$i]/tan:modifier return
            concat('pos ',$j/@where,' (U+',$j/@cp,')'),' '))"
         />)</report>
   </rule>
   <rule context="tan:recommended-div-type-refs">
      <let name="implicit-is-recommended" value="if (. = 'implicit') then true() else false()"/>
      <let name="divs-with-empty-ns"
         value="for $i in //(tan:div, tei:div)[@n=''] return tan:flatref($i)"/>
      <let name="all-implicit-refs" value="$prep-body/tan:div/@impl-ref"/>
      <let name="duplicate-implicit-refs"
         value="$all-implicit-refs[index-of($all-implicit-refs,.)[2]]"/>
      <report test="$implicit-is-recommended and exists($divs-with-empty-ns)">Implicit div refs
         cannot be recommended if any @n have empty values (<value-of select="$divs-with-empty-ns"
         />). </report>
      <report test="$implicit-is-recommended and exists($duplicate-implicit-refs)">Implicit div refs
         cannot be recommended if any flattened refs result in duplicates (<value-of
            select="string-join($prep-body/tan:div[@impl-ref = $duplicate-implicit-refs]/@ref,', ')"
         /> would equally resolve to <value-of select="$duplicate-implicit-refs"/>). </report>
   </rule>
   <rule context="tan:body|tei:body">
      <let name="duplicate-leafdivs" value="$leafdiv-flatrefs[index-of($leafdiv-flatrefs,.)[2]]"/>
      <report test="if (exists($duplicate-leafdivs)) then true() else false()">In class 1 files, leaf div references
         must be unique (violations at <value-of select="distinct-values($duplicate-leafdivs)"
         />)</report>
   </rule>
   <rule context="tei:div | tan:div">
      <let name="this-type" value="@type"/>
      <let name="this-n" value="@n"/>
      <let name="is-leaf-div" value="if (not(tei:div|tan:div)) then true() else false()"/>
      <report
         test="if ($is-leaf-div) then (preceding-sibling::*, following-sibling::*)[@n=$this-n][@type=$this-type] else false()"
         >Leaf div references must be unique. </report>
      <report test="$is-leaf-div and not(@include) and not(matches(.,'\S'))">Every leaf div must
         have at least some non-space text.</report>
   </rule>
</pattern>
