<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:include href="TAN-core-prepare-for-reuse.xsl"/>
    
    <xsl:variable name="self-prepped-for-reuse-prelim">
        <xsl:apply-templates mode="prep-tan-rdf-for-reuse"/>
    </xsl:variable>
    <xsl:template match="/" mode="prep-tan-rdf-for-reuse">
        <xsl:apply-templates select="$self-prepped-for-reuse-prelim" mode="prep-tan-for-reuse"/>
    </xsl:template>
    
    <xsl:template match="comment() | processing-instruction() | text()"
        mode="prep-tan-rdf-for-reuse">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="*" mode="prep-tan-rdf-for-reuse">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="prep-tan-rdf-for-reuse"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:claim" mode="prep-tan-rdf-for-reuse">
        <xsl:copy>
            <xsl:copy-of select="@ed-when, @ed-who, @cert"/>
            <xsl:copy-of select="tan:attr-to-elements((ancestor-or-self::*/@claimant)[last()])"/>
            <xsl:copy-of select="tan:attr-to-elements((ancestor-or-self::*/@subject)[last()])"/>
            <xsl:copy-of select="tan:attr-to-elements(@adverb)"/>
            <xsl:copy-of select="tan:attr-to-elements(@verb)"/>
            <xsl:copy-of select="tan:attr-to-elements(@object)"/>
            <xsl:copy-of select="tan:attr-to-elements(@where)"/>
            <xsl:apply-templates mode="prep-tan-rdf-for-reuse"/>
        </xsl:copy>
    </xsl:template>
    <xsl:function name="tan:attr-to-elements" as="element()*">
        <xsl:param name="tokenizable-attribute-to-be-distributed-into-elements" as="attribute()?"/>
        <xsl:variable name="this-attr-name"
            select="name($tokenizable-attribute-to-be-distributed-into-elements)"/>
        <xsl:for-each
            select="tokenize(normalize-space($tokenizable-attribute-to-be-distributed-into-elements), ' ')">
            <xsl:element name="{$this-attr-name}">
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>
</xsl:stylesheet>
