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

   <xsl:template match="node()" mode="prep-tan-key tan-key-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="/*" mode="prep-tan-key">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="prep-tan-key">
            <xsl:with-param name="is-reserved"
               select="matches(@id, '^tag:textalign.net,2015:tan-key:')" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:item" mode="prep-tan-key">
      <xsl:param name="is-reserved" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="affected-element"
         select="(ancestor-or-self::*[@affects-element])[last()]/@affects-element"/>
      <xsl:variable name="reserved-keyword-doc"
         select="$TAN-keywords[tan:TAN-key/tan:body/@affects-element = $affected-element]"/>
      <xsl:variable name="reserved-keyword-items"
         select="
            if (exists($reserved-keyword-doc)) then
               key('item-via-node-name', $affected-element, $reserved-keyword-doc)
            else
               ()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!--<test><xsl:copy-of select="$affected-element"/></test>-->
         <xsl:if
            test="($is-reserved = true()) and (not(exists(tan:IRI[starts-with(., $TAN-namespace)]))) and (not(exists(tan:token-definition)))">
            <xsl:variable name="this-fix" as="element()">
               <IRI><xsl:value-of select="$TAN-namespace"/></IRI>
            </xsl:variable>
            <xsl:copy-of select="tan:error('tky04', (), $this-fix)"/>
         </xsl:if>
         <xsl:apply-templates mode="prep-tan-key">
            <xsl:with-param name="reserved-keyword-items" select="$reserved-keyword-items"/>
            <!--<xsl:with-param name="other-keyword-items" select="$other-keyword-items"/>-->
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:name" mode="prep-tan-key">
      <xsl:param name="reserved-keyword-items" as="element()*"/>
      <xsl:param name="is-reserved" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="this-name" select="."/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="($reserved-keyword-items/tan:name = $this-name) and ($is-reserved = false())">
            <xsl:copy-of select="tan:error('tky01')"/>
         </xsl:if>
         <xsl:if
            test="count($body//tan:name[. = $this-name][(ancestor-or-self::*/@affects-element)[last()] = ($this-name/ancestor-or-self::*/@affects-element)[last()]]) gt 1">
            <xsl:copy-of select="tan:error('tky02')"/>
         </xsl:if>
         <!--<test>
            <xsl:copy-of select="$keys-1st-da"/>
         </test>-->
         <xsl:apply-templates mode="prep-tan-key"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:IRI[parent::tan:item]" mode="prep-tan-key">
      <xsl:variable name="this-IRI" select="."/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="count($body//tan:IRI[. = $this-IRI]) gt 1">
            <xsl:copy-of select="tan:error('tan09')"/>
         </xsl:if>
         <xsl:apply-templates mode="prep-tan-key"/>
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
         <xsl:apply-templates mode="tan-key-errors"/>
      </xsl:copy>
   </xsl:template>

   <xsl:variable name="all-body-iris" select="$body//tan:IRI"/>

</xsl:stylesheet>
