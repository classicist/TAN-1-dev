<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="2.0">

   <!-- Functions that are not central to validating TAN files, but could be helpful in creating, editing, or reusing them -->
   
   <xsl:param name="bibliography-words-to-ignore" as="xs:string*"
      select="('university', 'press', 'publication')"/>
   <xsl:function name="tan:possible-bibliography-id" as="xs:string">
      <!-- Input: a string with a bibliographic entry -->
      <!-- Output: unique values of the two longest words and the first numeral that looks like a date -->
      <!-- When working with bibliographical data, it is next to impossible to rely upon an exact match to tell whether two citations are for the same item -->
      <!-- Many times, however, the longest word or two, plus the four-digit date, are good ways to try to find matches. -->
      <xsl:param name="bibl-cit" as="xs:string"/>
      <xsl:variable name="this-citation-dates" as="xs:string*">
         <xsl:analyze-string select="$bibl-cit" regex="^\d\d\d\d\D|\D\d\d\d\d\D|\D\d\d\d\d$">
            <xsl:matching-substring>
               <xsl:value-of select="replace(., '\D', '')"/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="this-citation-longest-words" as="xs:string*">
         <xsl:for-each select="tokenize($bibl-cit, '\W+')">
            <xsl:sort select="string-length(.)" order="descending"/>
            <xsl:if test="not(lower-case(.) = $bibliography-words-to-ignore)">
               <xsl:value-of select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of
         select="string-join(distinct-values(($this-citation-longest-words[position() lt 3], $this-citation-dates[1])), ' ')"
      />
   </xsl:function>
   
</xsl:stylesheet>
