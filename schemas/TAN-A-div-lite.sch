<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Schematron light tests for TAN-A-div files, included by both TAN-A-div.sch and
      TAN-A-div-edit.sch. Represents lightweight, SQF-friendly helps for editing, without any tests
      that would be time-consuming on long documents. No tests in this file should invoke
      tokenization.</title>
   <rule context="tan:TAN-A-div">
      <let name="this-schematron-pi"
         value="/processing-instruction()[matches(., 'TAN-A-div(-edit)?\.sch')]"/>
      <let name="cited-schematron-url"
         value="
            replace($this-schematron-pi,
            concat('.*href=', $quot, '([^', $quot, ']+).+'),
            '$1')"/>
      <let name="this-schematron-url"
         value="replace($cited-schematron-url, 'TAN-A-div(-edit)?\.sch', 'TAN-A-div-lite.sch')"/>
      <let name="this-schematron-resolved-url"
         value="resolve-uri($this-schematron-url, $doc-parent-directory)"/>
      <let name="this-schematron"
         value="
            if (doc-available($this-schematron-resolved-url)) then
               doc($this-schematron-resolved-url)
            else
               ()"/>
      <report test="true()" role="info"
         ><!-- Information about elements that support editing help will be listed at the rootmost element -->Help
         available: <xsl:value-of
            select="
               for $i in $this-schematron//sch:rule,
                  $j in $i/@context,
                  $k in $i/(sch:assert, sch:report)/comment()
               return
                  concat('(', $j, ':) ', replace($k, '\$help-trigger', $help-trigger), ' ')"
         />
      </report>
   </rule>
   <rule context="tan:div-ref | tan:anchor-div-ref">
      <let name="this-ref" value="normalize-space(replace(@ref, $help-trigger-regex, ''))"/>
      <let name="this-src" value="normalize-space(replace(@src, $help-trigger-regex, ''))"/>
      <let name="this-src-list" value="tan:src-ids-to-nos($this-src)"/>
      <let name="src-help-requested" value="matches(@src, $help-trigger-regex)"/>
      <let name="ref-help-requested" value="matches(@ref, $help-trigger-regex)"/>
      <let name="these-sources-resolved" value="$src-1st-da-data[position() = $this-src-list]"/>
      <let name="is-implicit"
         value="
            if ($this-src-list = $src-impl-div-types) then
               true()
            else
               false()"/>
      <let name="these-refs-norm"
         value="
            for $i in $this-src-list
            return
               if ($i = $src-impl-div-types) then
                  tan:normalize-impl-refs($this-ref, $i)
               else
                  tan:normalize-refs($this-ref)"/>
      <let name="these-atomic-refs"
         value="
            distinct-values(for $i in $these-refs-norm
            return
               tokenize($i, ' [-,] '))"/>
      <let name="ref-identifies-what-divs"
         value="$these-sources-resolved/tan:div[@ref = $these-atomic-refs]"/>
      <let name="possible-corrected-refs"
         value="
            for $i in $these-refs-norm
            return
               if ($is-implicit = true()) then
                  $these-sources-resolved/tan:div[matches(@impl-ref, $i)]/@impl-ref
               else
                  $these-sources-resolved/tan:div[matches(@ref, $i)]/@ref"
      />
      <!--<let name="refs-that-fail" value="$these-atomic-refs[not(. = $ref-identifies-what-divs/@ref)]"/>-->
      <let name="possible-common-corrected-refs"
         value="distinct-values($possible-corrected-refs[count(index-of($possible-corrected-refs, .)) ge count($this-src-list)])"/>
      <let name="search-report"
         value="
            concat('(case ', if ($searches-are-case-sensitive = true()) then
               ()
            else
               'in', 'sensitive, accent ', if ($searches-ignore-accents = true()) then
               'in'
            else
               (), 'sensitive)')"/>
      <let name="this-ref-as-regex-search"
         value="
            if ($searches-ignore-accents = true()) then
               tan:expand-search($this-ref)
            else
               $this-ref"/>
      <let name="matched-refs"
         value="$these-sources-resolved/tan:div[matches(., $this-ref-as-regex-search, $match-flags)]"/>

      <report test="$ref-help-requested and exists($possible-common-corrected-refs)"
         sqf:fix="get-div-refs-from-hints get-div-text-from-search fetch-content"
         ><!-- Putting $help-trigger in @ref with a partial match on a div ref will return suggested alternatives -->Perhaps
         you mean: <xsl:value-of select="$possible-common-corrected-refs"/></report>
      <report
         test="not(exists($ref-identifies-what-divs)) and not(exists($possible-common-corrected-refs))"
         sqf:fix="get-div-text-from-search"
            ><!-- @ref with no match on a div ref will return suggested divs whose texts match the value of @ref (treated as a regular expression) --><xsl:value-of
            select="$this-ref"/>
         <xsl:value-of select="$search-report"/> found in: <xsl:value-of
            select="
               for $i in $src-ids[position() = $this-src-list]
               return
                  concat(string-join(if ($is-implicit = true()) then
                     $matched-refs[../@id = $i]/@impl-ref
                  else
                     $matched-refs[../@id = $i]/@ref, ' '),
                  ' (', $i, ') ')"
         /></report>
      <report test="$ref-help-requested = true() and exists($ref-identifies-what-divs)"
         sqf:fix="fetch-content"><!-- Putting $help-trigger in @ref with an exact match on a div ref will return either the text of the chosen div or the references to children div refs -->
         <xsl:value-of
            select="
               for $i in $ref-identifies-what-divs
               return
                  if (exists($i/text())) then
                     concat('(', $i/@ref, ':) ', $i/text(), ' ')
                  else
                     concat('(', $i/@ref, ':) ',
                     string-join(if ($is-implicit = true()) then
                        $these-sources-resolved/tan:div[@ref = $i/@ref]/following-sibling::*[matches(@ref, $i/@ref)]/@impl-ref
                     else
                        $these-sources-resolved/tan:div[@ref = $i/@ref]/following-sibling::*[matches(@ref, $i/@ref)]/@ref, ' '
                     ), ' ')"
         /></report>
      <report test="$src-help-requested">Sources available: <xsl:value-of select="$src-ids"
         /></report>

      <!-- SCHEMATRON QUICK FIXES -->
      <sqf:fix id="fetch-content" use-when="exists($ref-identifies-what-divs)">
         <sqf:description>
            <sqf:title>Append text content of the divs being referred to</sqf:title>
            <sqf:p>Selecting this option will insert for every reference in every source a
               tan:comment element as a following sibling with the textual content.</sqf:p>
         </sqf:description>
         <sqf:delete match="text()"/>
         <sqf:add match="." position="after">
            <xsl:for-each select="$ref-identifies-what-divs">
               <xsl:text>&#xA;</xsl:text>
               <tan:comment when="{current-date()}" who="{$head/tan:agent[1]/@xml:id}"><xsl:value-of
                     select="./text()"/></tan:comment>
            </xsl:for-each>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-div-refs-from-hints">
         <sqf:description>
            <sqf:title>Replace @ref with suggested help values</sqf:title>
            <sqf:p>Suppose you are looking for possible div refs, and you need help on the syntax
               and options. Put '???' in @ref, perhaps after the beginning fragment of a div ref.
               Choosing this quick fix will replace the content of @ref with all possible div
               references common to all sources. </sqf:p>
         </sqf:description>
         <sqf:replace match="@ref" node-type="attribute" target="ref"
            select="string-join($possible-common-corrected-refs, ', ')"/>
      </sqf:fix>
      <sqf:fix id="get-div-text-from-search">
         <sqf:description>
            <sqf:title>Append text content of divs that match @ref as a search pattern</sqf:title>
            <sqf:p>Suppose you are looking for a particular div ref that has a certain keyword. By
               making the content of @ref a regular expression pattern, this quick fix will allow
               you to search for that pattern across the sources mentioned in @src and append
               matching divs as tan:comments.</sqf:p>
         </sqf:description>
         <sqf:add match="." position="after">
            <xsl:for-each select="$matched-refs">
               <xsl:text>&#xA;</xsl:text>
               <tan:div-ref src="{../@id}"
                  ref="{if ($is-implicit = true()) then
                     @impl-ref
                     else
                     @ref}"/>
               <xsl:text>&#xA;</xsl:text>
               <tan:comment when="{current-date()}" who="{$head/tan:agent[1]/@xml:id}"><xsl:value-of
                     select="./text()"/></tan:comment>
            </xsl:for-each>
         </sqf:add>
      </sqf:fix>

   </rule>
</pattern>
