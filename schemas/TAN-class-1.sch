<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core tests for class 1 TAN files.</title>
   <let name="self-is-flat" value="tan:is-flat-class-1($self-resolved)"/>
   <let name="self-flattened" value="tan:flatten-class-1-doc(/)"/>
   <!--<let name="prep-body" value="tan:prep-body()"/>-->
   <let name="self-flattened-body" value="$self-flattened/(tei:TEI/tei:text/tei:body, tan:TAN-T/tan:body)"/>
   <let name="leafdiv-flatrefs" value="$self-flattened-body/(tan:div, tei:div)/@n"/>
   <!--<let name="transcription-langs" value="$prep-body//@xml:lang"/>-->
   <let name="div-types" value="$head/tan:declarations/tan:div-type/@xml:id"/>
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
      <let name="resolved-docs" value="tan:resolve-doc($first-docs)"/>
      <let name="resolved-bodies"
         value="$resolved-docs/(tei:TEI/tei:text/tei:body, tan:TAN-T/tan:body)"/>
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
   <rule context="tei:div | tan:div">
      <let name="these-types" value="tokenize(tan:normalize-text(@type),$separator-hierarchy-regex)"/>
      <let name="these-ns" value="tokenize(tan:normalize-text(@n),$separator-hierarchy-regex)"/>
      <let name="faulty-types" value="$these-types[not(. = $div-types)]"/>
      <let name="this-ref" value="tan:flatref(.)"/>
      <let name="is-leaf-div"
         value="
            if ($self-is-flat = true()) then
               exists(text())
            else
               if (not(tei:div | tan:div)) then
                  true()
               else
                  false()"
      />
      <!-- variables for checking flat transcriptions -->
      <let name="prec-ns"
         value="tokenize(tan:normalize-text(preceding-sibling::*[1]/@n), $separator-hierarchy-regex)"
      />
      <let name="foll-ns"
         value="tokenize(tan:normalize-text(following-sibling::*[1]/@n), $separator-hierarchy-regex)"
      />
      <let name="this-hierarchy-level" value="count($these-ns)"/>
      <let name="first-ancestor-common-with-prev"
         value="
            for $i in (1 to $this-hierarchy-level)
            return
               if ($prec-ns[$i] = $these-ns[$i]) then
                  $prec-ns[$i]
               else
                  ()"
      />
      <let name="foll-is-child"
         value="
            ($this-hierarchy-level + 1 = count($foll-ns)) and (every $i in (1 to count($this-hierarchy-level))
               satisfies
               $these-ns[$i] = $foll-ns[$i])"
      />
      <report
         test="
            if ($is-leaf-div = true()) then
               index-of($leafdiv-flatrefs, $this-ref)[2]
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
      <assert test="count($these-types) = count($these-ns)">The values of @n and @type must balance.</assert>
      <!-- reports specific to flat transcriptions -->
      <assert
         test="
            if ($self-is-flat = true()) then
               ($this-hierarchy-level = 1 or exists($first-ancestor-common-with-prev))
            else
               true()"
         >In a flat transcription every div must either be at the top of a hierarchy or have an
         ancestor in common with the preceding div.</assert>
      <assert
         test="
            if ($self-is-flat = true() and not($is-leaf-div)) then
               $foll-is-child
            else
               true()"
         >In a flat transcription any non-leaf-div must be followed by a child div.</assert>
      <!-- SQFixes -->
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
