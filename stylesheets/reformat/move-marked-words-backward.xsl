<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs tan" version="3.0">
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:move"/>
    <xsl:template match="tan:div[not(tan:div)][following::tan:div[not(tan:div)][1]/tan:move]">
        <xsl:variable name="trailing-space"
            select="
                (if (matches(text(), '\s+$')) then
                    true()
                else
                    false())"/>
        <xsl:variable name="movendum" select="following::tan:div[not(tan:div)][1]/tan:move"/>
        <xsl:variable name="novum-movendum"
            select="
                if ($trailing-space = true()) then
                    $movendum || ' '
                else
                    ' ' || $movendum"
        />
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of
                select="replace(text(),'\s+$','', 's') || $novum-movendum"
            />
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
