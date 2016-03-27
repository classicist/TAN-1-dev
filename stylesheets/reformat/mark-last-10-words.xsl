<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs tan" version="3.0">
    <xsl:template match="*">
        <xsl:variable name="text-to-keep" select="replace(text(), '(.+)(\s+\S+){10}(\s*)', '$1$3', 's')"/>
        <xsl:variable name="text-to-move" select="replace(text(), '.+((\s+\S+){10})\s*', '$1', 's')"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="$text-to-keep"/>
            <tan:move>
                <xsl:value-of select="normalize-space($text-to-move)"/>
            </tan:move>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
