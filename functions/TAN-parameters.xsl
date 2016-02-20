<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Updated </xd:b>January 14, 2015</xd:p>
            <xd:p>Parameters for core TAN files (i.e., applicable to TAN file types of more than one
                class), and variables that extrapolate values from parameters.</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:param name="regex-escaping-characters" as="xs:string"
        select="'[\.\[\]\\\|\-\^\$\?\*\+\{\}\(\)]'"/><!-- olim: [\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\)] -->

    <xsl:param name="separator-type-and-n" select="'.'" as="xs:string"/>
    <xsl:param name="separator-type-and-n-regex" select="'\.'" as="xs:string"/>
    <xsl:param name="separator-hierarchy" select="':'" as="xs:string"/>
    <xsl:param name="separator-hierarchy-regex" select="':'" as="xs:string"/>

    <xsl:param name="errors" select="doc('TAN-errors.xml')"/>
    <xsl:param name="id-idrefs" select="doc('TAN-idrefs.xml')"/>

    <xsl:param name="schema-version-major" select="1"/>
    <xsl:param name="schema-version-minor" select="'dev'"/>

    <xsl:variable name="tokenization-errors"
        select="$errors//tan:group[tokenize(@affects-element, '\s+') = 'tokenization']//tan:error"
        as="xs:string*"/>
    <xsl:variable name="inclusion-errors"
        select="$errors//tan:group[@affects-attribute = 'include']/tan:error" as="xs:string*"/>

    <xsl:param name="help-trigger" select="'???'"/>

</xsl:stylesheet>
