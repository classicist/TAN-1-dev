<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core tests for class 1 TAN files.</title>

   <rule context="*">
      <let name="this-name" value="name(.)"/>
      <let name="this-q" value="count(preceding-sibling::*[name(.) = $this-name]) + 1"/>
      <let name="this-q-ref" value="tan:q-ref(.)"/>
      <let name="this-checked-for-errors"
         value="tan:get-via-q-ref($this-q-ref, $self-class-1-errors-marked)"/>
      <let name="has-include-or-which-attr" value="exists(@include) or exists(@which)"/>
      <let name="relevant-fatalities"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:fatal
            else
               $this-checked-for-errors/tan:fatal"/>
      <let name="relevant-errors"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:error
            else
               $this-checked-for-errors/tan:error"/>
      <let name="relevant-warnings"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:warning
            else
               $this-checked-for-errors/tan:warning"/>
      <let name="help-requested"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:help
            else
               $this-checked-for-errors/tan:help"/>
      <report test="exists($relevant-fatalities)" role="fatal">
         <value-of select="$relevant-fatalities/tan:rule"/></report>
      <report test="exists($relevant-errors)" sqf:fix="errors">
         <value-of select="tan:error-report($relevant-errors)"/></report>
      <report test="exists($relevant-warnings)" role="warning">[<value-of
            select="$relevant-warnings/@xml:id"/>] <value-of select="$relevant-warnings/tan:message"
         /></report>
      <report test="exists($help-requested)" role="warning" sqf:fix="help">
         <value-of select="$help-requested/tan:message"/>
      </report>
   </rule>

   <!--<let name="self-prepped" value="tan:prep-resolved-class-1-doc($self-resolved)"/>-->
   <!--<let name="this-text" value="tan:text-join($body)"/>-->
   <!--<let name="leafdiv-flatrefs"
      value="
         for $i in $body//(tan:div, tei:div)[not(tan:div | tei:div)]
         return
            tan:flatref($i)"/>-->
   <!--<let name="relationship-key"
      value="$TAN-keywords/tan:TAN-key[@id = 'tag:textalign.net,2015:tan-key:relationships']"/>-->
   <!--<let name="see-also-resegmented-copies"
      value="$head/tan:see-also[tan:has-relationship(., 'resegmented copy', ())]"/>-->
   <!--<let name="copies-1st-la"
      value="
         for $i in $head/tan:see-also[tan:relationship/tan:IRI = $relationship-key//tan:item[tan:name = 'alternatively divided edition']/tan:IRI]
         return
            tan:first-loc-available($i)"/>-->
   <!--<let name="copies-1st-da-resolved"
      value="tan:resolve-doc(tan:get-1st-doc($see-also-resegmented-copies))"/>
   <let name="copy-comparisons"
      value="
         for $i in $copies-1st-da-resolved
         return
            tan:compare-copies($self-resolved, $i)"/>
   <let name="divs-not-in-copies" value="$copy-comparisons//*:div[@copy-text]"/>
   <let name="div-types" value="$head/tan:declarations/tan:div-type/@xml:id"/>
   <let name="see-also-models" value="$head/tan:see-also[tan:has-relationship(., 'model', ())]"/>-->
   <!--<let name="model-1st-la"
      value="
         for $i in $head/tan:see-also[tan:relationship/tan:IRI = $relationship-key//tan:item[tan:name = 'model']/tan:IRI]
         return
            tan:first-loc-available($i)"/>-->
   <!--<let name="model-1st-da-resolved" value="tan:resolve-doc(tan:get-1st-doc($see-also-models))"/>
   <let name="model-prepped" value="tan:prep-resolved-class-1-doc($model-1st-da-resolved)"/>
   <let name="self-and-model-skeletons-merged"
      value="tan:get-src-skeleton(($self-prepped, $model-prepped), 'type')"/>
   <let name="skeleton-divs" value="$self-and-model-skeletons-merged//*:div"/>
   <let name="model-divergence-threshold" value="0.1"/>-->

   <!--<rule context="tan:see-also">
      <let name="this-resolved" value="."/>
      <let name="first-locs"
         value="
            for $i in $this-resolved
            return
               tan:first-loc-available($i)"/>
      <let name="first-docs"
         value="
            for $i in $this-resolved
            return
               tan:get-1st-doc($i)"/>
      <let name="is-alternatively-divided-edition"
         value="
            for $i in $this-resolved
            return
               $i/tan:relationship/@which = $relationship-key//tan:item[tan:name = 'alternatively divided edition']/tan:name"/>
      <let name="is-strict-alternative"
         value="
            for $i in (1 to count($this-resolved))
            return
               ($is-alternatively-divided-edition[$i])"/>
      <let name="is-model"
         value="
            for $i in $this-resolved
            return
               $i/tan:relationship/@which = $relationship-key//tan:item[tan:name = 'model']/tan:name
            "/>
      <let name="shares-same-source"
         value="
            for $i in (1 to count($this-resolved))
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
               $body/@xml:lang = $first-docs[$i]//(*:body)/@xml:lang"/>
      <let name="resolved-docs" value="tan:resolve-doc($first-docs)"/>
      <let name="resolved-bodies"
         value="$resolved-docs/(tei:TEI/tei:text/tei:body, tan:TAN-T/tan:body)"/>
      <let name="alternative-text"
         value="
            for $i in $resolved-bodies
            return
               tan:text-join($i)"/>
      <let name="is-same-text"
         value="
            for $i in (1 to count($this-resolved))
            return
               if ($this-text = $alternative-text[$i]) then
                  true()
               else
                  false()"/>
      <let name="discrepancies-here"
         value="
            for $i in (1 to count($this-resolved))
            return
               string-join(for $j in $body//*:div[not(*:div)]
               return
                  if (contains($alternative-text[$i], tan:normalize-div-text($j))) then
                     ()
                  else
                     tan:flatref($j), ', ')"/>
      <let name="discrepancies-there"
         value="
            for $i in (1 to count($this-resolved))
            return
               string-join(for $j in $first-docs[$i]//*:div[not(*:div)]
               return
                  if (contains($this-text, tan:normalize-div-text($j))) then
                     ()
                  else
                     tan:flatref($j), ', ')"/>
      <!-\-<let name="div-types-here" value="tan:get-div-types-in-use($self-resolved)"/>-\->
      <!-\-<let name="div-types-there" value="tan:get-div-types-in-use($first-docs)"/>-\->
      <!-\-<let name="div-types-used-here-but-not-there"
         value="$div-types-here/tan:div-type[not(tan:IRI = $div-types-there//tan:IRI)]"/>-\->
      <!-\-<let name="div-types-used-there-but-not-here"
         value="$div-types-there/tan:div-type[not(tan:IRI = $div-types-here//tan:IRI)]"/>-\->
      <let name="divs-used-there-but-not-here"
         value="$skeleton-divs[@src = '2']"/>
      <let name="divs-used-here-but-not-there"
         value="$skeleton-divs[@src = '1']"/>
      <let name="count-divs" value="count($skeleton-divs)"></let>
      <!-\-<report
         test="
            for $i in count($this-resolved)
            return
               $is-strict-alternative[$i] and not($shares-same-source[$i])"
         >In class 1 files, alternative editions must share the same source.</report>-\->
      <!-\-<report
         test="
            for $i in count($this-resolved)
            return
               $is-strict-alternative[$i] and not($shares-same-work[$i])"
         >In class 1 files, alternative editions must share the same work.</report>-\->
      <!-\-<report
         test="
            for $i in count($this-resolved)
            return
               $is-strict-alternative[$i] and not($shares-same-work-version[$i])"
         >In class 1 files, alternative editions must share the same work-version.</report>-\->
      <!-\-<report test="true()"><value-of select="tan:lcs($this-text, $alternative-text)"/></report>-\->
      <!-\-<report test="true()"><value-of select="$alternative-text"/></report>-\->
      <!-\-<report
         test="
            some $i in (1 to count($this-resolved))
               satisfies
               $is-alternatively-divided-edition[$i] and $is-same-text[$i] = false()"
         >In class 1 files, resegmented copies must have identical transcriptions, after TAN
         normalization. (<value-of
            select="
               if (exists($discrepancies-here)) then
                  concat('Discrepancies here [length ', string-length($this-text), ']: ', string-join(($discrepancies-here), ', '), '. ')
               else
                  ()"/>
         <value-of
            select="
               if (exists($discrepancies-there)) then
                  concat('Discrepancies in alternative copy: [length ', string-join(for $i in $alternative-text
                  return
                     string(string-length($i)), ' '), ']', string-join(($discrepancies-there), ', '), '. ')
               else
                  ()"
         />)</report>-\->
      <!-\-<report test="$is-model = true() and $shares-same-work = false()">A class 1 file and its model
         must have the same work. (here: <value-of select="$head/tan:declarations/tan:work/tan:name"
         />; there: <value-of select="$first-docs/*/tan:head/tan:declarations/tan:work/tan:name"
         /></report>-\->
      <!-\-<report
         test="
            if ($is-model = true()) then
               exists($div-types-used-here-but-not-there)
            else
               false()"
         >A class 1 file may use div types that are not used in its model only if they do not
         correspond to a div in the model (<value-of
            select="$div-types-used-here-but-not-there/@xml:id"/>)</report>-\->
      <!-\-<report
         test="
            if ($is-model = true()) then
               exists($div-types-used-there-but-not-here)
            else
               false()"
         >A class 1 file should use all div types that are used by its model (<value-of
            select="$div-types-used-there-but-not-here/@xml:id"/>)</report>-\->
      <!-\-<report test="$is-model = true() and count('$model-1st-la') gt 1">A class 1 file may have no
         more than one model.</report>-\->
      <!-\-<report role="warning"
         test="
            if ($is-model = true()) then
               ((exists($divs-used-there-but-not-here) or exists($divs-used-here-but-not-there)) and
               (
               (count($divs-used-here-but-not-there) + count($divs-used-there-but-not-here)) div count($skeleton-divs) lt $model-divergence-threshold
               )
               )
            else
               false()"
         ><!-\\- If a class 1 file diverges from its model in its reference structure by less than 10% a warning will be generated specifying where differences exist -\\->
         This file and its model diverge: <value-of
            select="
               if (exists($divs-used-here-but-not-there)) then
                  concat('uniquely here: ', string-join($divs-used-here-but-not-there/@ref, '; '), ' ')
               else
                  ()"/>
         <value-of
            select="
               if (exists($divs-used-there-but-not-here)) then
                  concat('unique to model: ', string-join($divs-used-there-but-not-here/@ref, '; '), ' ')
               else
                  ()"
         />
      </report>-\->
      <!-\-<report
         test="
            if ($is-model = true()) then
               ((exists($divs-used-there-but-not-here) or exists($divs-used-here-but-not-there)) and
               (
               (count($divs-used-here-but-not-there) + count($divs-used-there-but-not-here)) div count($skeleton-divs) gt $model-divergence-threshold
               )
               )
            else
               false()"
         ><!-\\- If a class 1 file diverges from its model in its reference structure by less than 10% a warning will be generated specifying where differences exist -\\->
         This file and its model diverge: <value-of
            select="
               if (exists($divs-used-here-but-not-there)) then
                  concat('uniquely here: ', string-join($divs-used-here-but-not-there/@ref, '; '), ' ')
               else
                  ()"/>
         <value-of
            select="
               if (exists($divs-used-there-but-not-here)) then
                  concat('unique to model: ', string-join($divs-used-there-but-not-here/@ref, '; '), ' ')
               else
                  ()"
         />
      </report>-\->
   </rule>-->
   <!--<rule context="tan:work">
      <report test="count(tokenize(@include, '\s+')) gt 1">No more than one inclusion may be
         invoked.</report>
   </rule>-->
   <!--<rule context="tei:div | tan:div">
      <let name="faulty-types" value="tan:normalize-text(@type)[not(. = $div-types)]"/>
      <let name="this-ref" value="tan:flatref(.)"/>
      <let name="this-type" value="@type"/>
      <let name="is-leaf-div"
         value="
            if (not(tei:div | tan:div)) then
               true()
            else
               false()"/>
      <let name="faulty-copy" value="$divs-not-in-copies[@ref = $this-ref]"/>
      <!-\-<let name="skel-div" value="$self-and-model-skeletons-merged//tan:div[@ref = $this-ref][not(@src = '1')]"/>-\->
      <!-\-<let name="this-div-type" value="$head/tan:declarations/tan:div-type[@xml:id = $this-type]"/>-\->
      <!-\-<let name="model-div-type"
         value="$self-and-model-skeletons-merged/*/tan:head[2]/tan:declarations/tan:div-type[@xml:id = $skel-div/(@type, @type-2)]"
      />-\->
      <!-\-<report
         test="
            if ($is-leaf-div = true()) then
               index-of($leafdiv-flatrefs, $this-ref)[2]
            else
               false()"
         >Leaf div references must be unique. (<value-of select="$this-ref"/>)</report>-\->
      <!-\-<report test="exists($faulty-types)">@type must match the @xml:id of a &lt;div-type> (perhaps
            <value-of select="$faulty-types"/> should be <value-of
            select="
               for $i in $faulty-types
               return
                  $div-types[matches(., tan:escape($i))]"
         />)</report>-\->
      <!-\-<report
         test="
            if (exists($model-1st-la)) then
               exists($skel-div) and not($this-div-type/tan:IRI = $model-div-type/tan:IRI)
            else
               false()"
         >Divs must have the same type as their model. (<value-of
            select="$this-div-type/tan:name[1]"/> vs. <value-of select="$model-div-type/tan:name[1]"
         />)</report>-\->
      <!-\-<report test="$is-leaf-div and not(@include) and not(matches(., '\S'))">Every leaf div must
         have at least some non-space text.</report>-\->
      <!-\-<report test="
            some $i in text()
               satisfies matches($i, '^\p{M}')"
         sqf:fix="remove-modifiers-starting-divs">No div may begin with a modifying
         character.</report>-\->
      <!-\-<report test="matches(string-join(text(), ''), '\s\p{M}')"
         sqf:fix="remove-space-preceding-modifiers">No div may have a spacing character followed by
         a modifying character.</report>-\->
      <!-\-<report test="matches(string-join(text(), ''), $regex-characters-not-permitted)"
         sqf:fix="remove-banned-characters">No div may have Unicode characters that are disallowed,
         e.g., U+A0, NO BREAK SPACE.</report>-\->
      <!-\-<report test="exists($faulty-copy)" sqf:fix="replace-with-copy-text">The text of each div
         should be found in the copy. (Copy text: <value-of select="$faulty-copy/@copy-text"
         />)</report>-\->
      <!-\- SQFixes -\->
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
      <sqf:fix id="remove-banned-characters">
         <sqf:description>
            <sqf:title>Remove Unicode disallowed characters</sqf:title>
            <sqf:p>If a text has characters disallowed by the TAN format, e.g., U+A0, NO BREAK
               SPACE, a Schematron Quick Fix will be available to remove any space that precedes
               modifiers.</sqf:p>
         </sqf:description>
         <sqf:replace match="text()" select="replace(., $regex-characters-not-permitted, '')"/>
      </sqf:fix>
      <sqf:fix id="replace-with-copy-text">
         <sqf:description>
            <sqf:title>Replace content of current div with the text calculated to correspond to the
               copy.</sqf:title>
         </sqf:description>
         <sqf:stringReplace regex=".+" match="text()">
            <value-of select="$faulty-copy/@copy-text"/>
         </sqf:stringReplace>
      </sqf:fix>
   </rule>-->
</pattern>
