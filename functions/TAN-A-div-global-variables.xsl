<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>July 20, 2016</xd:p>
         <xd:p>Intended to be included alongside TAN-class-2-functions.xsl, to facilitate access to
            the class-2 and class-1 documents.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="incl/TAN-class-2-global-variables.xsl"/>

   <xsl:variable name="srcs-segmented"
      select="
         tan:get-src-1st-da-segmented($self3, if ($self3/tan:TAN-A-div/tan:body/tan:split) then
            $srcs-tokenized
         else
            $srcs-prepped)"
      as="document-node()*"/>
   <!--<xsl:variable name="srcs-segmented-and-filtered" select="tan:get-src-1st-da-segmented($self4, $srcs-tokenized-and-filtered)"
      as="document-node()*"/>-->
   <!--<xsl:variable name="self5" select="tan:get-self-expanded-5($self4)"/>-->
   <xsl:variable name="srcs-realigned" select="tan:get-src-1st-da-realigned($self3, $srcs-segmented)"
      as="document-node()*"/>
   <!--<xsl:variable name="srcs-realigned-and-filtered" select="tan:get-src-1st-da-realigned($self3, $srcs-segmented-and-filtered)"
      as="document-node()*"/>-->
   <xsl:variable name="srcs-statted" select="tan:get-src-1st-da-statted($srcs-realigned)"
      as="document-node()*"/>

</xsl:stylesheet>
