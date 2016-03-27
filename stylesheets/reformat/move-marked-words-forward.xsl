<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs tan" version="3.0">
    <xsl:output indent="false"/>
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:move"/>
    <xsl:template match="tan:div[not(tan:div)][preceding::tan:div[not(tan:div)][1]/tan:move]">
        <xsl:variable name="preceding-space"
            select="
                (if (matches(text(), '^\s+')) then
                    true()
                else
                    false())"/>
        <xsl:variable name="movendum" select="preceding::tan:div[not(tan:div)][1]/tan:move"/>
        <xsl:variable name="preceding-text-node" select="preceding-sibling::node()[1]/self::text()"/>
        <xsl:variable name="novum-movendum"
            select="
                if ($preceding-space = true()) then
                    ' ' || $movendum
                else
                    $movendum || (if ($preceding-text-node = true()) then
                        ' '
                    else
                        ())"
        />
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of
                select="$novum-movendum || replace(text(),'^\s+','', 's')"
            />
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
