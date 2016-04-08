<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tan" version="2.0">
    <xsl:import href="../../functions/TAN-LM-functions.xsl"/>
    <!-- Stylesheet to transform a TAN-LM file. Offers the following features:
        1. Reset <group>s of <ana>s
        2. Convert <tok> references to and from @pos and @val
        3. Recombine <ana>s
        4. Re-sort
    -->
    <!-- This parameter takes a sequence of TAN sequence constructors (e.g., '1 - last', '4, 5, 
        last-4 - last-1'). If the parameter is not present, or if it is the zero-length string, 
        then no changes will be made. Then for every value, the <ana>s picked by the constructor 
        will be grouped. If the first value is '0' then all groups will be reset (every <ana> will 
        be made a child of <body>). 
    -->
    <xsl:param name="re-group-anas" as="xs:string*"/>
    <!-- If the value is 'pos' then all <tok> values will be converted to @pos; likewise for
    'val'; for any other value no such transformation occurs -->
    <xsl:param name="convert-tok-refs-to-pos-or-val" as="xs:string?"/>
    <!--Recombinations. If the value is 'tok', 'l', or 'm' then that element will be the primary
        grouping key for recombining <ana>s; if the value is 'ungroup' or 'distribute', then the
        document will be revised such that every <ana> will have only one <tok> and one <lm>, and that
        <lm> will have only one <l> and one <m>. Any other value will make no changes to the
        current <ana> combinations -->
    <xsl:param name="first-recombination" as="xs:string?"/>
    <!-- If the first recombination is 'tok' then only 'l' or 'm' is allowed. If the first 
    recombination is 'l' or 'm' then only 'tok' is allowed. Any other value means that no secondary
    recombination takes place. -->
    <xsl:param name="second-recombination" as="xs:string?"/>
    <!-- Sorting. Normally, if recombination has occured, you want to re-sort upon that first
    combination. If it hasn't, then you want to pick a particular element to serve as the basis 
    for sorting. If the parameter does exist, or value is a zero-length string, then no sorting
    takes place. -->
    <xsl:param name="primary-sort" as="xs:string?"/>

    <xsl:variable name="regrouped-doc">
        <xsl:apply-templates select="/" mode="re-group"/>
    </xsl:variable>
    <xsl:template match="node()" mode="re-group no-groups">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:group" mode="no-groups">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="tan:body" mode="re-group" name="re-group">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="tan:re-group-anas(tan:ana, $re-group-anas)"/>
        </xsl:copy>
    </xsl:template>
    <xsl:function name="tan:re-group-anas" as="element()*">
        <xsl:param name="body-to-re-group" as="element()"/>
        <xsl:param name="sequences-to-check" as="xs:string*"/>
        <!--<xsl:variable name="sequences-to-check-adjusted"
            select="
                if (exists($sequences-to-check)) then
                    $sequences-to-check
                else
                    $re-group-anas"/>-->
        <xsl:variable name="this-sequence" select="$sequences-to-check[1]"/>
        <xsl:variable name="ana-max" select="count(tan:ana)"/>
        <xsl:variable name="this-sequence-resolved"
            select="tan:sequence-expand($this-sequence, $ana-max)"/>
        <xsl:choose>
            <xsl:when test="not(exists($this-sequence)) or $this-sequence = ''">
                <xsl:copy-of select="$body-to-re-group"/>
            </xsl:when>
            <!-- if there's nothing to re-group, then skip it all -->
            <xsl:when test="$this-sequence = '0'">
                <xsl:variable name="new-body" as="element()">
                    <xsl:apply-templates select="$body-to-re-group" mode="no-groups"/>
                </xsl:variable>
                <xsl:copy-of select="tan:re-group-anas($new-body, $this-sequence[position() gt 1])"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="anas-to-group"
                    select="$body-to-re-group/tan:ana[position() = $this-sequence-resolved]"/>
                <xsl:variable name="first-ana-to-group" select="$anas-to-group[1]"/>
                <xsl:variable name="new-body" as="element()">
                    <body>
                        <xsl:copy-of select="$body-to-re-group/@*"/>
                        <xsl:copy-of
                            select="$body-to-re-group/tan:ana[position() = $first-ana-to-group]/preceding-sibling::*"/>
                        <group>
                            <xsl:copy-of select="$anas-to-group"/>
                        </group>
                        <xsl:copy-of
                            select="$body-to-re-group/tan:ana[position() = $first-ana-to-group]/following-sibling::* except $anas-to-group"
                        />
                    </body>
                </xsl:variable>
                <xsl:copy-of select="tan:re-group-anas($new-body, $this-sequence[position() gt 1])"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>
