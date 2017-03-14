<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>March 2017</xd:p>
         <xd:p>Core variables and functions for class 2 and 3 TAN files (i.e., not applicable to
            class 3 TAN file types). Written principally for Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:function name="tan:data-type-check" as="xs:boolean">
      <!-- Input: an item and a string corresponding to a data type -->
      <!-- Output: a boolean indicating whether the item can be cast into that data type -->
      <xsl:param name="item" as="item()?"/>
      <xsl:param name="data-type" as="xs:string"/>
      <xsl:choose>
         <xsl:when test="$data-type = 'string'">
            <xsl:value-of select="$item castable as xs:string"/>
         </xsl:when>
         <xsl:when test="$data-type = 'boolean'">
            <xsl:value-of select="$item castable as xs:boolean"/>
         </xsl:when>
         <xsl:when test="$data-type = 'decimal'">
            <xsl:value-of select="$item castable as xs:decimal"/>
         </xsl:when>
         <xsl:when test="$data-type = 'float'">
            <xsl:value-of select="$item castable as xs:float"/>
         </xsl:when>
         <xsl:when test="$data-type = 'double'">
            <xsl:value-of select="$item castable as xs:double"/>
         </xsl:when>
         <xsl:when test="$data-type = 'duration'">
            <xsl:value-of select="$item castable as xs:duration"/>
         </xsl:when>
         <xsl:when test="$data-type = 'dateTime'">
            <xsl:value-of select="$item castable as xs:dateTime"/>
         </xsl:when>
         <xsl:when test="$data-type = 'time'">
            <xsl:value-of select="$item castable as xs:time"/>
         </xsl:when>
         <xsl:when test="$data-type = 'date'">
            <xsl:value-of select="$item castable as xs:date"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gYearMonth'">
            <xsl:value-of select="$item castable as xs:gYearMonth"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gYear'">
            <xsl:value-of select="$item castable as xs:gYear"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gMonthDay'">
            <xsl:value-of select="$item castable as xs:gMonthDay"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gDay'">
            <xsl:value-of select="$item castable as xs:gDay"/>
         </xsl:when>
         <xsl:when test="$data-type = 'gMonth'">
            <xsl:value-of select="$item castable as xs:gMonth"/>
         </xsl:when>
         <xsl:when test="$data-type = 'hexBinary'">
            <xsl:value-of select="$item castable as xs:hexBinary"/>
         </xsl:when>
         <xsl:when test="$data-type = 'base64Binary'">
            <xsl:value-of select="$item castable as xs:base64Binary"/>
         </xsl:when>
         <xsl:when test="$data-type = 'anyURI'">
            <xsl:value-of select="$item castable as xs:anyURI"/>
         </xsl:when>
         <xsl:when test="$data-type = 'QName'">
            <xsl:value-of select="$item castable as xs:QName"/>
         </xsl:when>
         <xsl:when test="$data-type = 'normalizedString'">
            <xsl:value-of select="$item castable as xs:normalizedString"/>
         </xsl:when>
         <xsl:when test="$data-type = 'token'">
            <xsl:value-of select="$item castable as xs:token"/>
         </xsl:when>
         <xsl:when test="$data-type = 'language'">
            <xsl:value-of select="$item castable as xs:language"/>
         </xsl:when>
         <xsl:when test="$data-type = 'NMTOKEN'">
            <xsl:value-of select="$item castable as xs:NMTOKEN"/>
         </xsl:when>
         <xsl:when test="$data-type = 'NMTOKENS'">
            <xsl:value-of select="$item castable as xs:NMTOKENS"/>
         </xsl:when>
         <xsl:when test="$data-type = 'Name'">
            <xsl:value-of select="$item castable as xs:Name"/>
         </xsl:when>
         <xsl:when test="$data-type = 'NCName'">
            <xsl:value-of select="$item castable as xs:NCName"/>
         </xsl:when>
         <xsl:when test="$data-type = 'ID'">
            <xsl:value-of select="$item castable as xs:ID"/>
         </xsl:when>
         <xsl:when test="$data-type = 'IDREF'">
            <xsl:value-of select="$item castable as xs:IDREF"/>
         </xsl:when>
         <xsl:when test="$data-type = 'IDREFS'">
            <xsl:value-of select="$item castable as xs:IDREFS"/>
         </xsl:when>
         <xsl:when test="$data-type = 'ENTITY'">
            <xsl:value-of select="$item castable as xs:ENTITY"/>
         </xsl:when>
         <xsl:when test="$data-type = 'ENTITIES'">
            <xsl:value-of select="$item castable as xs:ENTITIES"/>
         </xsl:when>
         <xsl:when test="$data-type = 'integer'">
            <xsl:value-of select="$item castable as xs:integer"/>
         </xsl:when>
         <xsl:when test="$data-type = 'nonPositiveInteger'">
            <xsl:value-of select="$item castable as xs:nonPositiveInteger"/>
         </xsl:when>
         <xsl:when test="$data-type = 'negativeInteger'">
            <xsl:value-of select="$item castable as xs:negativeInteger"/>
         </xsl:when>
         <xsl:when test="$data-type = 'long'">
            <xsl:value-of select="$item castable as xs:long"/>
         </xsl:when>
         <xsl:when test="$data-type = 'int'">
            <xsl:value-of select="$item castable as xs:int"/>
         </xsl:when>
         <xsl:when test="$data-type = 'short'">
            <xsl:value-of select="$item castable as xs:short"/>
         </xsl:when>
         <xsl:when test="$data-type = 'byte'">
            <xsl:value-of select="$item castable as xs:byte"/>
         </xsl:when>
         <xsl:when test="$data-type = 'nonNegativeInteger'">
            <xsl:value-of select="$item castable as xs:nonNegativeInteger"/>
         </xsl:when>
         <xsl:when test="$data-type = 'unsignedLong'">
            <xsl:value-of select="$item castable as xs:unsignedLong"/>
         </xsl:when>
         <xsl:when test="$data-type = 'unsignedInt'">
            <xsl:value-of select="$item castable as xs:unsignedInt"/>
         </xsl:when>
         <xsl:when test="$data-type = 'unsignedShort'">
            <xsl:value-of select="$item castable as xs:unsignedShort"/>
         </xsl:when>
         <xsl:when test="$data-type = 'unsignedByte'">
            <xsl:value-of select="$item castable as xs:unsignedByte"/>
         </xsl:when>
         <xsl:when test="$data-type = 'positiveInteger'">
            <xsl:value-of select="$item castable as xs:positiveInteger"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="false()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:template match="node()" mode="prep-tan-mor prep-tan-claims">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:claim" mode="prep-tan-claims">
      <xsl:variable name="this-verb-ids" select="tokenize(@verb, '\s+')"/>
      <xsl:variable name="these-verbs"
         select="/*/tan:head/tan:declarations/tan:verb[@xml:id = $this-verb-ids]"/>
      <xsl:variable name="these-verbs-with-object-constraints"
         select="$these-verbs[exists(@object-datatype)]"/>
      <xsl:variable name="verbal-groups"
         select="
            for $i in $these-verbs
            return
               tokenize($i/@orig-group, '\s+')"
      />
      <xsl:variable name="attr-object-idrefs" select="tokenize(@object, '\s+')"/>
      <xsl:variable name="object-targets"
         select="/*/tan:head//tan:*[@xml:id = $attr-object-idrefs]"/>
      <xsl:variable name="objects-that-are-not-textual" select="$object-targets[not(name() = ('person', 'agent', 'scriptum', 'work', 'version'))]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($these-verbs-with-object-constraints)">
            <xsl:if test="exists(@object) or not(exists(tan:object))">
               <xsl:copy-of select="tan:error('clm01')"/>
            </xsl:if>
            <xsl:if test="count($these-verbs) gt 1">
               <xsl:copy-of select="tan:error('clm02')"/>
            </xsl:if>
         </xsl:if>
         <xsl:if test="not(exists(@subject)) and not(exists(ancestor::tan:body/@subject)) and not(exists(tan:subject))">
            <xsl:copy-of select="tan:error('clm05')"/>
         </xsl:if>
         <xsl:if test="not(exists(@verb)) and not(exists(ancestor::tan:body/@verb))">
            <xsl:copy-of select="tan:error('clm07')"/>
         </xsl:if>
         <xsl:if
            test="not(exists(@object)) and not(exists(tan:object) or exists(tan:claim)) and $verbal-groups = 'object-required'">
            <xsl:copy-of select="tan:error('clm06', 'object is required')"/>
         </xsl:if>
         <xsl:if test="$verbal-groups = 'text-object' and (not(exists(tan:object//@ref)) or exists($objects-that-are-not-textual))">
            <xsl:copy-of select="tan:error('clm06', 'objects must be textual')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="verbs" select="$these-verbs"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:object" mode="prep-tan-claims">
      <xsl:param name="verbs" as="element()*"/>
      <xsl:variable name="this-text" select="text()[matches(.,'\S')][1]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each select="$verbs[@object-datatype]">
            <xsl:variable name="this-datatype" select="@object-datatype"/>
            <xsl:variable name="this-lexical-constraint" select="@object-lexical-constraint"/>
            <xsl:if test="not(tan:data-type-check($this-text, $this-datatype))">
               <xsl:variable name="help-message" select="concat('value must match data type ', $this-datatype)"/>
               <xsl:copy-of select="tan:error('clm03', $help-message)"/>
            </xsl:if>
            <xsl:if test="exists($this-lexical-constraint) and not(matches($this-text, $this-lexical-constraint))">
               <xsl:variable name="help-message" select="concat('value must match pattern ', $this-lexical-constraint)"/>
               <xsl:copy-of select="tan:error('clm04', $help-message)"/>
            </xsl:if>
         </xsl:for-each>

         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:function name="tan:prep-TAN-claims" as="document-node()*">
      <!-- Input: resolved TAN documents that take claims -->
      <!-- Output: the same documents, marking <claim>s for errors -->
      <xsl:param name="TAN-docs-resolved" as="document-node()*"/>
      <xsl:for-each select="$TAN-docs-resolved">
         <xsl:document>
            <xsl:apply-templates mode="prep-tan-claims"/>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>

   <xsl:template match="tan:feature" mode="prep-tan-mor">
      <xsl:param name="duplicate-codes" as="xs:string*"/>
      <xsl:param name="inclusions-resolved" tunnel="yes"/>
      <xsl:variable name="include-val" select="@include"/>
      <xsl:variable name="feature-inclusions" select="$inclusions-resolved[*/@incl = $include-val]"/>
      <xsl:variable name="declared-languages" select="ancestor::tan:body/tan:for-lang"/>
      <xsl:variable name="inappropriate-feature-inclusions"
         select="
            $feature-inclusions[some $i in $declared-languages
               satisfies not(tan:TAN-mor/tan:body/tan:for-lang = $i)]"/>
      <!--<xsl:param name="inappropriate-feature-inclusions" as="document-node()*"/>-->
      <xsl:variable name="is-first-include"
         select="not(exists(preceding-sibling::tan:feature[@include = $include-val]))"/>
      <xsl:variable name="these-ifis"
         select="$inappropriate-feature-inclusions[tan:TAN-mor/@incl = $include-val]"/>
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
      <xsl:variable name="codes-norm" as="xs:string*"
         select="
            for $i in $codes-raw
            return
               lower-case(tan:normalize-text($i))"/>
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
      <xsl:variable name="attr-context-items" select="tokenize($attr-context-norm, ' ')"/>
      <xsl:variable name="attr-feature-test-groups"
         select="tan:feature-test-to-groups(@feature-test)" as="element()*"/>
      <xsl:variable name="faulty-attr-context" select="$attr-context-items[not(. = $codes-norm)]"/>
      <xsl:variable name="faulty-attr-feature-test-items"
         select="$attr-feature-test-groups/tan:item[not(. = $codes-norm)]" as="element()*"/>
      <xsl:variable name="feature-count" select="count(..//tan:feature)"/>
      <xsl:variable name="feature-qty-test"
         select="
            if (exists(@feature-qty-test)) then
               tan:sequence-expand(tan:normalize-text(@feature-qty-test), $feature-count)
            else
               ()"/>
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
         <xsl:if test="$feature-qty-test = (-2, -1 - 0)">
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

   <xsl:function name="tan:prep-TAN-mor" as="document-node()*">
      <!-- One-param version of the function below -->
      <xsl:param name="TAN-mor-docs-resolved" as="document-node()*"/>
      <xsl:for-each select="$TAN-mor-docs-resolved">
         <xsl:variable name="is-self" select="$doc-id = /*/@id"/>
         <xsl:variable name="these-inclusions"
            select="
               if ($is-self = true()) then
                  $inclusions-1st-da
               else
                  tan:resolve-doc(tan:get-1st-doc(/*/tan:head/tan:inclusion), false(), 'incl', /*/tan:head/tan:inclusion/@xml:id, (), ())"/>
         <xsl:copy-of select="tan:prep-TAN-mor(., $these-inclusions)"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:prep-TAN-mor" as="document-node()*">
      <!-- Input: resolved TAN-mor documents -->
      <!-- Output: the same documents, after the inclusions have been resolved -->
      <xsl:param name="TAN-mor-docs-resolved" as="document-node()*"/>
      <xsl:param name="TAN-mor-doc-inclusions-resolved" as="document-node()*"/>
      <xsl:for-each select="$TAN-mor-docs-resolved">
         <xsl:document>
            <xsl:apply-templates mode="prep-tan-mor">
               <xsl:with-param name="inclusions-resolved" select="$TAN-mor-doc-inclusions-resolved"
                  tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>


   <xsl:function name="tan:feature-test-to-groups" as="element()*">
      <!-- Input: any value of @feature-test -->
      <!-- Output: the value converted into a series of <group>ed <item>s, observing the accepted syntax for this attribute -->
      <!-- Example: "a b + c" - > 
               <group>
                  <item>a</item>
               </group>
               <group>
                  <item>b</item>
                  <item>c</item>
               </group>
 -->
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
