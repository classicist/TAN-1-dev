<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Created on:</xd:b> June 10, 2015</xd:p>
         <xd:p><xd:b>Author:</xd:b> Joel</xd:p>
         <xd:p>Set of functions for class 3 TAN files (i.e., applicable to
            multiple class 3 TAN file types). Used by Schematron validation, but suitable for
            general use in other contexts </xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="TAN-core-functions.xsl"/>
   <xsl:include href="TAN-class-2-and-3-functions.xsl"/>   
</xsl:stylesheet>
