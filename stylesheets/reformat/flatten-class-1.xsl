<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tan" version="2.0">
    <xsl:import href="../../functions/TAN-core-functions.xsl"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when
                test="tei:TEI/tei:text/tei:body//tei:div[@include] or tan:TAN-T/tan:body//tan:div[@include]">
                <xsl:message terminate="yes" select="'This file has includes in the body; resolve them before trying this transformation.'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="node()">
                    <xsl:text>&#xA;</xsl:text>
                    <xsl:apply-templates select="." mode="flatten-class-1"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="/" mode="flatten-class-1">
        <xsl:copy>
            <xsl:apply-templates mode="flatten-class-1"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="comment() | processing-instruction() | text()" mode="flatten-class-1">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="*" mode="flatten-class-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:div | tei:div" mode="flatten-class-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="n" select="string-join((ancestor-or-self::*/@n), ' ')"/>
            <xsl:attribute name="type" select="string-join(ancestor-or-self::*/@type, ' ')"/>
            <xsl:if test="(ancestor-or-self::tan:div, ancestor-or-self::tei:div)/@xml:lang">
                <xsl:attribute name="xml:lang"
                    select="((ancestor-or-self::tan:div, ancestor-or-self::tei:div)/@xml:lang)[1]"/>
            </xsl:if>
            <xsl:value-of select="normalize-space(string-join(text(), ''))"/>
            <xsl:apply-templates mode="#current" select="* | text()[not(matches(., '\S'))] | comment()"
            />
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
