<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   exclude-result-prefixes="xs math xd tan fn tei functx sch" version="2.0">

   <xsl:template match="node()" mode="TAN-A-div-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:body" mode="TAN-A-div-errors">
      <xsl:variable name="split-leaf-div-at-toks-grouped"
         select="tan:group-tok-elements(tan:split-leaf-div-at/tan:tok)" as="element()"/>
      <xsl:variable name="anchor-divs" select="tan:realign/tan:anchor-div-ref/tan:div"/>
      
      <xsl:variable name="realigned-divs" select="tan:realign/tan:div-ref/tan:div"/>
      
      <xsl:variable name="anchor-div-refs" as="xs:string*"
         select="
            for $i in $anchor-divs
            return
               concat($i/parent::tan:anchor-div-ref/@src, '#', $i/@ref)"/>
      
      <xsl:variable name="realigned-div-refs" as="xs:string*"
         select="
            for $i in $realigned-divs
            return
               concat($i/parent::tan:div-ref/@src, '#', $i/@ref)"/>
      
      <xsl:variable name="realigned-anchors" select="$anchor-div-refs[. = $realigned-div-refs]"/>
      <xsl:variable name="duplicate-realign-refs" select="tan:duplicate-values($realigned-div-refs)"
      />
      <xsl:variable name="faulty-refs" select="($realigned-anchors, $duplicate-realign-refs)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="split-leaf-div-at-toks-grouped" tunnel="yes"
               select="$split-leaf-div-at-toks-grouped"/>
            <xsl:with-param name="faulty-refs" select="$faulty-refs" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:split-leaf-div-at/tan:tok" mode="TAN-A-div-errors">
      <xsl:param name="split-leaf-div-at-toks-grouped" tunnel="yes" as="element()?"/>
      <xsl:variable name="this-tok" select="."/>
      <xsl:variable name="this-sldatg"
         select="
            $split-leaf-div-at-toks-grouped/tan:group/tan:tok[@src = $this-tok/@src
            and @ref = $this-tok/@ref and @n = $this-tok/@n]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="count($this-sldatg/../*) gt 1">
            <xsl:variable name="this-message"
               select="concat($this-tok/@src, ': ', $this-tok/@ref, ': tok no. ', $this-tok/@n)"/>
            <xsl:copy-of select="tan:error('spl02', $this-message)"/>
         </xsl:if>
         <xsl:apply-templates mode="TAN-A-div-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div-ref | tan:anchor-div-ref" mode="TAN-A-div-errors">
      <xsl:param name="faulty-refs" tunnel="yes" as="xs:string*"/>
      <xsl:variable name="these-div-refs"
         select="
            for $i in tan:div
            return
               concat(@src, '#', $i/@ref)"
      />
      <xsl:variable name="these-faulty-refs" select="$faulty-refs[. = $these-div-refs]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="count($these-faulty-refs) gt 0">
            <xsl:variable name="this-message" as="xs:string*"
               select="
                  for $i in $these-faulty-refs
                  return
                     replace($i, '#', ': ')"
            />
            <xsl:copy-of select="tan:error('rea01', $this-message)"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   

</xsl:stylesheet>
