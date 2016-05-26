<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>March 18, 2016</xd:p>
         <xd:p>Intended to be included alongside TAN-class-2-functions.xsl, to facilitate access to
            the class-2 and class-1 documents.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:variable name="ref-filter-tan-a-tok" as="element()*">
      <xsl:for-each-group select="$self3//(tan:tok)" group-by="@ref">
         <tan:tok src="{$head/tan:source[1]/@xml:id}" ref="{current-grouping-key()}"/>
         <tan:tok src="{$head/tan:source[2]/@xml:id}" ref="{current-grouping-key()}"/>
      </xsl:for-each-group> 
   </xsl:variable>
   <xsl:variable name="srcs-prepped-and-filtered-tan-a-tok"
      select="tan:pick-prepped-class-1-data($ref-filter-tan-a-tok, $srcs-prepped, false())"/>
   <xsl:variable name="srcs-tokenized-and-filtered-tan-a-tok"
      select="tan:get-src-1st-da-tokenized($self2, $srcs-prepped-and-filtered-tan-a-tok)"
      as="document-node()*"/>
   <xsl:variable name="srcs-charred-and-filtered"
      select="tan:get-src-1st-da-chars-picked($self4, $srcs-tokenized-and-filtered-tan-a-tok)"/>
   <xsl:variable name="srcs-analyzed-and-filtered"
      select="tan:get-src-1st-da-analysis-stamped($self4, $srcs-charred-and-filtered)"/>


</xsl:stylesheet>
