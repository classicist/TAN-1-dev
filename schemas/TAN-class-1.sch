<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core tests for class 1 TAN files.</title>
   <let name="leafdiv-flatrefs" value="$prep-body/tan:div/@ref"/>
   <let name="transcription-langs" value="$prep-body//@xml:lang"/>
   <let name="div-types" value="$head/tan:declarations/tan:div-type/@xml:id"/>
   <let name="self-is-flat" value="tan:is-flat-class-1(/)"/>
   <rule context="tan:see-also">
      <let name="this-resolved" value="tan:resolve-include(.)"/>
      <let name="first-locs"
         value="
            for $i in $this-resolved
            return
               tan:first-loc-available($i)"/>
      <let name="first-docs"
         value="
            for $i in $first-locs
            return
               doc(resolve-uri($i, $doc-uri))"/>
      <let name="is-alternatively-divided-edition"
         value="
            for $i in $this-resolved
            return
               $i/tan:relationship/@which = 'alternatively divided edition'"/>
      <let name="is-alternatively-normalized-edition"
         value="
            for $i in $this-resolved
            return
               $i/tan:relationship/@which = 'alternatively normalized edition'"/>
      <let name="is-strict-alternative"
         value="
            for $i in count($this-resolved)
            return
               ($is-alternatively-divided-edition[$i] or $is-alternatively-normalized-edition[$i])"/>
      <let name="shares-same-source"
         value="
            for $i in count($this-resolved)
            return
               $head/tan:source/tan:IRI = $first-docs[$i]/*/tan:head/tan:source/tan:IRI"/>
      <let name="shares-same-work"
         value="
            for $i in count($this-resolved)
            return
               $head/tan:declarations/tan:work/tan:IRI = $first-docs[$i]/*/tan:head/tan:declarations/tan:work/tan:IRI"/>
      <let name="shares-same-work-version"
         value="
            for $i in count($this-resolved)
            return
               if ($head/tan:declarations/tan:version/tan:IRI and $first-docs[$i]/*/tan:head/tan:declarations/tan:version/tan:IRI) then
                  $head/tan:declarations/tan:version/tan:IRI = $first-docs[$i]/*/tan:head/tan:declarations/tan:version/tan:IRI
               else
                  true()"/>
      <let name="shares-same-language"
         value="
            for $i in count($this-resolved)
            return
               $body/@xml:lang = $first-docs[$i]//(tan:body, tei:body)/@xml:lang"/>
      <let name="this-text" value="normalize-space(string-join($body//text(), ''))"/>
      <let name="resolved-bodies"
         value="
            for $i in $first-docs/(tan:TAN-T/tan:body)
            return
               tan:resolve-element($i)"/>
      <let name="alternative-text"
         value="
            for $i in $resolved-bodies
            return
               normalize-space(string-join($i//text(), ''))"/>
      <let name="is-same-text"
         value="
            for $i in count($this-resolved)
            return
               if ($this-text = $alternative-text[$i]) then
                  true()
               else
                  false()"/>
      <let name="discrepancies-here"
         value="
            for $i in count($this-resolved)
            return
               string-join(for $j in //(tan:div, tei:div)[not((tan:div, tei:div))]
               return
                  if (contains($alternative-text[$i], normalize-space(string-join($j//text(), '')))) then
                     ()
                  else
                     tan:flatref($j), ', ')"/>
      <let name="discrepancies-there"
         value="
            for $i in count($this-resolved)
            return
               string-join(for $j in $first-docs[$i]//(tan:div, tei:div)[not((tan:div, tei:div))]
               return
                  if (contains($this-text, normalize-space(string-join($j//text(), '')))) then
                     ()
                  else
                     tan:flatref($j), ', ')"/>
      <report
         test="
            for $i in count($this-resolved)
            return
               $is-strict-alternative[$i] and not($shares-same-source[$i])"
         >In class 1 files, alternative editions must share the same source.</report>
      <report
         test="
            for $i in count($this-resolved)
            return
               $is-strict-alternative[$i] and not($shares-same-work[$i])"
         >In class 1 files, alternative editions must share the same work.</report>
      <report
         test="
            for $i in count($this-resolved)
            return
               $is-strict-alternative[$i] and not($shares-same-work-version[$i])"
         >In class 1 files, alternative editions must share the same work-version.</report>
      <report
         test="
            for $i in count($this-resolved)
            return
               $is-alternatively-divided-edition[$i] and not($is-same-text[$i])"
         >In class 1 files, alternatively divided editions must preserve identical transcriptions.
            <value-of
            select="
               if (exists($discrepancies-here)) then
                  concat('Discrepancies here: ', string-join(($discrepancies-here), ', '), '. ')
               else
                  ()"
            /><value-of
            select="
               if (exists($discrepancies-there)) then
                  concat('Discrepancies in alternative edition: ', string-join(($discrepancies-there), ', '), '. ')
               else
                  ()"
         /></report>
   </rule>
   <rule context="tan:work">
      <report test="count(tokenize(@include, '\s+')) gt 1">No more than one inclusion may be
         invoked.</report>
   </rule>
   <rule context="tan:recommended-div-type-refs">
      <let name="implicit-is-recommended"
         value="
            if (. = 'implicit') then
               true()
            else
               false()"/>
      <let name="divs-with-empty-ns"
         value="
            for $i in //(tan:div, tei:div)[@n = '']
            return
               tan:flatref($i)"/>
      <let name="all-implicit-refs" value="$prep-body/tan:div/@impl-ref"/>
      <let name="duplicate-implicit-refs"
         value="$all-implicit-refs[index-of($all-implicit-refs, .)[2]]"/>
      <report test="$implicit-is-recommended and exists($divs-with-empty-ns)">Implicit div refs
         cannot be recommended if any @n have empty values (<value-of select="$divs-with-empty-ns"
         />). </report>
      <report test="$implicit-is-recommended and exists($duplicate-implicit-refs)">Implicit div refs
         cannot be recommended if any flattened refs result in duplicates (<value-of
            select="string-join($prep-body/tan:div[@impl-ref = $duplicate-implicit-refs]/@ref, ', ')"
         /> would equally resolve to <value-of select="$duplicate-implicit-refs"/>). </report>
   </rule>
   <rule context="tan:body | tei:body">
      <let name="duplicate-leafdivs" value="$leafdiv-flatrefs[index-of($leafdiv-flatrefs, .)[2]]"/>
      <report tan:does-not-apply-to="body"
         test="
            if (exists($duplicate-leafdivs)) then
               true()
            else
               false()"
         >In class 1 files, leaf div references must be unique (violations at <value-of
            select="distinct-values($duplicate-leafdivs)"/>)</report>
   </rule>
   <rule context="tei:div | tan:div">
      <let name="these-types" value="tokenize(tan:normalize-text(@type),' ')"/>
      <let name="these-ns" value="tokenize(tan:normalize-text(@n),' ')"/>
      <let name="faulty-types" value="$these-types[not(. = $div-types)]"/>
      <let name="is-leaf-div"
         value="
            if ($self-is-flat = true()) then
               text()
            else
               if (not(tei:div | tan:div)) then
                  true()
               else
                  false()"
      />
      <report
         test="
            if ($is-leaf-div) then
               if ($self-is-flat = true()) then
                  (preceding-sibling::*, following-sibling::*)[@n = current()/@n]
               else
                  (preceding-sibling::*, following-sibling::*)[@n = $these-ns][@type = $these-types]
            else
               false()"
         >Leaf div references must be unique. </report>
      <report test="exists($faulty-types)">@type must match the @xml:id of a &lt;div-type> (perhaps
         <value-of select="$faulty-types"/> should be
         <value-of
            select="
               for $i in $faulty-types
               return
                  $div-types[matches(., tan:escape($i))]"
         />)</report>
      <report test="$is-leaf-div and not($self-is-flat) and not(@include) and not(matches(., '\S'))">Every leaf div 
         in non-flat class 1 files must
         have at least some non-space text.</report>
      <report test="
            some $i in text()
               satisfies matches($i, '^\p{M}')"
         sqf:fix="remove-modifiers-starting-divs">No div may begin with a modifying
         character.</report>
      <report test="matches(string-join(text(), ''), '\s\p{M}')"
         sqf:fix="remove-space-preceding-modifiers">No div may have a spacing character followed by
         a modifying character.</report>
      <sqf:fix id="remove-modifiers-starting-divs">
         <sqf:description>
            <sqf:title>Remove modifiers starting divs</sqf:title>
            <sqf:p>If an element's text begins with modifiers, a Schematron Quick Fix will be
               available to remove those initial modifiers.</sqf:p>
         </sqf:description>
         <sqf:replace match="text()" select="replace(., '^\p{M}+', '')"/>
      </sqf:fix>
      <sqf:fix id="remove-space-preceding-modifiers">
         <sqf:description>
            <sqf:title>Remove space preceding modifiers</sqf:title>
            <sqf:p>If a text is seen to have modifiers following a spacing character, a Schematron
               Quick Fix will be available to remove any space that precedes modifiers.</sqf:p>
         </sqf:description>
         <sqf:replace match="text()" select="replace(., '\s+(\p{M})', '$1')"/>
      </sqf:fix>
   </rule>
</pattern>
