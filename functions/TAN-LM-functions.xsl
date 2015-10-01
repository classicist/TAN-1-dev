<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Updated </xd:b>Oct. 1, 2015</xd:p>
            <xd:p>Set of functions for TAN-LM files. Used by Schematron validation, but suitable for
                other contexts.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:include href="TAN-class-2-functions.xsl"/>
    
    <xsl:variable name="morphologies"
        select="$head/tan:declarations/tan:morphology"/>
    <xsl:variable name="morphologies-1st-la"
        select="for $i in $morphologies return tan:first-loc-available($i)"/>
    <xsl:variable name="mory-1st-da" select="for $i in $morphologies-1st-la return doc(resolve-uri($i,$doc-uri))"/>
    <xsl:variable name="mory-1st-da-resolved" select="for $i in $mory-1st-da return tan:resolve-doc($i)"/>
    <xsl:variable name="mory-1st-da-features" as="element()*">
        <xsl:for-each select="$mory-1st-da-resolved">
            <xsl:element name="morphology" namespace="tag:textalign.net,2015:ns">
                <xsl:for-each select="/tan:TAN-R-mor/tan:head/tan:declarations/tan:feature">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of select="/tan:TAN-R-mor/tan:body/tan:option[@feature = current()/@xml:id]"/>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:function name="tan:all-morph-codes" as="xs:string*">
        <!-- Change any sequence of morphological codes into a sequence of synonymous morphological codes
            Input: node() picking a TAN-R-mor file, a sequence of strings, each item being the value of
            tan:option/@code or tan:feature/@xml:id
         Output: sequence of strings returning all equivalent lowercased values of each tan:option/@code or tan:feature/@xml:id 
         E.g., ('NN','comma','.') - > ('nn','comma',',','.','period')
      -->
        <xsl:param name="morph" as="node()?"/>
        <xsl:param name="codes" as="xs:string*"/>
        <xsl:variable name="codes-norm"
            select="
                for $i in $codes
                return
                    lower-case($i)"/>
        <xsl:variable name="id-equiv"
            select="
                for $i in $morph//tan:body/tan:option[lower-case(@code) = $codes-norm]/@feature
                return
                    lower-case($i)"/>
        <xsl:variable name="code-equiv"
            select="
                for $i in $morph//tan:body/tan:option[lower-case(@feature) = ($id-equiv,
                $codes-norm)]/@code
                return
                    lower-case($i)"/>
        <xsl:copy-of
            select="
                distinct-values(($codes-norm,
                $id-equiv,
                $code-equiv))"
        />
    </xsl:function>

    <xsl:function name="tan:feature-test-check" as="xs:boolean">
        <!--  Checks to see if a logical expression of morphological codes (+ synonyms) is found in a given value of <m>
            Input: two strings, the first a morphological code to be checked to see if it matches the second, a logical
            expression of features; a third parameter, a node(), defines the morphology rule to be used (to reconcile
            synonyms in codes)
            Output: true() if a match is found, false() otherwise
            E.g., 'nn 1 m', '(NN | m), 2' - > false()
            E.g., 'nn 1 m', '(NN | m), 1' - > true()
      -->
        <xsl:param name="code" as="xs:string"/>
        <xsl:param name="feature-expr" as="xs:string"/>
        <xsl:param name="morph" as="node()?"/>
        <xsl:variable name="this-expr-norm"
            select="normalize-space(replace($feature-expr, '([\(\),|])', ' $1 '))"/>
        <xsl:variable name="this-expr-seq" select="tokenize($this-expr-norm, ' ')"/>
        <xsl:variable name="this-expr-seq-norm"
            select="
                for $i in $this-expr-seq
                return
                    if ($i = ('(',
                    ')',
                    '|'))
                    then
                        $i
                    else
                        if ($i = ',')
                        then
                            '.+'
                        else
                            concat(' ', string-join(tan:escape(tan:all-morph-codes($morph, $i)), ' | '), ' ')"/>
        <xsl:variable name="commas" select="count($this-expr-seq[. = ','])"/>
        <xsl:variable name="this-code-norm"
            select="
                string-join(for $i in (1 to $commas + 1)
                return
                    concat(' ', replace($code, '\s+', ' , '), ' '), ',')"/>
        <xsl:value-of select="matches($this-code-norm, string-join($this-expr-seq-norm, ''), 'i')"/>
    </xsl:function>

    <!--<xsl:function name="tan:regex-prep" as="xs:string+">
        <!-\- Converts a non-regex search string into a regex one.
            Input: a string to be searched
         Output: that string with reserved regex characters escaped
         E.g., '[.w]' - > '\[\.w\]' 
         Based on http://www.w3.org/TR/xpath-functions/#regex-syntax without #x00 escapes-\->
        <xsl:param name="str" as="xs:string+"/>
        <xsl:copy-of
            select="
                for $i in $str
                return
                    replace($i, '([-\|.?*+(){}\[\]\^])', '\\$1')"
        />
    </xsl:function>-->
</xsl:stylesheet>
