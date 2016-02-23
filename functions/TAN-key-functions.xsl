<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Created on:</xd:b> February 2, 2016</xd:p>
         <xd:p><xd:b>Author:</xd:b> Joel</xd:p>
         <xd:p>Set of functions for TAN-key files. Used by Schematron validation, but suitable for
            general use in other contexts </xd:p>
      </xd:desc>
   </xd:doc>
   
   <xsl:include href="TAN-class-3-functions.xsl"/>
   <xsl:include href="TAN-schema-functions.xsl"/>
   <xsl:variable name="all-body-iris" select="$body//tan:IRI"/>
   <!-- CONTEXT INDEPEDENT FUNCTIONS -->
   <!-- CONTEXT DEPEDENT FUNCTIONS -->
   
</xsl:stylesheet>
