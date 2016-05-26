<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Created on:</xd:b> June 10, 2015</xd:p>
         <xd:p><xd:b>Author:</xd:b> Joel</xd:p>
         <xd:p>Set of context-dependent functions for TAN-A-tok files. Used by Schematron
            validation, suitable for other contexts only if parameters are honored</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="TAN-class-2-functions.xsl"/>
   <xsl:function name="tan:get-src-1st-da-chars-picked" as="document-node()*">
      <!-- zero-parameter version of the next function -->
      <xsl:copy-of
         select="tan:get-src-1st-da-chars-picked(tan:get-self-expanded-4(), tan:get-src-1st-da-tokenized())"
      />
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-chars-picked" as="document-node()*">
      <xsl:param name="self-expanded-4" as="document-node()?"/>
      <xsl:param name="tokenized-class-1-doc" as="document-node()*"/>
      <xsl:for-each select="$tokenized-class-1-doc">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy>
            <xsl:apply-templates select="node()" mode="char-setup">
               <xsl:with-param name="ref-tok-filter"
                  select="$self-expanded-4/tan:TAN-A-tok/tan:body//tan:tok[tokenize(@src, '\s+') = $this-src]"
               />
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-analysis-stamped" as="document-node()*">
      <xsl:param name="self-expanded-4" as="document-node()?"/>
      <xsl:param name="tokenized-and-charred-class-1-doc" as="document-node()*"/>
      <xsl:for-each select="$tokenized-and-charred-class-1-doc">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy>
            <xsl:apply-templates select="node()" mode="analysis-stamp">
               <xsl:with-param name="ref-tok-filter"
                  select="$self-expanded-4/tan:TAN-A-tok/tan:body//tan:tok[tokenize(@src, '\s+') = $this-src]"
               />
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="analysis-stamp">
      <xsl:param name="ref-tok-filter" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="analysis-stamp">
            <xsl:with-param name="ref-tok-filter" select="$ref-tok-filter"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:tok" mode="analysis-stamp">
      <xsl:param name="ref-tok-filter" as="element()*"/>
      <xsl:variable name="this-ref" select="parent::tan:div/@ref"/>
      <xsl:variable name="this-n" select="(@n, count(preceding-sibling::tan:tok) + 1)[1]"/>
      <xsl:variable name="relevant-filters" select="$ref-tok-filter[@ref = $this-ref][@n = $this-n]"/>
      <xsl:choose>
         <xsl:when test="exists($relevant-filters)">
            <xsl:variable name="class-breadcrumb"
               select="
                  if (exists($relevant-filters[not(@chars)]/ancestor::*/@q)) then
                     for $i in $relevant-filters[not(@chars)]
                     return
                        concat('q', string-join(
                        $i/ancestor::*/@q, '-'))
                  else
                     ()"
            />
            <xsl:variable name="class-reuse"
               select="$relevant-filters[not(@chars)]/ancestor-or-self::*[@reuse-type][1]/@reuse-type"/>
            <xsl:variable name="class-cert"
               select="$relevant-filters[not(@chars)]/ancestor-or-self::*[@cert][1]/@cert"/>
            <xsl:variable name="new-class" select="string-join((@class, $class-breadcrumb, $class-reuse, $class-cert), ' ')"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:if test="exists($new-class)">
                  <xsl:attribute name="class" select="$new-class"/>
               </xsl:if>
               <xsl:apply-templates mode="analysis-stamp">
                  <xsl:with-param name="ref-tok-filter" select="$relevant-filters[@chars]"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="tan:c" mode="analysis-stamp">
      <xsl:param name="ref-tok-filter" as="element()*"/>
      <xsl:variable name="this-n" select="count(preceding-sibling::tan:c) + 1"/>
      <xsl:variable name="relevant-filters"
         select="$ref-tok-filter[tokenize(@chars, '\s+') = string($this-n)]"/>
      <xsl:choose>
         <xsl:when test="exists($relevant-filters)">
            <xsl:variable name="class-breadcrumb"
               select="
                  if (exists($relevant-filters/ancestor::*/@q)) then
                     for $i in $relevant-filters
                     return
                        concat('q', string-join($i/ancestor::*/@q, '-'))
                  else
                     ()"
            />
            <xsl:variable name="class-reuse"
               select="$relevant-filters/ancestor-or-self::*[@reuse-type][1]/@reuse-type"/>
            <xsl:variable name="class-cert"
               select="$relevant-filters/ancestor-or-self::*[@cert][1]/@cert"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="class"
                  select="string-join((@class, $class-breadcrumb, $class-reuse, $class-cert), ' ')"/>
               <xsl:copy-of select="text()"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:function name="tan:analyze-tok-chars" as="element()?">
      <xsl:param name="src-tok-element" as="element()?"/>
      <xsl:param name="self-expanded-4-tok-element" as="element()?"/>
      <xsl:variable name="src-tok-norm" as="element()?">
         <xsl:choose>
            <xsl:when test="$src-tok-element/tan:c">
               <xsl:sequence select="$src-tok-element"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="$src-tok-element" mode="char-setup"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="chars-picked"
         select="
            for $i in tokenize($self-expanded-4-tok-element/@chars, ' ')
            return
               xs:integer($i)"
         as="xs:integer*"/>
      <xsl:variable name="class-breadcrumb"
         select="
            if (exists($self-expanded-4-tok-element/ancestor-or-self::*/@q)) then
               concat('q', string-join($self-expanded-4-tok-element/ancestor-or-self::*/@q, '-'))
            else
               ()"/>
      <xsl:variable name="class-reuse"
         select="$self-expanded-4-tok-element/ancestor-or-self::*[@reuse-type][1]/@reuse-type"/>
      <xsl:variable name="class-cert"
         select="$self-expanded-4-tok-element/ancestor-or-self::*[@cert][1]/@cert"/>
      <xsl:for-each select="$src-tok-norm">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="tan:c">
               <xsl:variable name="pos" select="position()"/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:if test="$pos = $chars-picked">
                     <xsl:attribute name="class"
                        select="string-join((@class, $class-breadcrumb, $class-reuse, $class-cert), ' ')"
                     />
                  </xsl:if>
                  <xsl:copy-of select="text()"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
</xsl:stylesheet>
