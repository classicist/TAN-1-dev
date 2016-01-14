<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Revised</xd:b>Jan 13, 2016</xd:p>
         <xd:p>Functions and variables for experimental edit function</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="TAN-core-functions.xsl"/>

   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-sources"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-count"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-source-lacks-id"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-ids"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-1st-da-locations"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-1st-da"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-1st-da-resolved"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-1st-da-data"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-suppress-div-types"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-div-types-to-suppress"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-div-types-to-suppress-reg-ex"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-rename-div-types"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-rename-div-ns"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-n-type-pattern"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-src-impl-div-types"/>

   <xi:include href="TAN-class-2-functions.xsl" xpointer="f-src-ids-to-nos"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="f-prep-class-1-data-1"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="f-prep-class-1-data-2"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="f-ref-rename"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="f-normalize-refs"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="f-normalize-ref-punctuation"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="f-normalize-impl-refs"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="v-ucd-decomp"/>
   <xi:include href="TAN-class-2-functions.xsl" xpointer="f-string-base"/>

   <xsl:variable name="src-1st-da-data-prepped-for-search"
      select="tan:prep-for-search($src-1st-da-data)"/>

   <xsl:function name="tan:expand-search" as="xs:string?">
      <xsl:param name="regex" as="xs:string?"/>
      <xsl:variable name="output" as="xs:string*">
         <xsl:for-each select="1 to string-length($regex)">
            <xsl:variable name="pos" select="."/>
            <xsl:variable name="char" select="substring($regex, $pos, 1)"/>
            <xsl:variable name="prev-char" select="substring($regex, $pos - 1, 1)"/>
            <xsl:variable name="reverse-translate-match" select="$ucd-decomp/tan:translate/tan:reverse/tan:transString[text() = $char]"/>
            <xsl:choose>
               <xsl:when test="$prev-char = '\' or ($prev-char != '\' and $char = '|')">
                  <xsl:value-of select="$char"/>
               </xsl:when>
               <xsl:when test="$reverse-translate-match">
                  <xsl:value-of select="concat('[', $char, string-join($reverse-translate-match/tan:mapString,''), ']')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$char"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($output,'')"/>
   </xsl:function>

   <xsl:function name="tan:prep-for-search" as="element()*">
      <xsl:param name="src-data" as="element()*"/>
      <xsl:for-each select="$src-data">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="prep-for-search"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>

   <xsl:template match="tan:*" mode="prep-for-search">
      <xsl:param name="text-to-suppress" as="xs:string" select="'\p{M}'"/>
      <xsl:param name="case-insensitive" as="xs:boolean" select="true()"/>
      <!--<xsl:param name="search-on-base" as="xs:boolean" select="false()"/>-->
      <xsl:variable name="pass-1" select="replace(text(), $text-to-suppress, '')"/>
      <!--<xsl:variable name="pass-2"
         select="
            if ($case-insensitive = true()) then
               lower-case($pass-1)
            else
               $pass-1"
      />-->
      <!--<xsl:variable name="pass-3"
         select="
            if ($search-on-base = true()) then
               tan:string-base($pass-2)
            else
               $pass-2"
      />-->
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:element name="tan:search">
            <xsl:value-of select="$pass-1"/>
         </xsl:element>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tei:*" mode="prep-for-search"/>

</xsl:stylesheet>
