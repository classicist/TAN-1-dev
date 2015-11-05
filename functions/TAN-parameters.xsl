<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Updated </xd:b>Aug 31, 2015</xd:p>
            <xd:p>Functions and variables for core TAN files (i.e., applicable to TAN file types of
                more than one class). Used by Schematron validation, but suitable for general use in
                other contexts.</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:param name="separator-type-and-n" select="'.'" as="xs:string"/>
    <xsl:param name="separator-type-and-n-regex" select="'\.'" as="xs:string"/>
    <xsl:param name="separator-hierarchy" select="':'" as="xs:string"/>
    <xsl:param name="separator-hierarchy-regex" select="':'" as="xs:string"/>

    <xsl:param name="errors" select="doc('TAN-errors.xml')"/>
    <xsl:param name="keywords" select="doc('TAN-keywords.xml')"/>
    
    <xsl:variable name="tokenization-errors"
        select="$errors//tan:group[tokenize(@affects-element, '\s+') = 'tokenization']//tan:error"
        as="xs:string*"/>
    <xsl:variable name="inclusion-errors"
        select="$errors//tan:group[@affects-attribute = 'include']/tan:error" as="xs:string*"/>
    
    <xsl:variable name="relationship-keywords-for-tan-versions"
        select="$keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']/descendant-or-self::tan:group[@class = 'version']//tan:keyword"
        as="xs:string*"/>
    <xsl:variable name="relationship-keywords-for-tan-editions"
        select="$keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']/descendant-or-self::tan:group[@class = 'edition']//tan:keyword"
        as="xs:string*"/>
    <xsl:variable name="relationship-keywords-for-class-1-editions"
        select="$keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']/descendant-or-self::tan:group[@class = 'edition']/descendant-or-self::tan:group[@class = 'class1']//tan:keyword"
        as="xs:string*"/>
    <xsl:variable name="relationship-keywords-for-tan-files"
        select="
        $keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']//tan:keyword"
        as="xs:string*"/>
    <xsl:variable name="relationship-keywords-all"
        select="$keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']//tan:keyword"
        as="xs:string*"/>
    
</xsl:stylesheet>
