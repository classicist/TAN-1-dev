<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core tests for class 1 TAN files.</title>
   <let name="leafdiv-flatrefs" value="$prep-body/tan:div/@ref"/>
   <let name="transcription-langs"
      value="/(tan:TAN-T/tan:body|tei:TEI/tei:text/tei:body)//@xml:lang"/>
   <rule context="tan:see-also">
      <let name="first-loc" value="tan:location[doc-available(tan:resolve-url(.,''))][1]"/>
      <let name="first-doc"
         value="if (doc-available($first-loc)) then doc($first-loc) 
         else if (doc-available(concat($doc-parent-directory,$first-loc))) 
         then doc(concat($doc-parent-directory,$first-loc)) else ()"/>
      <let name="is-alternatively-divided-edition" value="tan:relationship = 'alternatively divided edition'"/>
      <let name="is-alternatively-normalized-edition" value="tan:relationship = 'alternatively divided edition'"/>
      <let name="is-strict-alternative" value="$is-alternatively-divided-edition or $is-alternatively-normalized-edition"/>
      <let name="shares-same-source" value="$head/tan:source/tan:IRI = $first-doc/*/tan:head/tan:source/tan:IRI"/>
      <let name="shares-same-work" value="$head/tan:declarations/tan:work/tan:IRI = $first-doc/*/tan:head/tan:declarations/tan:work/tan:IRI"/>
      <let name="shares-same-work-version" value="if ($head/tan:declarations/tan:version/tan:IRI and $first-doc/*/tan:head/tan:declarations/tan:version/tan:IRI) then $head/tan:declarations/tan:version/tan:IRI = $first-doc/*/tan:head/tan:declarations/tan:version/tan:IRI else true()"/>
      <let name="shares-same-language" value="$body/@xml:lang = $first-doc//(tan:body, tei:body)/@xml:lang"/>
      <let name="this-text" value="normalize-space(string-join(//(tan:body, tei:body)//text(),''))"/>
      <let name="alternative-text"
         value="normalize-space(string-join($first-doc//(tan:body, tei:body)//text(),''))"/>
      <let name="is-same-text" value="if ($this-text = $alternative-text) then true() else false()"/>
      <let name="discrepancies-here"
         value="for $i in //(tan:div, tei:div)[not((tan:div, tei:div))] return 
         if (contains($alternative-text,normalize-space(string-join($i//text(),'')))) then () else tan:flatref($i)"/>
      <let name="discrepancies-there"
         value="for $i in $first-doc//(tan:div, tei:div)[not((tan:div, tei:div))] return 
         if (contains($this-text,normalize-space(string-join($i//text(),'')))) then () else tan:flatref($i)"/>
      <report test="$is-strict-alternative and not($shares-same-source)">Alternative editions 
         must share the same source.</report>
      <report test="$is-strict-alternative and not($shares-same-work)">Alternative editions 
         must share the same work.</report>
      <report test="$is-strict-alternative and not($shares-same-work-version)">Alternative editions 
         must share the same work-version.</report>
      <report test="$is-alternatively-divided-edition and not($is-same-text)">Alternatively divided editions
         must treat the identical transcription. <value-of
            select="if (exists($discrepancies-here)) then concat('Discrepancies here: ',string-join(($discrepancies-here),', '),'. ') else ()"
            /><value-of
            select="if (exists($discrepancies-there)) then concat('Discrepancies in alternative edition: ',string-join(($discrepancies-there),', '),'. ') else ()"
         /></report>
   </rule>
   <rule context="tan:recommended-tokenization">
      <let name="this-which" value="@which"/>
      <let name="this-which-is-valid"
         value="if ($this-which = $tokenization-which-reserved)
         then true() else false()"/>
      <let name="this-tokz-loc-urls"
         value="for $i in tan:location/text() return
         if (resolve-uri($i) = $i) then $i else concat($doc-parent-directory,$i)"/>
      <let name="this-tokz-loc-da"
         value="for $i in $this-tokz-loc-urls return if (doc-available($i)) then $i else ()"/>
      <!--<let name="this-tokz-which"
         value="$tokenization-which-reserved-url[index-of($tokenization-which-reserved,$this-which)]"/>-->
      <let name="this-tokz"
         value="if ($this-which-is-valid) then $tokenizations-core[index-of($tokenization-which-reserved,$this-which)] else if (exists($this-tokz-loc-da)) then doc($this-tokz-loc-da[1]) else ()"/>
      <!--<let name="this-tokz" value="doc(($this-tokz-loc-1st-da,'../sch/rules/TAN-R-tok/precise-1.xml')[1])"/>-->
      <!--<let name="this-tokz" value="doc('precise-1.xml')"/>-->
      <!--<let name="this-tokz" value="$tok-test"/>-->
      <let name="this-tokz-replaces" value="$this-tokz//tan:replace"/>
      <let name="this-tokz-tokenize" value="$this-tokz//tan:tokenize"/>
      <let name="this-tokz-fails-modifiers-at-what-div"
         value="if (exists($this-tokz)) then for $i in $prep-body/tan:div return
         if (count(tan:tokenize(tan:replace-sequence(replace($i,'\p{M}',''), $this-tokz-replaces), $this-tokz-tokenize)) =
         count(tan:tokenize(tan:replace-sequence(replace($i,'\p{M}','M'), $this-tokz-replaces), $this-tokz-tokenize))
         ) then () else $i else ()"/>
      <let name="tokz-error-refs"
         value="for $i in $this-tokz-fails-modifiers-at-what-div return $i/@ref"/>
      <let name="tokz-error-vals"
         value="for $i in $this-tokz-fails-modifiers-at-what-div return tan:locate-modifiers($i)"/>
      <report test="exists($this-which) and not($this-which-is-valid)">@which must be one of the
         following: <value-of select="string-join($tokenization-which-reserved,', ')"/></report>
      <report test="exists($this-tokz-fails-modifiers-at-what-div)">This tokenization pattern fails
         to predictably handle the combining characters at <value-of
            select="for $i in (1 to count($tokz-error-refs)) 
            return concat($tokz-error-refs[$i],' ',string-join(for $j in $tokz-error-vals[$i]/tan:modifier return
            concat('pos ',$j/@where,' (U+',$j/@cp,')'),' '))"
         />.</report>
   </rule>
   <rule context="tan:IRI[parent::tan:recommended-tokenization]">
      <let name="this-tokz-loc-urls"
         value="for $i in ../tan:location/text() return
         if (resolve-uri($i) = $i) then $i else concat($doc-parent-directory,$i)"/>
      <let name="this-tokz-loc-da"
         value="for $i in $this-tokz-loc-urls return if (doc-available($i)) then $i else ()"/>
      <!--<let name="tokenization-locations-1st-da" value="../tan:location[doc-available(.)][1]"/>-->
      <let name="tokenization-file" value="doc($this-tokz-loc-da)"/>
      <let name="tokenization-langs"
         value="$tokenization-file/tan:TAN-R-tok/tan:head/tan:declarations/tan:for-lang"/>
      <assert test="name($tokenization-file/*) = 'TAN-R-tok'">Recommended tokenization must point to
         a TAN-R-tok file (currently <value-of select="name($tokenization-file/*)"/>).</assert>
      <report role="warning"
         test="$tokenization-langs and not(every $i in $transcription-langs satisfies index-of($tokenization-langs,$i) > 0)"
         >TAN-R-tok file is language specific, and not every language in the body (<value-of
            select="$transcription-langs"/>) is explicitly provided for in the TAN-R-tok file
            (<value-of select="$tokenization-langs"/>).</report>
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
      <!-- START TESTING BLOCK -->
      <let name="test1" value="false()"/>
      <let name="test2" value="false()"/>
      <let name="test3" value="true()"/>
      <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
            select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
      <!-- END TESTING BLOCK -->
      <report test="if (exists($duplicate-leafdivs)) then true() else false()">Leaf div references
         must be unique. Violations at <value-of select="distinct-values($duplicate-leafdivs)"
         />.</report>
   </rule>
   <rule context="tei:div | tan:div">
      <let name="this-type" value="@type"/>
      <let name="this-n" value="@n"/>
      <let name="is-leaf-div"
         value="if (not(tei:div|tan:div)) then true() else false()"/>
      <report
         test="if ($is-leaf-div) then (preceding-sibling::*, following-sibling::*)[@n=$this-n][@type=$this-type] else false()"
         >Leaf div references must be unique. </report>
      <report test="$is-leaf-div and not(matches(.,'\S'))">Every leaf div must have
         at least some non-space text.</report>
   </rule>
</pattern>
