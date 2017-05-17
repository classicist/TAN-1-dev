<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">
    <xsl:import href="../../../tools/TEI%20stylesheets/html/html.xsl"/>
    <xsl:output method="xhtml" indent="no"/>

    <xsl:include href="../get%20inclusions/TAN-to-HTML-core.xsl"/>
    <xsl:include href="../get%20inclusions/TAN-core-prepare-for-reuse.xsl"/>
    <xsl:include href="../../functions/TAN-T-functions.xsl"/>

    <xsl:variable name="self-prepped-for-reuse">
        <xsl:apply-templates select="$self-prepped" mode="prep-tan-for-reuse"/>
    </xsl:variable>
    <xsl:template match="/">
        <!--<xsl:copy-of select="$self-prepped"/>-->
        <!--<xsl:copy-of select="$self-prepped-for-reuse"/>-->
        <!--<xsl:copy-of select="$self-prepped-for-html"/>-->
        <xsl:copy-of select="tan:tan-to-html($self-prepped-for-reuse)"/>
    </xsl:template>

</xsl:stylesheet>
