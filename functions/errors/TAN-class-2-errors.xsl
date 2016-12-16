<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   exclude-result-prefixes="xs math xd tan fn tei functx sch" version="2.0">

   <xsl:template match="node()" mode="class-2-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="class-2-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:function name="tan:group-tok-elements" as="element()">
      <xsl:param name="prepped-tok-elements" as="element()*"/>
      <results>
         <xsl:for-each-group select="$prepped-tok-elements" group-by="@src">
            <xsl:for-each-group select="current-group()" group-by="@ref">
               <xsl:for-each-group select="current-group()" group-by="@n">
                  <xsl:choose>
                     <xsl:when test="exists(current-group()/@chars)">
                        <xsl:for-each-group select="current-group()"
                           group-by="tan:sequence-expand((@chars, '1-last')[1], string-length(text()))">
                           <group>
                              <xsl:copy-of select="current-group()"/>
                           </group>
                        </xsl:for-each-group>
                     </xsl:when>
                     <xsl:otherwise>
                        <group>
                           <xsl:copy-of select="current-group()"/>
                        </group>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each-group>
            </xsl:for-each-group>
         </xsl:for-each-group>
      </results>
   </xsl:function>
   <xsl:template match="*[tan:tok]" mode="class-2-errors">
      <xsl:variable name="these-toks-grouped" select="tan:group-tok-elements(tan:tok)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="self::tan:ana/@xml:id and count(tan:tok) gt 1">
            <xsl:copy-of select="tan:error('tlm01')"/>
         </xsl:if>
         <xsl:apply-templates mode="class-2-errors">
            <xsl:with-param name="sibling-toks-grouped" select="$these-toks-grouped"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:tok" mode="class-2-errors">
      <xsl:param name="sibling-toks-grouped" as="element()?"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-tok-group"
         select="
            $sibling-toks-grouped/tan:group[tan:tok[@src = $this-element/@src
            and @ref = $this-element//@ref and @n = $this-element/@n]]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($this-tok-group/*[2])">
            <xsl:copy-of select="tan:error('cl211')"/>
         </xsl:if>
         <!--<test><xsl:copy-of select="$this-tok-group"/></test>-->
         <xsl:apply-templates mode="class-2-errors"/>
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
