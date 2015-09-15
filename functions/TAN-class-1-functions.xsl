<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Udpated</xd:b>Aug 31, 2015</xd:p>
         <xd:p>Variables and functions for class 1 TAN files (i.e., applicable to multiple class 1
            TAN file types). Written principally for Schematron validation, but suitable for general
            use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:variable name="prep-body" as="element()*">
      <xsl:element name="tan:body">
         <xsl:for-each
            select="
               $body//(tan:div,
               tei:div)[not((tan:div,
               tei:div))]">
            <xsl:variable name="this-flatref" select="tan:flatref(.)"/>
            <xsl:element name="tan:div">
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="ref" select="$this-flatref"/>
               <xsl:attribute name="impl-ref"
                  select="replace($this-flatref, concat('\w+', $separator-type-and-n-regex), '')"/>
               <xsl:copy-of select="normalize-space(string-join(.//text(), ''))"/>
            </xsl:element>
         </xsl:for-each>
      </xsl:element>
   </xsl:variable>
   <xsl:variable name="recommended-tokenizations" as="element()*">
      <!-- Sequence of one element per recommended tokenizations, their first
         document-available location, and the languages covered:
         <recommended-tokenization>
            <location>[URL or ERROR MESSAGE]</location>
            <for-lang>[LANG1 or *]<lang>
            <for-lang>[LANG2]<lang>
            ...
         </tokenization>-->
      <xsl:for-each select="$head/tan:declarations/tan:recommended-tokenization">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:variable name="this-tok-reserved-loc" select="if (@which = $tokenization-which-reserved) then 
               $tokenization-which-reserved-url[index-of($tokenization-which-reserved,current()/@which)] else ()"/>
            <xsl:variable name="this-tok-1st-la"
               select="
                  (for $i in tan:location,
                     $j in resolve-uri($i, $doc-uri)
                  return
                     if (doc-available($j)) then
                        $j
                     else
                        ())[1]"
            />
            <xsl:variable name="this-tok-loc" select="if (exists($this-tok-reserved-loc)) then $this-tok-reserved-loc else
               $this-tok-1st-la"/>
            <xsl:variable name="this-tok-1st-da" select="doc($this-tok-loc)"/>
            <xsl:copy-of select="$this-tok-1st-la"/>
            <xsl:for-each select="$this-tok-1st-da">
               <xsl:variable name="these-langs" select="tan:TAN-R-tok/tan:head/tan:declarations/tan:for-lang"/>
               <xsl:choose>
                  <xsl:when test="exists($these-langs)">
                     <xsl:sequence select="$these-langs"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:element name="for-lang" namespace="tag:textalign.net,2015:ns">*</xsl:element>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </xsl:copy>
      </xsl:for-each>
   </xsl:variable>

   <xsl:function name="tan:locate-modifiers" as="element()?">
      <!-- Locates all modifying letters in a string
         Input: string
         Output: element with the following structure:
         <tan:modifiers>
            <tan:modifier cp="[HEX]" where="[SPACE-SEPARATED NUMBERS IDENTIFYING POSITION IN STRING]"/>
            ....
         </tan:modifiers>
      -->

      <xsl:param name="text" as="xs:string?"/>
      <xsl:variable name="raw-char-seq" select="tokenize(replace($text, '(.)', '$1 '), ' ')"/>
      <xsl:variable name="combchar-seq" select="distinct-values($raw-char-seq[matches(., '\p{M}')])"/>
      <xsl:element name="tan:modifiers">
         <xsl:for-each select="$combchar-seq">
            <xsl:variable name="this-combchar" select="."/>
            <xsl:element name="tan:modifier">
               <xsl:attribute name="cp" select="tan:dec-to-hex(string-to-codepoints(.))"/>
               <xsl:attribute name="where"
                  select="
                     string-join(for $i in index-of($raw-char-seq, $this-combchar)
                     return
                        string($i), ' ')"
               />
            </xsl:element>
         </xsl:for-each>

      </xsl:element>
   </xsl:function>

   <xsl:include href="TAN-core-functions.xsl"/>

</xsl:stylesheet>
