<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core tests for class 1 TAN files.</title>
   <let name="leafdiv-flatrefs" value="$prep-body/tan:div/@ref"/>
   <let name="transcription-langs"
      value="/(tan:TAN-T/tan:body|tei:TEI/tei:text/tei:body)//@xml:lang"/>
   <!-- number of leafdivs allowed before enforcement of the Leaf Div Uniqueness Rule occurs at body instead of individual leaf divs -->
   <let name="too-many-leafdivs" value="if (count($prep-body/*) ge 400) then true() else false()"/>
   <rule context="tan:see-also">
      <let name="first-loc" value="tan:location[doc-available(tan:resolve-url(.))][1]"/>
      <let name="first-doc"
         value="if (doc-available($first-loc)) then doc($first-loc) 
         else if (doc-available(concat($doc-parent-directory,$first-loc))) 
         then doc(concat($doc-parent-directory,$first-loc)) else ()"/>
      <let name="is-same-source-work-and-version"
         value="if (tan:relationship = 'alternative edition' and 
         /*/tan:head/tan:source/tan:IRI = $first-doc/*/tan:head/tan:source/tan:IRI and 
         /*/tan:head/tan:declarations/tan:work/tan:IRI = $first-doc/*/tan:head/tan:declarations/tan:work/tan:IRI and 
         (if (/*/tan:head/tan:declarations/tan:version/tan:IRI and $first-doc/*/tan:head/tan:declarations/tan:work/tan:IRI) 
            then /*/tan:head/tan:declarations/tan:version/tan:IRI and $first-doc/*/tan:head/tan:declarations/tan:work/tan:IRI 
            else //tan:body/@xml:lang = $first-doc//tan:body/@xml:lang)) 
         then true() else false()"/>
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
      <report test="$is-same-source-work-and-version and not($is-same-text)">Alternative edition
         claims to be the same source, work, and version, yet text differs. <value-of
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
      <!-- START TESTING BLOCK -->
      <let name="test1" value="base-uri($this-tokz)"/>
      <let name="test2" value="$doc-parent-directory"/>
      <let name="test3" value="true()"/>
      <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
            select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
      <!-- END TESTING BLOCK -->
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
   <rule context="tan:body|tei:body">
      <let name="duplicate-leafdivs"
         value="for $i in $leafdiv-flatrefs return
         if (count(index-of($leafdiv-flatrefs,$i)) gt 1) then $i else ()"/>
      <report
         test="if ($too-many-leafdivs)
         then if (exists($duplicate-leafdivs)) then true() else false() 
         else false()"
         >Canonical references must be unique. Violations at <value-of
            select="distinct-values($duplicate-leafdivs)"/>. (Reported at body for computational
         efficiency.) </report>
   </rule>
   <rule context="tei:div | tan:div">
      <let name="node-ref" value="tan:flatref(.)"/>
      <let name="is-leaf-div"
         value="if (not(descendant::tei:div|descendant::tan:div)) then true() else false()"/>
      <report
         test="if ($too-many-leafdivs) then false() else count(index-of($leafdiv-flatrefs,$node-ref)) > 1"
         >Canonical references must be unique. </report>
      <report
         test="if ($is-leaf-div) then 
         if (string-length(normalize-space(string-join(//text(),''))) = 0) then true() else false()
         else false()"
         >A leaf div should not be empty.</report>
   </rule>
   <rule context="*[ancestor::tei:div[not(descendant::tei:div)]]" role="warning">
      <report test="@xml:lang" sqf:fix="remove-xmllang">Language differentiations below leaf div
         level may be ignored in alignments.</report>
      <sqf:fix id="remove-xmllang">
         <sqf:description>
            <sqf:title>Remove @xml:lang</sqf:title>
         </sqf:description>
         <sqf:replace match="@xml:lang"/>
      </sqf:fix>
   </rule>
</pattern>
