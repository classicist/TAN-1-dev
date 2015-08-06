<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> June 10, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> Joel</xd:p>
            <xd:p>Set of context-dependent functions for TAN-A-tok files. Used by Schematron
                validation, suitable for other contexts only if parameters are honored</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:include href="TAN-class-2-functions.xsl"/>
</xsl:stylesheet>
