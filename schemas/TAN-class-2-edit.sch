<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" id="class-2-edit">
   <title>Schematron tests for class 2 TAN files, edits only.</title>
   <p>This pattern facilitates quick, on-the-fly help for editing class 2 files.
      &lt;suppress-div-types> and &lt;rename-div-ns> are ignored, so as to use files prior to the
      preparatory stage. </p>
   <!-- variables as document-node() -->
   <let name="srcs-1st-da-edit" value="tan:get-src-1st-da()"/>
   <let name="srcs-resolved-edit" value="tan:get-src-1st-da-resolved($srcs-1st-da-edit, $src-ids)"/>
   <let name="srcs-flattened-edit" value="tan:get-src-1st-da-flattened($srcs-resolved-edit)"/>
   <rule context="tan:tok | tan:anchor-div-ref | tan:div-ref">
      <let name="help-requested" value="tan:help-requested(.)"/>
      <let name="srcs-pass-1" value="tokenize(tan:normalize-text(@src),' ')"/>
      <let name="these-srcs"
         value="
            if ($srcs-pass-1 = '*') then
               $head/tan:source/@xml:id
            else
               $srcs-pass-1"
      />
      <let name="these-refs" value="tokenize(tan:normalize-text(@ref),' [-,] ')"/>
      <let name="matched-refs"
         value="$srcs-flattened-edit/*[@src = $these-srcs]/(tei:text/tei:body, tan:body)/(tan:div, tei:div)[@ref = $these-refs]"/>
      <let name="mismatched-refs"
         value="
            for $i in $these-srcs,
               $j in $these-refs
            return
               if ($srcs-flattened-edit/*[@src = $i]/(tei:text/tei:body, tan:body)/(tan:div, tei:div)[@ref = $j]) then
                  ()
               else
                  ($i, $j)"
      />
      <let name="possible-corrections"
         value="
            for $i in (1 to (count($mismatched-refs) idiv 2)),
               $j in $mismatched-refs[($i * 2) - 1],
               $k in $mismatched-refs[($i * 2)]
            return
               $srcs-flattened-edit/*[@src = $j]/(tei:text/tei:body, tan:body)/(tan:div, tei:div)[matches(@ref, $k)]/@ref"
      />
      <let name="help-requested-ref-matches"
         value="
            for $i in $these-srcs,
               $j in $these-refs
            return
               $srcs-flattened-edit/*[@src = $i]/(tei:text/tei:body, tan:body)/(tan:div, tei:div)[matches(@ref, $j)]"
      />
      <let name="help-requested-searched-matches"
         value="
            for $i in tan:normalize-text(@ref),
               $j in (if ($searches-ignore-accents = true()) then
                  tan:expand-search($i)
               else
                  $i)
            return
               $srcs-flattened-edit/*[@src = $these-srcs]/(tei:text/tei:body, tan:body)/(tan:div, tei:div)[matches(., $j, $match-flags)]"
      />
      <report test="exists($mismatched-refs)">Every @ref must be found in every source (<value-of
            select="
               for $i in (1 to (count($mismatched-refs) idiv 2)),
                  $j in $mismatched-refs[($i * 2) - 1],
                  $k in $mismatched-refs[($i * 2)]
               return
                  concat($j, ':', $k)"/>
         <value-of
            select="
               if (exists($possible-corrections)) then
                  ('; try ', $possible-corrections)
               else
                  ()"
         />)</report>
      <report test="$help-requested = true()"
         sqf:fix="fetch-content get-matched-divs"
         ><!-- Putting $help-trigger in @ref will take the content of @ref and return matched refs or refs that have matched content -->Try
            <value-of select="$help-requested-ref-matches/@ref"/> (@ref matches) or <value-of
            select="$help-requested-searched-matches/@ref"/> (text matches) </report>

      <!-- SCHEMATRON QUICK FIXES -->
      <sqf:fix id="fetch-content" use-when="exists($matched-refs)">
         <sqf:description>
            <sqf:title>Append text content of the divs being referred to</sqf:title>
            <sqf:p>Selecting this option will insert for every reference in every source a
               tan:comment element as a following sibling with the textual content.</sqf:p>
         </sqf:description>
         <sqf:delete match="text()"/>
         <sqf:add match="." position="after">
            <xsl:for-each select="$matched-refs">
               <xsl:text>&#xA;</xsl:text>
               <tan:comment when="{current-date()}" who="{$head/tan:agent[1]/@xml:id}"><xsl:value-of
                     select="./text()"/></tan:comment>
            </xsl:for-each>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-matched-divs">
         <sqf:description>
            <sqf:title>Append text content of divs with @ref or text that matches current
               @ref</sqf:title>
            <sqf:p>This quick fix will allow you to search for divs by @ref or by text and append
               matching divs as tan:comments.</sqf:p>
         </sqf:description>
         <sqf:add match="." position="after">
            <xsl:for-each select="$help-requested-ref-matches, $help-requested-searched-matches">
               <xsl:text>&#xA;</xsl:text>
               <tan:div-ref src="{root()/*/@src}" ref="{@ref}"/>
               <xsl:text>&#xA;</xsl:text>
               <tan:comment when="{current-date()}" who="{$head/tan:agent[1]/@xml:id}"><xsl:value-of
                     select="./text()"/></tan:comment>
            </xsl:for-each>
         </sqf:add>
      </sqf:fix>
   </rule>
</pattern>
