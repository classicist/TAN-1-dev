<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated</xd:b>August 20, 2016</xd:p>
         <xd:p>Variables and functions for class 1 TAN files (i.e., applicable to multiple class 1
            TAN file types). Written principally for Schematron validation, but suitable for general
            use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="TAN-core-functions.xsl"/>
   <xsl:include href="TAN-class-1-and-2-functions.xsl"/>
   <xsl:include href="errors/TAN-class-1-errors.xsl"/>

   <!-- CLASS 1 GLOBAL VARIABLES -->
   <xsl:variable name="self-prepped" select="tan:prep-resolved-class-1-doc($self-core-errors-marked)"
      as="document-node()*"/>
   <xsl:variable name="self-leaf-div-flatrefs"
      select="$self-prepped/tan:TAN-T/tan:body//tan:div[not(tan:div)]/@ref"/>
   <xsl:variable name="self-leaf-div-flatref-duplicates"
      select="tan:duplicate-values($self-leaf-div-flatrefs)"/>
   <xsl:variable name="self-class-1-errors-marked" as="document-node()">
      <xsl:variable name="pass1">
         <xsl:document>
            <xsl:apply-templates select="$self-prepped" mode="class-1-errors"/>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="copy-diff"
         select="$pass1/tan:TAN-T/tan:head/tan:see-also/tan:error[@xml:id = 'cl104']/tan:fix/tan:diff"/>
      <xsl:variable name="copy-diff-prep" as="element()?">
         <xsl:apply-templates select="$copy-diff" mode="class-1-copy-errors"/>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="exists($copy-diff)">
            <xsl:document>
               <!--<xsl:copy-of select="$copy-diff-prep"/>-->
               <xsl:apply-templates select="tan:analyze-string-length($pass1, true())"
                  mode="class-1-copy-errors">
                  <xsl:with-param name="copy-diff-prepped" select="$copy-diff-prep" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$pass1"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>

   <!-- Special end div characters are specially designated Unicode characters. If they appear at the end
   of a div, they do not count as part of the character count of the div, and they effectively negate the
   space between that div and the next. This allows characters such as the discretionary hyphen (U+AD SOFT
   HYPHEN) and the ZERO WIDTH JOINER (U+200D) to override the default single space that is assumed to separate
   every <div>
   -->
   <!-- CLASS 1 TRANSFORMATIONS -->

   <!-- Template default actions on all nodes -->
   <xsl:template match="node()" mode="c1-add-ref compare-copies get-mismatched-text mark-splits">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <!-- Template default actions on all nodes except text() -->
   <xsl:template match="* | comment() | processing-instruction()" mode="normalize-space">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:prep-resolved-class-1-doc" as="document-node()*">
      <!-- one-parameter version of the master function kept in TAN-class-1-and-2-functions.xsl -->
      <xsl:param name="class-1-docs-resolved" as="document-node()*"/>
      <xsl:copy-of select="tan:prep-resolved-class-1-doc((), $class-1-docs-resolved)"/>
   </xsl:function>
   <!--<xsl:function name="tan:class-1-add-ref" as="document-node()*">
      <!-\- Input: any class-1 document
         Output: the same document, with @ref added to every div, with the flatref
      -\->
      <xsl:param name="resolved-class-1-doc" as="document-node()*"/>
      <xsl:for-each select="$resolved-class-1-doc">
         <xsl:document>
            <xsl:apply-templates mode="c1-add-ref"/>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>-->
   <!--<xsl:template match="tan:div | tei:div" mode="c1-add-ref">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="ref" select="tan:flatref(.)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>-->


   <xsl:function name="tan:compare-copies" as="document-node()">
      <!-- Input: two class-1 documents, one treated as a master and the other as a copy
      Output: addition of @copy-loc to the first document's leaf divs, indicating at what character number
      a div's text is found in the copy. If it the text is not found in the copy, the corresponding text
      from the copy is placed in @copy-text and @ref, with the faulty div's ref, is returned. 
      This function is useful for diagnosing and fixing discrepancies between copies, especially those
      that have a different segmentation / div structure.
      -->
      <xsl:param name="document" as="document-node()"/>
      <xsl:param name="copy" as="document-node()"/>
      <!--<xsl:variable name="copy-text" select="tan:normalize-div-text($copy//*:body)"/>-->
      <xsl:variable name="copy-text" select="tan:text-join($copy//*:body)"/>
      <!--<xsl:variable name="copy-analyzed" select="tan:analyze-string-length($copy)"/>-->
      <xsl:variable name="pass-1" as="document-node()">
         <xsl:document>
            <xsl:apply-templates select="$document" mode="compare-copies">
               <xsl:with-param name="copy-text" select="$copy-text" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:document>
      </xsl:variable>
      <!--<xsl:copy-of select="$pass-1"/>-->
      <!--<xsl:document><test><xsl:value-of select="string-length($copy-text)"/></test></xsl:document>-->
      <xsl:document>
         <xsl:apply-templates select="$pass-1" mode="get-mismatched-text">
            <xsl:with-param name="copy-text" select="$copy-text" tunnel="yes"/>
            <!--<xsl:with-param name="copy-analyzed" select="$copy-analyzed" tunnel="yes"/>-->
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="*:div[not(*:div)]" mode="compare-copies">
      <xsl:param name="copy-text" as="xs:string" tunnel="yes"/>
      <xsl:variable name="normalized-text-regex" select="tan:escape(tan:normalize-div-text(.))"/>
      <!--<xsl:variable name="found-in-copy"
         select="contains(tan:normalize-div-text(.), $copy-text)"/>-->
      <xsl:variable name="found-in-copy" as="element()">
         <div>
            <xsl:if test="string-length($normalized-text-regex) gt 0">
               <xsl:analyze-string select="$copy-text" regex="{$normalized-text-regex}">
                  <xsl:matching-substring>
                     <match><xsl:value-of select="."/></match>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <non-match><xsl:value-of select="."/></non-match>
                  </xsl:non-matching-substring>
               </xsl:analyze-string></xsl:if>
         </div>
      </xsl:variable>
      <xsl:variable name="matches-at-pos" as="xs:integer*"
         select="
            for $i in ($found-in-copy/tan:match)[position() lt 4]
            return
               string-length(string-join($i/preceding-sibling::*, ''))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="test" select="count($found-in-copy/*)"/>
         <xsl:if test="exists($matches-at-pos)">
            <xsl:attribute name="copy-loc" select="$matches-at-pos"/>
         </xsl:if>
         <xsl:value-of select="text()"/>
      </xsl:copy>
   </xsl:template>
   <!--<xsl:template match="*:body" mode="compare-copies">
      <xsl:param name="copy-text" as="xs:string" tunnel="yes"/>
      <text><xsl:value-of select="$copy-text"/></text>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="compare-copies"/>
      </xsl:copy>
   </xsl:template>-->
   <xsl:template match="*:div[not(*:div) and not(@copy-loc)]" mode="get-mismatched-text">
      <!--<xsl:param name="copy-analyzed" as="document-node()" tunnel="yes"/>-->
      <xsl:param name="copy-text" as="xs:string" tunnel="yes"/>
      <xsl:variable name="last-good-match" select="(preceding::*:div[@copy-loc])[last()]"/>
      <xsl:variable name="next-good-match" select="(following::*:div[@copy-loc])[1]"/>
      <xsl:variable name="this-text" select="tan:normalize-div-text(.)"/>
      <xsl:variable name="ending-pos"
         select="(number(tokenize($next-good-match/@copy-loc, ' ')[1]), string-length($copy-text))[1]"/>
      <xsl:variable name="starting-pos"
         select="(number(tokenize($last-good-match/@copy-loc, ' ')[1]), 1)[1] + string-length(tan:normalize-div-text($last-good-match)) + 1"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="ref" select="tan:flatref(.)"/>
         <xsl:attribute name="copy-text"
            select="substring($copy-text, $starting-pos, $ending-pos - $starting-pos)"/>
         <xsl:value-of select="text()"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:mark-splits" as="document-node()">
      <!-- Input: any prepped class 1 doc
      Output: the same document, but with @pos added to <div>s that are split.-->
      <xsl:param name="c1-doc-prepped" as="document-node()"/>
      <!--<xsl:variable name="pass-1" as="document-node()">
         <xsl:document>
            <xsl:apply-templates select="$c1-doc" mode="c1-add-ref"/>
         </xsl:document>
      </xsl:variable>-->
      <xsl:variable name="pass-1" select="tan:prep-resolved-class-1-doc($c1-doc-prepped)"/>
      <xsl:variable name="all-refs" select="$pass-1//@ref" as="xs:string*"/>
      <xsl:variable name="duplicate-refs" select="tan:duplicate-values($all-refs)"/>
      <xsl:variable name="duplicate-ref-range" as="element()*">
         <xsl:for-each select="$duplicate-refs">
            <xsl:variable name="dup-ref-locs" select="index-of($all-refs, .)"/>
            <duplicate ref="{.}">
               <xsl:for-each select="$dup-ref-locs[1] to $dup-ref-locs[last()]">
                  <div ref="{$all-refs[current()]}"/>
               </xsl:for-each>
            </duplicate>
         </xsl:for-each>
      </xsl:variable>
      <xsl:document>
         <xsl:apply-templates select="$pass-1" mode="mark-splits">
            <xsl:with-param name="duplicates" select="$duplicate-ref-range" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="*:div" mode="mark-splits">
      <xsl:param name="duplicates" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="split-membership" select="$duplicates/(tan:div[@ref = $this-ref])[1]"
         as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($split-membership)">
            <xsl:for-each select="$split-membership">
               <xsl:variable name="pos" select="position()"/>
               <xsl:attribute name="{concat('split',string($pos))}" select="../@ref"/>
            </xsl:for-each>
         </xsl:if>
         <xsl:apply-templates mode="mark-splits"/>
      </xsl:copy>
   </xsl:template>

   <!-- MISCELLANEOUS FUNCTIONS -->

   <xsl:function name="tan:get-ref-seq" as="xs:string*">
      <xsl:param name="resolved-class-1-doc" as="document-node()"/>
      <xsl:for-each select="$resolved-class-1-doc//*:div">
         <xsl:value-of select="tan:flatref(.)"/>
      </xsl:for-each>
   </xsl:function>

   <!--<xsl:function name="tan:get-div-types-in-use" as="element()*">
      <xsl:param name="resolved-class-1-doc" as="document-node()*"/>
      <xsl:for-each select="$resolved-class-1-doc">
         <xsl:variable name="type-ids-in-use"
            select="distinct-values($resolved-class-1-doc/(tei:TEI/tei:text/tei:body, tan:TAN-T/tan:body)//(tan:div, tei:div)/@type)"/>
         <class-1-doc>
            <xsl:copy-of select="*/@*"/>
            <xsl:copy-of
               select="*/tan:head/tan:declarations/tan:div-type[@xml:id = $type-ids-in-use]"/>
         </class-1-doc>
      </xsl:for-each>
   </xsl:function>-->

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



   <xsl:function name="tan:normalize-doc-space" as="document-node()+">
      <!-- Input: any document
      Output: that same document, but with each text() space-normalized -->
      <xsl:param name="doc" as="document-node()+"/>
      <xsl:for-each select="$doc">
         <xsl:document>
            <xsl:apply-templates mode="normalize-space"/>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="text()" mode="normalize-space">
      <xsl:value-of select="normalize-space(.)"/>
   </xsl:template>

</xsl:stylesheet>
