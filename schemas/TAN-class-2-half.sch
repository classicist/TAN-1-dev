<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" id="class-2-half">
   <title>Schematron tests for class 2 TAN files, second level of expansion.</title>
   <let name="srcs-prepped" value="tan:get-src-1st-da-prepped($self-expanded-2, $srcs-resolved)"/>
   <let name="self-expanded-3" value="tan:get-self-expanded-3($self-expanded-2, $srcs-prepped)"/>
   <rule
      context="
         tan:tok | tan:anchor-div-ref | tan:div-ref |
         tan:realign[@include] | tan:align[@include] | tan:ana[@include] | tan:split-leaf-div-at[@include]">
      <let name="this" value="."/>
      <let name="this-resolved" value="tan:resolve-include(.)"/>
      <let name="this-expanded" value="tan:expand-src-and-div-type-ref($this-resolved)"/>
      <let name="these-elements-with-ref" value="$this-expanded/descendant-or-self::*[@ref]"/>
      <let name="these-elements-with-ref-help-requested"
         value="
            for $i in $these-elements-with-ref
            return
               if (tan:help-requested($i/@ref))
               then
                  $i
               else
                  ()"/>
      <let name="matched-refs"
         value="
            for $i in $these-elements-with-ref,
               $j in tokenize(normalize-space(($i/@src, '1')[1]), ' '),
               $k in tokenize(tan:normalize-refs($i/@ref), ' [-,] '),
               $l in $srcs-prepped/*[@src = $j]
            return
               key('div-via-ref', $k, $l)"
      />
      <let name="mismatched-refs"
         value="
            for $i in $these-elements-with-ref,
               $j in tokenize(normalize-space(($i/@src, '1')[1]), ' '),
               $k in tokenize(tan:normalize-refs($i/@ref), ' [-,] ')
            return
               if (some $l in $srcs-prepped/*[@src = $j]
                  satisfies key('div-via-ref', $k, $l)) then
                  ()
               else
                  ($i/@src, $k)"
      />
      <let name="possible-corrections"
         value="
            for $i in (1 to (count($mismatched-refs) idiv 2)),
               $j in $mismatched-refs[($i * 2) - 1],
               $k in $mismatched-refs[($i * 2)]
            return
               $srcs-prepped/tan:TAN-T[@src = $j]/tan:body//tan:div[matches(@ref, $k)]/@ref"/>
      <let name="help-requested-ref-matches"
         value="
            for $i in $these-elements-with-ref-help-requested,
               $j in tokenize(tan:normalize-refs($i/@ref), ' [-,] ')
            return
               $srcs-prepped/tan:TAN-T[@src = $i/@src]/tan:body//tan:div[matches(@ref, $j)]"/>
      <let name="help-requested-searched-matches"
         value="
            for $i in $these-elements-with-ref-help-requested,
               $j in tan:normalize-refs($i/@ref),
               $k in (if ($searches-ignore-accents = true()) then
                  tan:expand-search($j)
               else
                  $j)
            return
               $srcs-prepped/tan:TAN-T[@src = $i/@src]/tan:body//tan:div[matches(., $k, $match-flags)]"/>
      <let name="cont-with-disjoint-srcs"
         value="$this-resolved/descendant-or-self::*[@cont][not(@src = following-sibling::*/@src)]"/>
      <report test="exists($mismatched-refs)" tan:does-not-apply-to="realign align ana split-leaf-div-at"
         tan:applies-to="ref">Every @ref must be found in every
         source (<value-of
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
      <report test="exists($these-elements-with-ref-help-requested)"
         sqf:fix="fetch-content get-matched-divs" tan:does-not-apply-to="realign align ana split-leaf-div-at"
         ><!-- Putting $help-trigger in @ref will take the content of @ref and return matched refs or refs that have matched content -->Try
            <value-of select="$help-requested-ref-matches/@ref"/> (@ref matches) or <value-of
            select="$help-requested-searched-matches/@ref"/> (text matches) </report>
      <report tan:does-not-apply-to="realign align ana split-leaf-div-at"
         test="
            some $i in preceding-sibling::*
               satisfies deep-equal($i, $this)"
         >May not be duplicated by siblings</report>
      <report test="exists($cont-with-disjoint-srcs)"
         tan:does-not-apply-to="realign align ana split-leaf-div-at" tan:applies-to="cont">@cont may
         not be used to join references from different sources.</report>

      <!-- SCHEMATRON QUICK FIXES -->
      <sqf:fix id="fetch-content" use-when="exists($matched-refs)">
         <sqf:description>
            <sqf:title>Append text content of the divs being referred to</sqf:title>
            <sqf:p>For elements with at least one match in @ref, selecting this option will insert
               for every reference in every source a tan:comment element as a following sibling with
               the textual content.</sqf:p>
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
            <sqf:p>This quick fix will allow you to search for divs by @ref or by text search
               (regular expressions) and append matching divs as tan:comments.</sqf:p>
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
