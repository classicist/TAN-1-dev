<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Schematron tests for TAN-A-div files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>

   <pattern>
      <!--<rule context="/*">
         <let name="test-var" value="$src-1st-da-data-prepped-for-search[position() = (2, 5)]/*[position() = (1 to 5)]"/>
         <!-\-<let name="test-var" value="$src-1st-da-data-prepped-for-search[5]"/>-\->
         <report test="true()" sqf:fix="get-copy-of-test-var"><xsl:value-of
               select="count($test-var)"/></report>
         <sqf:fix id="get-copy-of-test-var">
            <sqf:description>
               <sqf:title>Get copy of test variable</sqf:title>
            </sqf:description>
            <sqf:add match="/*" select="$test-var" position="after"/>
         </sqf:fix>
      </rule>-->
      <rule context="tan:div-ref | tan:anchor-div-ref">
         <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
         <let name="this-ref" value="@ref"/>
         <let name="these-sources-resolved" value="$src-1st-da-data[position() = $this-src-list]"/>
         <let name="is-implicit"
            value="
               if ($this-src-list = $src-impl-div-types) then
                  true()
               else
                  false()"/>

         <!-- Reference lookup only -->
         <let name="help-asked-on-what-ref" value="normalize-space(replace(@ref, '\?\?\?', ''))"/>
         <let name="this-ref-normalized"
            value="
               if ($is-implicit = true())
               then
                  replace($help-asked-on-what-ref, '\W+', $separator-hierarchy-regex)
               else
                  tan:normalize-ref-punctuation($help-asked-on-what-ref)
               "/>
         <let name="possible-refs"
            value="
               if ($is-implicit = true()) then
                  $these-sources-resolved/tan:div[matches(@impl-ref, concat('^', $this-ref-normalized, $separator-hierarchy-regex, '?\w+$|^', $this-ref-normalized, '\w+$'))]/@impl-ref
               else
                  $these-sources-resolved/tan:div[matches(@ref, concat('^', $this-ref-normalized, '\w*', $separator-type-and-n-regex, '\?\w*', $separator-hierarchy-regex, '?\w+$'))]/@ref"/>
         <let name="possible-common-refs"
            value="distinct-values($possible-refs[count(index-of($possible-refs, .)) ge count($this-src-list)])"/>
         <assert test="$help-asked-on-what-ref = @ref" sqf:fix="get-div-refs-from-hints">Help:
               <xsl:value-of select="$possible-common-refs"/></assert>

         <!-- Regex search for text patterns held by @ref -->
         <let name="this-refs-norm"
            value="
               for $i in $this-src-list
               return
                  if ($i = $src-impl-div-types) then
                     tan:normalize-impl-refs(@ref, $i)
                  else
                     tan:normalize-refs(@ref)"/>
         <let name="these-atomic-refs"
            value="
               distinct-values(for $i in $this-refs-norm
               return
                  tokenize($i, ' [-,] '))"/>
         <let name="ref-is-search-pattern"
            value="
               if ($these-sources-resolved/tan:div[@ref = $these-atomic-refs] or
               not($help-asked-on-what-ref = @ref)) then
                  false()
               else
                  true()"/>
         <let name="search-ignores-accents" value="true()"/>
         <let name="search-is-case-sensitive" value="false()"/>
         <let name="search-report"
            value="
               concat('(case ', if ($search-is-case-sensitive = true()) then
                  ()
               else
                  'in', 'sensitive, accent ', if ($search-ignores-accents = true()) then
                  'in'
               else
                  (), 'sensitive)')"
         />
         <let name="this-ref-as-regex-search"
            value="
               if ($search-ignores-accents = true()) then
                  tan:expand-search($this-ref)
               else
                  $this-ref"
         />
         <let name="search-flags"
            value="
               if ($search-is-case-sensitive = false()) then
                  'i'
               else
                  ()"
         />
         <let name="matched-refs"
            value="$these-sources-resolved/tan:div[matches(., $this-ref-as-regex-search, $search-flags)]"
         />
         <report test="$ref-is-search-pattern = true()" sqf:fix="get-div-text-from-search"
               ><xsl:value-of select="$this-ref"/> 
            <xsl:value-of select="$search-report"/> found in: 
            <xsl:value-of
               select="
                  for $i in $src-ids[position() = $this-src-list]
                  return
                     concat(string-join(if ($is-implicit = true()) then
                        $matched-refs[../@id = $i]/@impl-ref
                     else
                        $matched-refs[../@id = $i]/@ref, ' '),
                     ' (', $i, ') ')"
            /></report>

         <sqf:fix id="get-div-refs-from-hints">
            <sqf:description>
               <sqf:title>Replace @ref with suggested help values</sqf:title>
               <sqf:p>Suppose you are looking for possible div refs, and you need help on the syntax
                  and options. Put '???' in @ref, perhaps after the beginning fragment of a div ref.
                  Choosing this quick fix will replace the content of @ref with all possible div
                  references common to all sources. </sqf:p>
            </sqf:description>
            <sqf:replace match="@ref" node-type="attribute" target="ref"
               select="string-join($possible-common-refs, ', ')"/>
         </sqf:fix>
         <sqf:fix id="get-div-text-from-search">
            <sqf:description>
               <sqf:title>Append text content of divs that match @ref as a search
                  pattern</sqf:title>
               <sqf:p>Suppose you are looking for a particular div ref that has a certain keyword.
                  By making the content of @ref a regular expression pattern, this quick fix will
                  allow you to search for that pattern across the sources mentioned in @src and
                  append matching divs as tan:comments.</sqf:p>
            </sqf:description>
            <sqf:add match="." position="after">
               <xsl:for-each select="$matched-refs">
                  <xsl:text>&#xA;</xsl:text>
                  <tan:div-ref src="{../@id}"
                     ref="{if ($is-implicit = true()) then
                     @impl-ref
                     else
                     @ref}"
                  />
                  <xsl:text>&#xA;</xsl:text>
                  <tan:comment when="{current-date()}" who="{$head/tan:agent[1]/@xml:id}"
                        ><xsl:value-of select="./text()"/></tan:comment>
               </xsl:for-each>
            </sqf:add>
         </sqf:fix>

         <!-- Testing -->
         <let name="test-var" value="$this-ref-as-regex-search"/>
         <report test="false()"><xsl:value-of select="$test-var"/></report>

      </rule>
   </pattern>

   <!-- FUNCTIONS -->
   <!--<xsl:include href="../functions/TAN-core-functions.xsl"/>-->
   <xsl:include href="../functions/TAN-A-div-edit-functions.xsl"/>
</schema>
