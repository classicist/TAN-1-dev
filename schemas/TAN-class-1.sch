<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core tests for class 1 TAN files.</title>
   <let name="leafdiv-flatrefs" value="$prep-body/tan:div/@ref"/>
   <let name="transcription-langs" value="$prep-body//@xml:lang"/>
   <rule context="tan:see-also">
      <let name="this-resolved" value="tan:resolve-include(.)"/>
      <let name="first-locs" value="for $i in $this-resolved return tan:first-loc-available($i)"/>
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
      <report test="for $i in count($this-resolved) return $is-strict-alternative[$i] and not($shares-same-source[$i])">Alternative editions must
         share the same source.</report>
      <report test="for $i in count($this-resolved) return $is-strict-alternative[$i] and not($shares-same-work[$i])">Alternative editions must
         share the same work.</report>
      <report test="for $i in count($this-resolved) return $is-strict-alternative[$i] and not($shares-same-work-version[$i])">Alternative editions
         must share the same work-version.</report>
      <report test="for $i in count($this-resolved) return $is-alternatively-divided-edition[$i] and not($is-same-text[$i])">Alternatively divided
         editions must treat the identical transcription. <value-of select="true()"/> <value-of
            select="if (exists($discrepancies-here)) then concat('Discrepancies here: ',string-join(($discrepancies-here),', '),'. ') else ()"
            /><value-of
            select="if (exists($discrepancies-there)) then concat('Discrepancies in alternative edition: ',string-join(($discrepancies-there),', '),'. ') else ()"
         /></report>
   </rule>
   <rule context="tan:work">
      <report test="$head/tan:declarations/tan:work[2]">There may be no more than two work
         elements.</report>
      <report test="$head/tan:declarations/tan:work/@error">Error: <value-of
            select="string-join(for $i in $head/tan:declarations/tan:work/@error
         return $inclusion-errors[number($i)],', ')"
         /></report>
   </rule>
   <rule context="tan:recommended-tokenization">
      <let name="this-which" value="@which"/>
      <let name="this-which-is-reserved"
         value="if ($this-which = $tokenization-which-reserved) then true() else false()"/>
      <let name="first-tokz-loc" value="tan:location[doc-available(resolve-uri(.,$doc-uri))][1]"/>
      <let name="first-tokz-loc-resolved"
         value="if (exists($first-tokz-loc)) 
         then resolve-uri($first-tokz-loc,$doc-uri) else ()"/>
      <let name="this-tokz"
         value="if ($this-which-is-reserved) then $tokenizations-core[index-of($tokenization-which-reserved,$this-which)] else 
         if (exists($first-tokz-loc-resolved)) then doc($first-tokz-loc-resolved) else ()"/>
      <let name="this-tokz-replaces" value="$this-tokz//tan:replace"/>
      <let name="this-tokz-tokenize" value="$this-tokz//tan:tokenize"/>
      <let name="this-tokz-fails-modifiers-at-what-div"
         value="if (exists($this-tokz)) then for $i in $prep-body/tan:div[matches(.,'\p{M}')] return
         if (count(tan:tokenize(tan:replace-sequence(replace($i,'\p{M}',''), $this-tokz-replaces), $this-tokz-tokenize)) =
         count(tan:tokenize(tan:replace-sequence(replace($i,'\p{M}','M'), $this-tokz-replaces), $this-tokz-tokenize))
         ) then () else $i else ()"/>
      <let name="tokz-error-refs"
         value="for $i in $this-tokz-fails-modifiers-at-what-div return $i/@ref"/>
      <let name="tokz-error-vals"
         value="for $i in $this-tokz-fails-modifiers-at-what-div return tan:locate-modifiers($i)"/>
      <let name="tokenization-langs"
         value="$this-tokz/tan:TAN-R-tok/tan:head/tan:declarations/tan:for-lang"/>
      <!-- START TESTING BLOCK -->
      <let name="test1" value="$transcription-langs"/>
      <let name="test2" value="$tokenization-langs"/>
      <let name="test3" value="$recommended-tokenizations/tan:for-lang"/>
      <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
            select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
      <!-- END TESTING BLOCK -->
      <report test="exists($this-which) and not($this-which-is-reserved)">@which must be one of the
         following: <value-of select="string-join($tokenization-which-reserved,', ')"/></report>
      <report test="exists($this-tokz-fails-modifiers-at-what-div)">This tokenization pattern fails
         to predictably handle the combining characters at <value-of
            select="for $i in (1 to count($tokz-error-refs)) 
            return concat($tokz-error-refs[$i],' ',string-join(for $j in $tokz-error-vals[$i]/tan:modifier return
            concat('pos ',$j/@where,' (U+',$j/@cp,')'),' '))"
         />.</report>
      <report test="@xml:id = $tokenization-which-reserved">@xml:id values may not use a reserved
         keyword for tokenization.</report>
      <assert test="every $i in $this-tokz satisfies name($i/*) = 'TAN-R-tok'">Recommended
         tokenization must point to a TAN-R-tok file (currently <value-of
            select="name($this-tokz/*)"/>)</assert>
      <report role="warning"
         test="exists($tokenization-langs) and not($tokenization-langs = $transcription-langs)"
         >TAN-R-tok file is meant for specific languages (<value-of select="$tokenization-langs"/>),
         none of which are used in the body (<value-of select="$transcription-langs"/>).</report>
      <report
         test="not('*' = $recommended-tokenizations/tan:for-lang) and $transcription-langs[not(. = $recommended-tokenizations/tan:for-lang)]"
         >Some languages used in the transcription (<value-of
            select="$transcription-langs[not(. = $recommended-tokenizations/tan:for-lang)]"/>) have
         not been supplied recommended tokenization patterns (currently supported: <value-of
            select="$recommended-tokenizations/tan:for-lang"/>).</report>
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
      <report test="if (exists($duplicate-leafdivs)) then true() else false()">Leaf div references
         must be unique. Violations at <value-of select="distinct-values($duplicate-leafdivs)"
         />.</report>
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
