<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tan tei" version="2.0">
   <xsl:import href="../../functions/TAN-class-2-functions.xsl"/>
   <!-- This template takes a class-2 file, and adds/replaces the <tail> with a copy
      of the sources, prepped. This transformation is useful for the editing mode of class-2
      files, to make editing assistance more efficient
   -->
   <xsl:template match="/">
      <xsl:choose>
         <xsl:when test="not((tan:TAN-A-div, tan:TAN-A-tok, tan:TAN-LM))">
            <xsl:message terminate="yes" select="'This file is not a class 2 file.'"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="processing-instruction() | comment()"/>
            <xsl:for-each select="*">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="tan:head, tan:body"/>
                  <tail>
                     <xsl:copy-of select="tan:get-src-1st-da-prepped()/*"/>
                  </tail>
               </xsl:copy>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

</xsl:stylesheet>
