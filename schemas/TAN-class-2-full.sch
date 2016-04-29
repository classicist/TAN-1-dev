<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" id="class-2-full">
   <title>Schematron tests for class 2 TAN files, full phase</title>
   <p>This battery of tests is possibly quite time consuming, especially for class-2 files that
      refer to lengthy sources. Includes tests that involve tokenization and tests on the sources
      (e.g., checking that leaf divs are uniquely named).</p>
   <let name="srcs-tokenized" value="tan:get-src-1st-da-tokenized($self-expanded-2, $srcs-prepped)"/>
   <let name="self-expanded-4" value="tan:get-self-expanded-4($self-expanded-3, $srcs-tokenized)"/>
   <let name="duplicate-tok-siblings"
      value="
         for $i in $self-expanded-4//*[tan:tok],
            $j in $i/tan:tok,
            $k in $j/preceding-sibling::tan:tok
         return
            if ($j/@src = $k/@src and $j/@ref = $k/@ref and $j/@n = $k/@n) then
               $j
            else
               ()"/>
   <rule context="tan:head">
      <let name="duplicate-leafdiv-flatrefs"
         value="
         for $i in $srcs-prepped
         return
         tan:duplicate-values($i/tan:TAN-T/tan:body//tan:div[not(tan:div)]/@ref)"
      />
      <report test="exists($duplicate-leafdiv-flatrefs)" tan:does-not-apply-to="head"
         subject="tan:source">Class 1 sources must preserve the leaf div uniqueness rule (violations
         at <value-of
            select="
            for $i in $duplicate-leafdiv-flatrefs
            return
            concat(root($i)/*/@src, ': ', $i/@ref)"
         />). </report>
      <!-- needs to be diagnosed and fixed -->
      <!--<sqf:fix id="use-new-edition">
         <sqf:description>
            <sqf:title>Replace with new version</sqf:title>
            <sqf:p>If the source is found to have a see-also that has a relationship of
               'new-version', choosing this option will replace the IRI + name pattern with the one
               in the source file's see-also.</sqf:p>
         </sqf:description>
         <sqf:delete match="child::*"/>
         <sqf:add match="."
            select="$exists-new-version/* except $exists-new-version/tan:relationship"/>
      </sqf:fix>-->
   </rule>
   <rule context="tan:body">
      <report test="exists($duplicate-tok-siblings)"
            ><!-- Class 2 files should not have deeply equal elements in <body> --><value-of
            select="$duplicate-tok-siblings/@*"/></report>
   </rule>
   <rule
      context="tan:tok | tan:ana[@include] | tan:split-leaf-div-at[@include] | tan:align[root()/tan:TAN-A-tok][@include]">
      <let name="this-resolved" value="tan:resolve-include(.)"/>
      <let name="these-toks"
         value="tan:expand-src-and-div-type-ref((self::tan:tok, $this-resolved/tan:tok))"/>
      <let name="these-toks-expanded" value="tan:expand-tok($these-toks, $srcs-tokenized)"/>
      <let name="these-toks-with-pos-help-requested"
         value="
            for $i in $these-toks-expanded
            return
               if (tan:help-requested($i/@pos) = true()) then
                  $i
               else
                  ()"/>
      <let name="these-toks-with-pos-help-requested-values-without-val"
         value="
            for $i in $these-toks-with-pos-help-requested[not(@val)]
            return
               $srcs-tokenized/tan:TAN-T[@src = tan:normalize-text($i/@src)]/tan:body/tan:div[@ref = tan:normalize-text($i/@ref)]/tan:tok"/>
      <let name="these-toks-with-pos-help-requested-values-with-val"
         value="
            for $i in $these-toks-with-pos-help-requested[@val],
               $j in $srcs-tokenized/tan:TAN-T[@src = tan:normalize-text($i/@src)]/tan:body/tan:div[@ref = tan:normalize-text($i/@ref)]
            return
               (count($j/tan:tok[matches(., tan:normalize-text($i/@val))]), distinct-values($j/tan:tok[matches(., tan:normalize-text($i/@val))]))"/>
      <let name="these-toks-with-val-help-requested"
         value="
            for $i in $these-toks-expanded[@val]
            return
               if (tan:help-requested($i/@val) = true()) then
                  $i
               else
                  ()"/>
      <let name="these-toks-with-val-help-requested-suggestions"
         value="
            for $i in $these-toks-with-val-help-requested,
               $j in $srcs-tokenized/tan:TAN-T[@src = tan:normalize-text($i/@src)]/tan:body/tan:div[@ref = tan:normalize-text($i/@ref)]
            return
               for $k in distinct-values($j/tan:tok[matches(., tan:normalize-text($i/@val))])
               return
                  ($k,
                  count($j/tan:tok[. = $k]))"/>
      <let name="these-duplicate-siblings"
         value="
            for $i in $these-toks-expanded,
               $j in $duplicate-tok-siblings
            return
               if (deep-equal($i, $j)) then
                  $i
               else
                  ()"/>
      <let name="tokens-not-found" value="$these-toks-expanded[xs:integer(@n) lt 0]"/>
      <let name="these-toks-with-chars" value="$these-toks-expanded[@chars]"/>
      <let name="these-toks-with-chars-help-requested"
         value="
            for $i in $these-toks-with-chars
            return
               if (tan:help-requested($i/@chars) = true()) then
                  $i
               else
                  ()"/>
      <let name="these-toks-with-chars-values"
         value="
            for $i in $these-toks-with-chars
            return
               ($srcs-tokenized/tan:TAN-T[@src = tan:normalize-text($i/@src)]/tan:body/tan:div[@ref = tan:normalize-text($i/@ref)]/tan:tok[@n = $i/@n])[1]"/>
      <let name="toks-with-incorrect-chars"
         value="
            for $i in (1 to count($these-toks-with-chars)),
               $j in $these-toks-with-chars[$i],
               $k in $these-toks-with-chars-values[$i]/text(),
               $l in string-length(replace($k, '\p{M}', ''))
            return
               if (some $m in tan:sequence-expand(tan:normalize-text($j/@chars), $l)
                  satisfies ($m lt 1 or $m gt $l)) then
                  ($j, $k)
               else
                  ()"/>
      <let name="splits-at-first-tok"
         value="
            if (ancestor-or-self::tan:split-leaf-div-at) then
               $these-toks-expanded[@n = '1']
            else
               ()"/>
      <report test="exists($tokens-not-found)">Tokens must be locatable ( <value-of
            select="
               for $i in $tokens-not-found
               return
                  ($i/(@ref),
                  $errors//tan:group[@affects-element = 'tok']/tan:error[abs(xs:integer($i/@n))])"
         />)</report>
      <report test="exists($these-duplicate-siblings)"
         tan:does-not-apply-to="ana split-leaf-div-at align">Sibling &lt;tok>s may not point to the
         same token (<value-of select="$these-duplicate-siblings/@*"/>).</report>
      <report test="exists($toks-with-incorrect-chars)" tan:does-not-apply-to="ana split-leaf-div-at align"
         tan:applies-to="chars">@chars may not exceed the number of
         characters in a token picked (<value-of
            select="
               for $i in (1 to (count($toks-with-incorrect-chars) idiv 2)),
                  $j in $toks-with-incorrect-chars[($i * 2) - 1],
                  $k in $toks-with-incorrect-chars[($i * 2)]
               return
                  concat($j/@src, ':', $j/@ref, ':', $j/@n, ' = ', $k)"
         />) </report>
      <report test="exists($these-toks-with-pos-help-requested-values-without-val)" tan:applies-to="pos"
         tan:does-not-apply-to="ana split-leaf-div-at align"><!-- Putting $help-trigger in @pos when there
         is no @val will return the maximum number of tokens allowed -->max <value-of
            select="$these-toks-with-pos-help-requested-values-without-val"/></report>
      <report test="exists($these-toks-with-pos-help-requested-values-with-val)" tan:applies-to="pos"
         tan:does-not-apply-to="ana split-leaf-div-at align"><!-- Putting $help-trigger in @pos while @val 
            exists will return the maximum number of tokens that match the value of @val -->max <value-of
            select="$these-toks-with-pos-help-requested-values-with-val"/>
      </report>
      <report tan:applies-to="chars" 
         test="exists($these-toks-with-chars-help-requested)"><!-- Putting $help-trigger in @chars will return the maximum number of characters allowed --><value-of
            select="
               for $i in $these-toks-with-chars-help-requested,
                  $j in $srcs-tokenized/tan:TAN-T[@src = $i/@src]/tan:body/tan:div[@ref = $i/@ref]/tan:tok[@n = $i/@n]
               return
                  concat('max ', string-length($j), ' (', $j, ') ')"
         /></report>
      <report test="exists($splits-at-first-tok)" tan:does-not-apply-to="ana align">&lt;tok> splits
         may not be made at the first token in a div.</report>
      <report test="exists($these-toks-with-val-help-requested-suggestions)"><!-- Putting $help-trigger in @val 
         will return distinct values of tokens along with the number of times each one occurs -->Possible values and
         counts: <value-of select="$these-toks-with-val-help-requested-suggestions"/></report>
   </rule>
</pattern>
