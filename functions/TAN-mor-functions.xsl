<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>September 10, 2016</xd:p>
         <xd:p>Set of functions for TAN-R-mor files. Used by Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="TAN-class-3-functions.xsl"/>
   
   <xsl:variable name="self-prepped" as="document-node()">
      <xsl:document>
         <xsl:apply-templates select="$self-core-errors-marked" mode="prep-tan-mor"/>
      </xsl:document>
   </xsl:variable>

   <!-- Sept 2016: I think this can be deleted; based on old model -->
   <!--<xsl:function name="tan:feature-test-seq" as="item()+">
      <!-\- Recursive function written for strings normalized by tan:normalize-feature-test().
      Input: sequence of strings created by tan:normalize-feature-test() and an integer indicating the number of the last matched parenthesis
      Output: sequence of feature id-refs, operators, and matched parentheses; the first two returned as strings, 
      the last as integers. 
      E.g., "red, ((noun | adj() | conj), (pres, impv))" - > ('red', ',', 1, 2, 'noun', '|', 
      'adj', 3, 3, '|', 'conj', 2, ',', 2, 'pres', ',' 'impv', 2, 1)-\->
      <xsl:param name="in" as="xs:string"/>
      <xsl:param name="paren-number" as="xs:integer"/>
      <xsl:variable name="in-seq" select="tokenize($in, ' ')"/>
      <xsl:variable name="parens"
         select="
            index-of($in-seq, '('),
            index-of($in-seq, ')')"/>
      <xsl:variable name="first-paren" select="min($parens)"/>
      <xsl:variable name="first-paren-replacement"
         select="
            if (exists($first-paren)) then
               if ($in-seq[$first-paren] = ')') then
                  $paren-number
               else
                  $paren-number + 1
            else
               ()"/>
      <xsl:variable name="next-paren-number"
         select="
            if (exists($first-paren)) then
               if ($first-paren-replacement = $paren-number) then
                  $paren-number - 1
               else
                  $paren-number + 1
            else
               ()"/>
      <xsl:copy-of
         select="
            if (exists($first-paren)) then
               subsequence($in-seq, 1, $first-paren - 1)
            else
               $in-seq"/>
      <xsl:copy-of
         select="
            if (not(exists($first-paren))) then
               ()
            else
               if (exists(subsequence($in-seq, $first-paren + 1)))
               then
                  ($first-paren-replacement,
                  tan:feature-test-seq(string-join(subsequence($in-seq, $first-paren + 1), ' '),
                  $next-paren-number))
               else
                  $first-paren-replacement"
      />
   </xsl:function>-->

</xsl:stylesheet>
