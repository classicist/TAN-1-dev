<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Created on:</xd:b> September 16, 2016</xd:p>
         <xd:p><xd:b>Author:</xd:b> Joel</xd:p>
         <xd:p>Set of functions for TAN-key files. Used by Schematron validation, but suitable for
            general use in other contexts </xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="incl/TAN-class-3-functions.xsl"/>
   <xsl:include href="incl/TAN-schema-functions.xsl"/>
   <!--<xsl:variable name="self-prepped" select="$self-core-errors-marked"/>-->
   <xsl:variable name="all-body-iris" select="$body//tan:IRI"/>
   <xsl:variable name="self-prepped" as="document-node()">
      <xsl:variable name="pass-1">
         <xsl:document>
            <xsl:apply-templates select="$self-core-errors-marked" mode="prep-tan-key"/>
         </xsl:document>
      </xsl:variable>
      <xsl:document>
         <xsl:apply-templates select="$pass-1" mode="tan-key-errors"/>
      </xsl:document>
   </xsl:variable>

   <xsl:template match="node()" mode="tan-key-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:IRI[parent::tan:item]" mode="tan-key-errors">
      <xsl:variable name="this-IRI" select="."/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="count($all-body-iris[. = $this-IRI]) gt 1">
            <xsl:copy-of select="tan:error('tan09')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="/*" mode="tan-key-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="is-reserved"
               select="matches(@id, '^tag:textalign.net,2015:tan-key:')" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="*[@affects-element]" mode="tan-key-errors">
      <xsl:variable name="these-element-names"
         select="tokenize(tan:normalize-text(@affects-element), ' ')"/>
      <xsl:variable name="bad-element-names"
         select="$these-element-names[not(. = $TAN-elements-that-take-the-attribute-which/@name)]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($bad-element-names)">
            <xsl:copy-of
               select="tan:error('tky03', $TAN-elements-that-take-the-attribute-which/@name)"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:item" mode="tan-key-errors">
      <xsl:param name="is-reserved" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="affected-elements"
         select="tokenize((ancestor-or-self::*[@affects-element])[last()]/@affects-element, '\s+')"
      />
      <xsl:variable name="reserved-keyword-doc"
         select="$TAN-keywords[tan:TAN-key/tan:body[tokenize(@affects-element, '\s+') = $affected-elements]]"
      />
      <xsl:variable name="reserved-keyword-items"
         select="
            if (exists($reserved-keyword-doc)) then
               key('item-via-node-name', $affected-elements, $reserved-keyword-doc)
            else
               ()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if
            test="($is-reserved = true()) and (not(exists(tan:IRI[starts-with(., $TAN-namespace)]))) and (not(exists(tan:token-definition)))">
            <xsl:variable name="this-fix" as="element()">
               <IRI>
                  <xsl:value-of select="$TAN-namespace"/>
               </IRI>
            </xsl:variable>
            <xsl:copy-of select="tan:error('tky04', (), $this-fix)"/>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="reserved-keyword-items" select="$reserved-keyword-items"/>
            <xsl:with-param name="affected-elements" select="$affected-elements"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:name[not(@common)]" mode="tan-key-errors">
      <xsl:param name="reserved-keyword-items" as="element()*"/>
      <xsl:param name="is-reserved" as="xs:boolean?" tunnel="yes"/>
      <xsl:param name="affected-elements"/>
      <xsl:variable name="this-name" select="."/>
      <xsl:variable name="this-common-name" select="following-sibling::tan:name[1][@common]"/>
      <xsl:variable name="name-to-check"
         select="
            if (not(exists($this-common-name))) then
               $this-name
            else
               $this-common-name"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if
            test="($reserved-keyword-items/tan:name = $name-to-check) and ($is-reserved = false())">
            <xsl:copy-of select="tan:error('tky01')"/>
         </xsl:if>
         <xsl:if
            test="count(root(.)/tan:TAN-key/tan:body//tan:name[. = $name-to-check][tokenize((ancestor-or-self::*/@affects-element)[last()],'\s+') = $affected-elements]) gt 1">
            <xsl:copy-of select="tan:error('tky02')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
