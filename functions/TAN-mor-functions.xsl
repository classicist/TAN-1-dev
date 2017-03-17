<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>March 2017</xd:p>
         <xd:p>Set of functions for TAN-R-mor files. Used by Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="incl/TAN-class-3-functions.xsl"/>
   
   <xsl:variable name="self-prepped" as="document-node()">
      <xsl:document>
         <xsl:apply-templates select="$self-core-errors-marked" mode="prep-tan-mor"/>
      </xsl:document>
   </xsl:variable>

</xsl:stylesheet>
