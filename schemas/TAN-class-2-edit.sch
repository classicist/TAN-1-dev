<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" id="class-2-edit">
   <title>Schematron tests for class 2 TAN files, edits only.</title>
   <p>This pattern facilitates quick, on-the-fly help for editing class 2 files.</p>
   <let name="this-tail" value="/tan:*/tan:tail"/>
   <let name="srcs-prepped-edit"
      value="
         if (exists($this-tail)) then
            $this-tail
         else
            tan:get-src-1st-da-prepped()"/>
   <rule context="/*[2]" tan:applies-to="tail">
      <!-- XPath is /*[2] to avoid triggering guidelines for tan:body -->
      <assert test="/*/tan:tail" role="warning" sqf:fix="make-tail-srcs-prepped">This editing phase
         depends upon preparation of each source document, which can be time-consuming and
         inefficient if done every single time. Select the associated Quick Fix to create a
         /*/tan:tail with a copy of the prepared source documents, to speed up editing.
         Alternatively, use the official TAN stylesheet found at
         stylesheets/speed-validation</assert>
      <sqf:fix id="make-tail-srcs-prepped">
         <sqf:description>
            <sqf:title>Create tail with content of prepped sources (time-consuming)</sqf:title>
            <sqf:p>In the edit phase of validation, invoking this SQF will delete the current
               &lt;tail> (if present and add a new &lt;tail> that contains a copy of all sources
               prepared (result of the function tan:get-src-1st-da-prepped()). Very useful for
               getting editing help in the context of numerous, long source files. The procedure is
               very lengthy, however, and can be shortened by using the official TAN stylesheet to
               create a clone and work from there.</sqf:p>
         </sqf:description>
         <sqf:delete match="/*/tan:tail"/>
         <sqf:add match="." position="after">
            <tan:tail>
               <xsl:copy-of select="$srcs-prepped-edit/*"/>
            </tan:tail>
         </sqf:add>
      </sqf:fix>
   </rule>
   <rule context="tan:tok | tan:anchor-div-ref | tan:div-ref">
      <let name="help-requested" value="tan:help-requested(.)"/>
      <let name="srcs-pass-1" value="tokenize(tan:normalize-text(@src), ' ')"/>
      <let name="these-srcs"
         value="
            if ($srcs-pass-1 = '*') then
               $head/tan:source/@xml:id
            else
               $srcs-pass-1"/>
      <let name="these-refs" value="tokenize(tan:normalize-text(@ref), ' [-,] ')"/>
      <let name="matched-refs"
         value="$srcs-prepped-edit/*[@src = $these-srcs]/tan:body//tan:div[@ref = $these-refs]"/>
      <let name="mismatched-refs"
         value="
            for $i in $these-srcs,
               $j in $these-refs
            return
               if ($srcs-prepped-edit/*[@src = $i]/tan:body//tan:div[@ref = $j]) then
                  ()
               else
                  ($i, $j)"/>
      <let name="possible-corrections"
         value="
            for $i in (1 to (count($mismatched-refs) idiv 2)),
               $j in $mismatched-refs[($i * 2) - 1],
               $k in $mismatched-refs[($i * 2)]
            return
               $srcs-prepped-edit/*[@src = $j]/tan:body//tan:div[matches(@ref, $k)]/@ref"/>
      <let name="help-requested-ref-matches"
         value="
            for $i in $these-srcs,
               $j in $these-refs
            return
               $srcs-prepped-edit/*[@src = $i]/tan:body//tan:div[matches(@ref, $j)]"/>
      <let name="help-requested-searched-matches"
         value="
            for $i in tan:normalize-text(@ref),
               $j in (if ($searches-ignore-accents = true()) then
                  tan:expand-search($i)
               else
                  $i)
            return
               $srcs-prepped-edit/*[@src = $these-srcs]/tan:body//tan:div[matches(., $j, $match-flags)]"/>
      <report test="exists($mismatched-refs) or $help-requested = true()"
         sqf:fix="fetch-content get-matched-divs"
         ><!-- Putting $help-trigger in @ref will take the content of @ref and return matching refs or refs that point to 
            <div>s where the regular expression is found -->Try
            <value-of select="$help-requested-ref-matches/@ref"/> (@ref matches) or <value-of
            select="$help-requested-searched-matches/@ref"/> (text matches) <value-of
            select="count($srcs-prepped-edit)"/>
         <!--<value-of
            select="$srcs-prepped-edit/*/tan:body//tan:div[@ref = 'Col 1 4']"/>--></report>

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
               <tan:div-ref src="{ancestor::tan:TAN-T/@src}" ref="{@ref}"/>
               <xsl:text>&#xA;</xsl:text>
               <tan:comment when="{current-date()}" who="{$head/tan:agent[1]/@xml:id}"><xsl:value-of
                     select="./text()"/></tan:comment>
            </xsl:for-each>
         </sqf:add>
      </sqf:fix>
   </rule>
</pattern>
