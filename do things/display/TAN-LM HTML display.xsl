<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">
   <!-- Include the following if you wish to have TEI formatting -->
   <!--<xsl:import href="../Stylesheets/html/html.xsl"/>-->
   <!-- Normally, indent should be no, because this is analyzing words and parts of words, and the lack of space between elements is important to observe -->
   <xsl:output method="html" indent="yes"/>
   
   <xsl:include href="../get%20inclusions/TAN-to-HTML-core.xsl"/>
   <xsl:include href="../get%20inclusions/TAN-LM-prepare-for-reuse.xsl"/>
   <xsl:include href="../../functions/TAN-LM-functions.xsl"/>

   <xsl:template match="/*">
      <!-- diagnostics, results -->
      <!--<xsl:copy-of select="tan:get-1st-doc(//tan:source[1])"/>-->
      <!--<xsl:copy-of select="tan:get-1st-doc(//tan:source[1])//*[@n = '1']"/>-->
      <!--<xsl:copy-of select="$self-resolved"/>-->
      <!--<xsl:copy-of select="$self-prepped"/>-->
      <!--<xsl:copy-of select="$sources-prepped"/>-->
      <!--<xsl:copy-of select="$morphologies-prepped-for-reuse"/>-->
      <!--<xsl:copy-of select="$self-prepped-for-reuse-prelim-a1"/>-->
      <!--<xsl:copy-of select="$self-prepped-for-reuse-prelim-a2"/>-->
      <!--<xsl:copy-of select="$self-prepped-for-reuse-prelim-b"/>-->
      <!--<xsl:copy-of select="$self-prepped-for-reuse-prelim-c"/>-->
      <!--<xsl:copy-of select="$self-prepped-for-reuse"/>-->
      <xsl:copy-of select="tan:tan-to-html($self-prepped-for-reuse)"/>
   </xsl:template>

</xsl:stylesheet>
