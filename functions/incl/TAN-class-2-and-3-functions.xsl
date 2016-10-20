<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>Sept. 10, 2016</xd:p>
         <xd:p>Core variables and functions for class 2 and 3 TAN files (i.e., not applicable to
            class 3 TAN file types). Written principally for Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:function name="tan:prep-TAN-mor" as="document-node()*">
      <xsl:param name="TAN-mor-docs-resolved" as="document-node()*"/>
      <xsl:for-each select="$TAN-mor-docs-resolved">
         <xsl:variable name="is-self" select="$doc-id = /*/@id"/>
         <xsl:variable name="these-inclusions"
            select="
               if ($is-self = true()) then
                  $inclusions-1st-da
               else
                  tan:resolve-doc(tan:get-1st-doc(/*/tan:head/tan:inclusion), false(), 'incl', /*/tan:head/tan:inclusion/@xml:id, (), ())"
         />
         <xsl:copy-of select="tan:prep-TAN-mor(.,$these-inclusions)"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:prep-TAN-mor" as="document-node()*">
      <xsl:param name="TAN-mor-docs-resolved" as="document-node()*"/>
      <xsl:param name="TAN-mor-doc-inclusions-resolved" as="document-node()*"/>
      <xsl:for-each select="$TAN-mor-docs-resolved">
         <xsl:document>
            <xsl:apply-templates mode="prep-tan-mor">
               <xsl:with-param name="inclusions-resolved" select="$TAN-mor-doc-inclusions-resolved" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="prep-tan-mor">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="prep-tan-mor"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:feature" mode="prep-tan-mor">
      <xsl:param name="duplicate-codes" as="xs:string*"/>
      <xsl:param name="inclusions-resolved" tunnel="yes"/>
      <xsl:variable name="include-val" select="@include"/>
      <xsl:variable name="feature-inclusions" select="$inclusions-resolved[*/@incl = $include-val]"/>
      <xsl:variable name="declared-languages" select="ancestor::tan:body/tan:for-lang"/>
      <xsl:variable name="inappropriate-feature-inclusions"
         select="
            $feature-inclusions[some $i in $declared-languages
               satisfies not(tan:TAN-mor/tan:body/tan:for-lang = $i)]"
      />
      <!--<xsl:param name="inappropriate-feature-inclusions" as="document-node()*"/>-->
      <xsl:variable name="is-first-include" select="not(exists(preceding-sibling::tan:feature[@include = $include-val]))"/>
      <xsl:variable name="these-ifis" select="$inappropriate-feature-inclusions[tan:TAN-mor/@incl = $include-val]"/>
      <xsl:variable name="this-code" select="lower-case(tan:normalize-text(@code))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="code" select="$this-code"/>
         <xsl:if test="exists($include-val) and exists($these-ifis) and $is-first-include = true()">
            <xsl:copy-of
               select="tan:error('tmo01', concat('supports only these languages: ', string-join($these-ifis/tan:TAN-mor/tan:head/tan:declarations/tan:for-lang, ' ')))"
            />
         </xsl:if>
         <xsl:if test="$this-code = $duplicate-codes">
            <xsl:copy-of select="tan:error('tmo02')"/>
         </xsl:if>
         <xsl:apply-templates mode="prep-tan-mor"/>
      </xsl:copy>
   </xsl:template>
   <!--<xsl:template match="tan:body" mode="prep-tan-mor">
      <xsl:variable name="codes-raw"
         select="tan:option/@code, /tan:TAN-mor/tan:head/tan:declarations/tan:feature/@xml:id"/>
      <xsl:variable name="codes-norm" as="xs:string*" select="for $i in $codes-raw return lower-case(tan:normalize-text($i))"/>
      <xsl:variable name="duplicate-codes"
         select="
         if (exists(tan:category)) then
         ()
         else
         tan:duplicate-values($codes-norm)"
      />
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="prep-tan-mor">
            <xsl:with-param name="duplicate-codes" select="$duplicate-codes"/>
            <xsl:with-param name="codes-norm" select="$codes-norm"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>-->
   <xsl:template match="tan:category | tan:body" mode="prep-tan-mor">
      <xsl:variable name="codes-raw" select="tan:feature/@code"/>
      <xsl:variable name="codes-norm" as="xs:string*" select="for $i in $codes-raw return lower-case(tan:normalize-text($i))"/>
      <xsl:variable name="duplicate-codes" select="tan:duplicate-values($codes-norm)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="prep-tan-mor">
            <xsl:with-param name="duplicate-codes" select="$duplicate-codes"/>
            <xsl:with-param name="codes-norm" select="$codes-norm"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <!--<xsl:template match="tan:option" mode="prep-tan-mor">
      <xsl:param name="duplicate-codes" as="xs:string*"/>
      <xsl:variable name="this-code" select="lower-case(tan:normalize-text(@code))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="code" select="lower-case(@code)"/>
         <xsl:if test="$this-code = $duplicate-codes">
            <xsl:copy-of select="tan:error('tmo02')"/>
         </xsl:if>
         <xsl:apply-templates mode="prep-tan-mor"></xsl:apply-templates>
      </xsl:copy>
   </xsl:template>-->
   <xsl:template match="tan:report | tan:assert" mode="prep-tan-mor">
      <xsl:param name="codes-norm" as="xs:string*"/>
      <xsl:variable name="attr-context-norm" select="lower-case(tan:normalize-text(@context))"/>
      <xsl:variable name="attr-context-items" select="tokenize($attr-context-norm,' ')"/>
      <xsl:variable name="attr-feature-test-groups" select="tan:feature-test-to-groups(@feature-test)" as="element()*"/>
      <xsl:variable name="faulty-attr-context" select="$attr-context-items[not(. = $codes-norm)]"/>
      <xsl:variable name="faulty-attr-feature-test-items"
         select="$attr-feature-test-groups/tan:item[not(. = $codes-norm)]" as="element()*"/>
      <xsl:variable name="feature-count" select="count(..//tan:feature)"/>
      <xsl:variable name="feature-qty-test"
         select="
         if (exists(@feature-qty-test)) then
         tan:sequence-expand(tan:normalize-text(@feature-qty-test), $feature-count)
         else
         ()"
      />
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="@context">
            <xsl:attribute name="context" select="$attr-context-norm"/>
         </xsl:if>
         <xsl:if test="@feature-test">
            <xsl:attribute name="feature-test" select="normalize-space(@feature-test)"/>
         </xsl:if>
         <xsl:if test="exists($feature-qty-test)">
            <xsl:attribute name="feature-qty-test" select="$feature-qty-test"/>
         </xsl:if>
         <xsl:if test="exists(($faulty-attr-context))">
            <xsl:copy-of select="tan:error('tmo03', ($faulty-attr-context))"/>
         </xsl:if>
         <xsl:if test="exists(($faulty-attr-feature-test-items))">
            <xsl:copy-of select="tan:error('tmo03', ($faulty-attr-feature-test-items))"/>
         </xsl:if>
         <xsl:if test="$feature-qty-test = (-2, -1- 0)">
            <xsl:if test="$feature-qty-test = 0">
               <xsl:copy-of select="tan:error('seq01', concat('max ', $feature-count))"/>
            </xsl:if>
            <xsl:if test="$feature-qty-test = -1">
               <xsl:copy-of select="tan:error('seq02', concat('max ', $feature-count))"/>
            </xsl:if>
            <xsl:if test="$feature-qty-test = -2">
               <xsl:copy-of select="tan:error('seq03')"/>
            </xsl:if>
         </xsl:if>
         <xsl:apply-templates mode="prep-tan-mor"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:function name="tan:feature-test-to-groups" as="element()*">
      <xsl:param name="attr-feature-test" as="xs:string?"/>
      <xsl:variable name="attr-norm" select="tan:normalize-text($attr-feature-test)"/>
      <xsl:if test="string-length($attr-feature-test) gt 0">
         <xsl:analyze-string select="$attr-feature-test" regex="[^\s\+]+(\s\+\s[^\s\+]+)*">
            <xsl:matching-substring>
               <group>
                  <xsl:for-each select="tokenize(., ' \+ ')">
                     <item>
                        <xsl:value-of select="lower-case(.)"/>
                     </item>
                  </xsl:for-each>
               </group>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:if>
   </xsl:function>
   
</xsl:stylesheet>
