<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   exclude-result-prefixes="xs math xd tan fn tei functx sch" version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>September 3, 2016</xd:p>
         <xd:p>Variables, functions, and templates for marking errors in TAN class 2 files. To be
            used in conjunction with TAN-core-functions.xsl. Includes items related to help
            requests.</xd:p>
      </xd:desc>
   </xd:doc>

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
                  <group>
                     <xsl:copy-of select="current-group()"/>
                  </group>
               </xsl:for-each-group>
            </xsl:for-each-group>
         </xsl:for-each-group>
      </results>
   </xsl:function>
   <xsl:template match="tan:body" mode="class-2-errors">
      <xsl:variable name="split-leaf-div-at-toks-grouped"
         select="tan:group-tok-elements(tan:split-leaf-div-at/tan:tok)" as="element()"/>
      <xsl:variable name="realign-div-refs-grouped" as="element()">
         <!-- This variable is meant primarily to identify where there
         have been <div>s that have been duplicately realigned. For nonleaf <div>s
         it is pretty straightforward just to group the <div>s. But in leaf <div>s
         one must determine which segments are duplicates. Therfore the variable contains
         <seg> and not <div> in those cases. -->
         <rdf>
            <xsl:for-each-group select="tan:realign/(tan:div-ref, tan:anchor-div-ref)"
               group-by="@src">
               <xsl:variable name="this-src" select="current-grouping-key()"/>
               <xsl:for-each-group select="current-group()//tan:div" group-by="@ref">
                  <group src="{$this-src}" ref="{current-grouping-key()}">
                     <xsl:for-each select="current-group()">
                        <xsl:choose>
                           <xsl:when test="exists(tan:seg)">
                              <xsl:copy-of select="tan:seg"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:copy>
                                 <xsl:copy-of select="@*"/>
                              </xsl:copy>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:for-each>
                  </group>
               </xsl:for-each-group>
            </xsl:for-each-group>
         </rdf>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!--<test>
            <xsl:copy-of select="$realign-div-refs-grouped"/>
         </test>-->
         <xsl:apply-templates mode="class-2-errors">
            <xsl:with-param name="split-leaf-div-at-toks-grouped" tunnel="yes"
               select="$split-leaf-div-at-toks-grouped"/>
            <xsl:with-param name="realign-div-refs-grouped" tunnel="yes"
               select="$realign-div-refs-grouped"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:split-leaf-div-at/tan:tok" mode="class-2-errors">
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
         <xsl:apply-templates mode="class-2-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:realign/tan:div-ref | tan:realign/tan:anchor-div-ref"
      mode="class-2-errors">
      <xsl:param name="realign-div-refs-grouped" tunnel="yes" as="element()?"/>
      <xsl:variable name="this-element" select="."/>
      <!--<xsl:variable name="these-leaf-divs" select="$this-element//tan:div[not(tan:div)]"/>-->
      <xsl:variable name="this-rdf-group"
         select="
            $realign-div-refs-grouped/tan:group[@src = $this-element/@src
            and @ref = $this-element//@ref]"/>
      <xsl:variable name="duplicated-segs"
         select="$this-rdf-group/tan:seg[@n = preceding-sibling::tan:seg/@n]"/>
      <xsl:variable name="duplicated-nonleaf-divs" select="$this-rdf-group[count(tan:div) gt 1]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($duplicated-segs) or exists($duplicated-nonleaf-divs)">
            <xsl:variable name="this-message">
               <xsl:choose>
                  <xsl:when test="exists($duplicated-segs)">
                     <xsl:value-of
                        select="
                           string-join(for $i in $duplicated-segs
                           return
                              concat($i/../@src, ': ', $i/../@ref, ' seg no. ', $i/@n), '; ')"
                     />
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:value-of
                        select="
                           string-join(for $i in $duplicated-nonleaf-divs
                           return
                              concat($i/@src, ': ', $i/@ref), '; ')"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <!--<xsl:variable name="this-message1"
               select="
                  string-join(for $i in $duplicated-leaf-div-refs
                  return
                     concat($i/@src, ': ', $i/@ref, ' seg no. ', $i/@seg), '; ')"
            />-->
            <xsl:copy-of select="tan:error('rea01', $this-message)"/>
         </xsl:if>
         <xsl:copy-of select="*//tan:error"/>
         <!--<test><xsl:copy-of select="$this-rdf-group"/></test>-->
         <xsl:apply-templates mode="class-2-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:ana | tan:align" mode="class-2-errors">
      <xsl:variable name="these-toks-grouped" select="tan:group-tok-elements(tan:tok)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!--<test><xsl:copy-of select="$these-toks-grouped"/></test>-->
         <xsl:if test="self::tan:ana/@xml:id and count(tan:tok) gt 1">
            <xsl:copy-of select="tan:error('tlm01')"/>
         </xsl:if>
         <xsl:apply-templates mode="class-2-errors">
            <xsl:with-param name="sibling-toks-grouped" select="$these-toks-grouped"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:ana/tan:tok | tan:align/tan:tok" mode="class-2-errors">
      <xsl:param name="sibling-toks-grouped" as="element()?"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-tok-group"
         select="
            $sibling-toks-grouped/tan:group[tan:tok[@src = $this-element/@src
            and @ref = $this-element//@ref and @n = $this-element/@n]]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="count($this-tok-group/*) gt 1">
            <xsl:copy-of select="tan:error('cl211')"/>
         </xsl:if>
         <!--<test><xsl:copy-of select="$this-tok-group"/></test>-->
         <xsl:apply-templates mode="class-2-errors"/>
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
