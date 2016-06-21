<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Udpated</xd:b>June 20, 2016</xd:p>
         <xd:p>Variables and functions for class 1 TAN files (i.e., applicable to multiple class 1
            TAN file types). Written principally for Schematron validation, but suitable for general
            use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:function name="tan:get-div-types-in-use" as="element()*">
      <xsl:param name="resolved-class-1-doc" as="document-node()*"/>
      <xsl:for-each select="$resolved-class-1-doc">
         <xsl:variable name="type-ids-in-use"
            select="distinct-values($resolved-class-1-doc/(tei:TEI/tei:text/tei:body, tan:TAN-T/tan:body)//(tan:div, tei:div)/@type)"
         />
         <class-1-doc>
            <xsl:copy-of select="*/@*"/>
            <xsl:copy-of select="*/tan:head/tan:declarations/tan:div-type[@xml:id = $type-ids-in-use]"/>
         </class-1-doc>
      </xsl:for-each>
   </xsl:function>
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

   <xsl:function name="tan:normalize-div-text" as="xs:string">
      <!-- Returns a normalized text, per TAN requirements. It is assumed that each member 
         of the sequence of strings represents the content of a single leaf div, and that the
         user wishes to concatenate them per TAN specifications. Any adjacent leaf divs are joined
         by a space, unless if ZWJ U+200D or SOFT HYPHEN U+AD falls at the end of the first of a pair of leaf divs. In that 
         case, the terminal mark is deleted, no intervening space is introduced, and the text of
         the two divs is effectively fused. After joining all divs, text is space-normalized.
         *** In a future version, this function is likely to probe the semantics of a div, to determine
         whether the space should be SPACE U+20 or END OF LINE U+A. ***
      -->
      <xsl:param name="leaf-divs" as="element()*"/>
      <xsl:variable name="new-sequence" as="xs:string*">
         <xsl:for-each select="$leaf-divs">
            <xsl:choose>
               <xsl:when test="matches(., '[&#x200D;&#xAD;]$')">
                  <xsl:value-of select="replace(., '[&#x200D;&#xAD;]$', '')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="concat(., ' ')"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="normalize-space(string-join($new-sequence,''))"/>
   </xsl:function>

   <xsl:include href="TAN-core-functions.xsl"/>

</xsl:stylesheet>
