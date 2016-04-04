<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="tan fn tei xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Updated </xd:b>Oct. 1, 2015</xd:p>
            <xd:p>Set of functions for TAN-LM files. Used by Schematron validation, but suitable for
                other contexts.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:include href="TAN-class-2-functions.xsl"/>
    
    <xsl:variable name="morphologies" select="$head/tan:declarations/tan:morphology"/>
    <xsl:variable name="morphologies-prepped" as="element()*">
        <xsl:for-each select="$morphologies">
            <xsl:variable name="first-la" select="tan:first-loc-available(.)"/>
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <location href="{resolve-uri($first-la, $doc-uri)}"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:variable>
    <!--<xsl:variable name="morphologies-1st-la"
        select="
            for $i in $morphologies
            return
                tan:first-loc-available($i)"/>-->
    <!--<xsl:variable name="mory-1st-da"
        select="
            for $i in $morphologies-1st-la
            return
                doc(resolve-uri($i, $doc-uri))"/>-->
    <xsl:variable name="mory-1st-da-resolved"
        select="
            for $i in $morphologies-prepped
            return
                tan:resolve-doc(doc($i/tan:location/@href), $i/@xml:id, false())"/>
    <xsl:variable name="mory-1st-da-features" as="element()*">
        <xsl:for-each select="$mory-1st-da-resolved">
            <morphology>
                <xsl:for-each select="/tan:TAN-mor/tan:head/tan:declarations/tan:feature">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of
                            select="/tan:TAN-mor/tan:body/tan:option[@feature = current()/@xml:id]"
                        />
                    </xsl:copy>
                </xsl:for-each>
            </morphology>
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

    <xsl:function name="tan:get-lm-ids" as="xs:string*">
        <!-- Input: any number of <ana>
            Output: one string per combination of <l> + <m>, calculated by joining (1) the <l> value,
            (2)the <m> code, and (3) attribute values of <lm>, <l>, and <m>
        -->
        <xsl:param name="ana-elements" as="element()+"/>
        <xsl:for-each select="$ana-elements">
            <xsl:copy-of
                select="
                    for $i in tan:lm,
                        $j in if ($i/tan:l) then
                            $i/tan:l
                        else
                            $empty-doc,
                        $k in if ($i/tan:m) then
                            $i/tan:m
                        else
                            $empty-doc
                    return
                        concat($j, '###', $k, '###', string-join(for $l in ($i, $j, $k)[(@cert, @morphology, @lexicon, @def-ref)],
                            $m in $l/(@cert, @morphology, @lexicon, @def-ref)
                        return
                            concat('%', name($l), '%', name($m), '%', $m), '###'
                        ))"
            />
        </xsl:for-each>
    </xsl:function>

    <!-- Transformative templates -->
    <xsl:function name="tan:expand-per-lm" as="document-node()*">
        <!-- Takes a TAN-LM and consolidates it, creating one <ana> per individual <l> + <m> pair,
        then putting in it any <tok> that shares that data -->
        <xsl:param name="tan-lm-resolved" as="document-node()*"/>
        <xsl:for-each select="$tan-lm-resolved">
            <xsl:copy>
                <xsl:apply-templates mode="expand-lm"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:function>

    <xsl:template match="node()" mode="expand-lm convert-code-to-features">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:body" mode="expand-lm">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each-group select="tan:ana" group-by="tan:get-lm-ids(current())">
                <xsl:sort select="current-grouping-key()"/>
                <xsl:variable name="this-l-and-m" select="tokenize(current-grouping-key(), '###')"/>
                <ana>
                    <xsl:copy-of select="current-group()/tan:tok"/>
                    <lm>
                        <xsl:copy-of select="current-group()/tan:lm/@cert"/>
                        <l>
                            <xsl:copy-of select="current-group()/tan:lm/tan:l/(@cert, @lexicon)"/>
                            <xsl:value-of select="$this-l-and-m[1]"/>
                        </l>
                        <m>
                            <xsl:copy-of select="current-group()/tan:lm/tan:l/(@cert, @morphology)"/>
                            <xsl:value-of select="$this-l-and-m[2]"/>
                        </m>
                    </lm>
                </ana>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="tan:convert-code-to-features" as="document-node()*">
        <!-- adds to every <m> a <feature @xml:id> for every part of the code -->
        <xsl:param name="tan-lm-resolved" as="document-node()*"/>
        <xsl:for-each select="$tan-lm-resolved">
            <xsl:copy>
                <xsl:apply-templates mode="convert-code-to-features"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:function>
    <xsl:template match="tan:m" mode="convert-code-to-features">
        <xsl:variable name="this-mory-id" select="(ancestor-or-self::*/@morphology)[1]"/>
        <xsl:variable name="this-mory"
            select="$mory-1st-da-resolved/tan:TAN-mor[@src = $this-mory-id]"/>
        <xsl:variable name="this-mory-categories" select="$this-mory/tan:body/tan:category"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="."/>
            <xsl:choose>
                <xsl:when test="exists($this-mory-categories)">
                    <xsl:for-each select="tokenize(., '\s+')">
                        <xsl:variable name="this-code" select="."/>
                        <xsl:variable name="pos" select="position()"/>
                        <xsl:variable name="this-feature"
                            select="$this-mory-categories[$pos]/tan:option[@code = $this-code]/@feature"/>
                        <feature>
                            <xsl:value-of select="$this-feature"/>
                        </feature>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="tokenize(., '\s+')">
                        <feature>
                            <xsl:value-of select="."/>
                        </feature>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:function name="tan:add-tok-val" as="document-node()*">
        <!-- take a fully expanded TAN-LM file ($self4) and to each <tok> add the value of 
        the token chosen, as @val, and replacing any pre-existing @val with @val-orig -->
        <xsl:param name="tan-lm-resolved" as="document-node()*"/>
        <xsl:param name="src-tokenized" as="document-node()*"/>
        <xsl:for-each select="$tan-lm-resolved">
            <xsl:variable name="pos" select="position()"/>
            <xsl:copy>
                <xsl:apply-templates mode="add-tok-val">
                    <xsl:with-param name="src-tokenized" select="$src-tokenized[$pos]"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:for-each>
    </xsl:function>
    <xsl:template match="node()" mode="add-tok-val">
        <xsl:param name="src-tokenized" as="document-node()?"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="src-tokenized" select="$src-tokenized"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:tok" mode="add-tok-val">
        <xsl:param name="src-tokenized" as="document-node()?"/>
        <xsl:variable name="this-ref" select="@ref"/>
        <xsl:variable name="this-n" select="@n"/>
        <xsl:variable name="this-match" select="$src-tokenized/tan:TAN-T/tan:body//tan:div[@ref = $this-ref]/tan:tok[@n = $this-n]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="@val">
                <xsl:attribute name="val-orig" select="@val"></xsl:attribute>
            </xsl:if>
            <xsl:attribute name="val" select="$this-match"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
