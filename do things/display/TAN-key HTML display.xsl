<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">
    <xsl:import href="../../../stylesheets/Stylesheets/html/html.xsl"/>
    <xsl:output method="html" indent="yes"/>

    <xsl:include href="../../../stylesheets/prepare/TAN-to-HTML-core.xsl"/>
    <xsl:include href="../../../stylesheets/prepare/incl/TAN-core-prepare-for-reuse.xsl"/>
    <xsl:include href="../../functions/TAN-key-functions.xsl"/>

    <xsl:variable name="self-prepped-for-html">
        <xsl:apply-templates select="$self-prepped" mode="prep-tan-for-reuse"/>
    </xsl:variable>
    <xsl:template match="/*">
        <!--<xsl:copy-of select="$self-prepped"/>-->
        <!--<xsl:copy-of select="$self-prepped-for-html"/>-->
        <xsl:copy-of select="tan:tan-to-html($self-prepped-for-html)"/>
    </xsl:template>

</xsl:stylesheet>
