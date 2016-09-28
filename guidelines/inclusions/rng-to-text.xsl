<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">
    <xsl:mode name="formaldef" on-no-match="deep-skip"/>
    <xsl:template match="rng:optional" mode="formaldef">
        <xsl:apply-templates mode="formaldef"/>
        <xsl:text>?</xsl:text>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:zeroOrMore" mode="formaldef">
        <xsl:apply-templates mode="formaldef"/>
        <xsl:text>*</xsl:text>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:oneOrMore" mode="formaldef">
        <xsl:apply-templates mode="formaldef"/>
        <xsl:text>+</xsl:text>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <!-- options/branches/joins -->
    <xsl:template match="rng:group | rng:choice | rng:interleave" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:variable name="new-indent"
            select="
                if (parent::rng:attribute or parent::rng:element)
                then
                    $current-indent
                else
                    concat($current-indent, $indent)"/>
        <xsl:variable name="this-prefix"
            select="
                if (parent::rng:attribute or parent::rng:element)
                then
                    ()
                else
                    '('"/>
        <xsl:variable name="this-suffix"
            select="
                if (parent::rng:attribute or parent::rng:element)
                then
                    ()
                else
                    ')'"/>
        <xsl:value-of select="$lf || $new-indent || $this-prefix"/>
        <xsl:apply-templates mode="formaldef" select="rng:*[1]"/>
        <xsl:apply-templates mode="formaldef" select="rng:*[position() gt 1]">
            <xsl:with-param name="current-indent" select="$new-indent" tunnel="yes"/>
        </xsl:apply-templates>
        <xsl:value-of select="$this-suffix"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:ref" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:param name="is-new-line" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:variable name="this-ref" select="."/>
        <xsl:variable name="this-name" select="@name"/>
        <xsl:variable name="defs"
            select="$rng-collection-without-TEI//rng:define[@name = $this-name][not(rng:empty)]"/>
        <xsl:if test="$is-new-line = true()">
            <xsl:copy-of select="$lf || $current-indent"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when
                test="
                    every $i in $defs
                        satisfies count($i/rng:*) lt 2">
                <xsl:apply-templates select="$defs/rng:*" mode="formaldef"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="tan:prep-string-for-docbook('~' || ($this-name, '[ANY]')[1])"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="comma-check"/>
        
    </xsl:template>
    <xsl:template match="rng:ref" mode="formaldef-test">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:variable name="this" select="."/>
        <xsl:variable name="name" select="@name"/>
        <xsl:variable name="defs"
            select="$rng-collection-without-TEI//rng:define[@name = $name][not(rng:empty)]"/>
        <xsl:if test="count($defs) gt 1">
            <xsl:value-of select="$lf || $current-indent"/>
        </xsl:if>
        <!--<test><xsl:copy-of select="$defs"/></test>-->
        <xsl:for-each select="$defs">
            <xsl:if test="count($defs) gt 1">
                <emphasis>
                    <xsl:value-of select="replace(base-uri(.), '.+/(.+)', '$1')"/>
                    <xsl:text>:</xsl:text>
                </emphasis>
                <xsl:text>&#xA;</xsl:text>
            </xsl:if>
            <xsl:apply-templates mode="formaldef" select=".">
                <xsl:with-param name="is-group" tunnel="yes"
                    select="
                        if (count(rng:*) gt 1 and ($this/parent::rng:choice or $this/parent::rng:optional)) then
                            true()
                        else
                            false()"
                />
            </xsl:apply-templates>
            <xsl:if test="position() lt last()">
                <xsl:text>&#xA;</xsl:text>
                <emphasis>
                    <xsl:text>  ~OR~</xsl:text>
                </emphasis>
                <xsl:text>&#xA;</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:if test="count($defs) gt 1">
            <xsl:text>&#xA;</xsl:text>
        </xsl:if>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:define" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:param name="is-group" as="xs:boolean" select="true()" tunnel="yes"/>
        <xsl:variable name="this-prefix"
            select="
                if ($is-group = true()) then
                    '('
                else
                    ()"/>
        <xsl:variable name="this-suffix"
            select="
                if ($is-group = true()) then
                    ')'
                else
                    ()"/>
        <xsl:value-of select="$lf || $current-indent || $this-prefix"/>
        <xsl:choose>
            <xsl:when test="count(rng:*) gt 1 or not(rng:element or rng:attribute)">
                <xsl:apply-templates mode="formaldef" select="rng:*[1]"/>
                <xsl:apply-templates mode="formaldef" select="rng:*[position() gt 1]">
                    <xsl:with-param name="is-new-line" select="true()" tunnel="yes"/>
                </xsl:apply-templates>
                <xsl:value-of select="$this-suffix"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="formaldef"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--<xsl:template match="rng:define[count(rng:*) le 1]" mode="formaldef">
        <xsl:apply-templates mode="formaldef"></xsl:apply-templates>
    </xsl:template>-->
    <xsl:template match="rng:element" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:param name="is-new-line" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:if test="$is-new-line = true()">
            <xsl:copy-of select="$lf || $current-indent"/>
        </xsl:if>
        <!--<test><xsl:value-of select="@name"/></test>-->
        <xsl:copy-of select="tan:prep-string-for-docbook('&lt;' || (@name, '[ANY]')[1] || '>')"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:attribute" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:param name="is-new-line" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:if test="$is-new-line = true()">
            <xsl:copy-of select="$lf || $current-indent"/>
        </xsl:if>
        <xsl:copy-of select="tan:prep-string-for-docbook('@' || (@name, '[ANY]')[1])"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:param" mode="formaldef">
        <xsl:value-of select="'(' ||@name || ' ' || . || ')'"/>
    </xsl:template>
    <xsl:template match="rng:data" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:value-of
            select="
                if (parent::rng:group | parent::rng:choice | parent::rng:interleave) then
                    $lf || $current-indent
                else
                    ()"/>
        <xsl:value-of select="@type || ' '"/>
        <xsl:apply-templates mode="formaldef"/>
    </xsl:template>
    <xsl:template match="rng:text" mode="formaldef">
        <xsl:text>text</xsl:text>
    </xsl:template>
    <xsl:template match="rng:empty" mode="formaldef">
        <xsl:text>{empty}</xsl:text>
    </xsl:template>
    <xsl:template match="text()" mode="formaldef"/>
    <!-- I'm not yet sure if it's better to do the function or the template form of the comma-check -->
    <!--<xsl:function name="tan:comma-check" as="xs:string*">
        <xsl:param name="rng-nodes" as="element()*"/>
        <xsl:for-each select="$rng-nodes">
            <xsl:choose>
                <xsl:when test="parent::rng:choice and following-sibling::rng:*">
                    <xsl:text> |&#xA;</xsl:text>
                </xsl:when>
                <xsl:when test="parent::rng:interleave and following-sibling::rng:*">
                    <xsl:text> &amp;&#xA;</xsl:text>
                </xsl:when>
                <xsl:when test="following-sibling::rng:*">
                    <xsl:text>,&#xA;</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>-->
    <xsl:template name="comma-check">
        <xsl:choose>
            <xsl:when test="parent::rng:choice and following-sibling::rng:*">
                <!--<xsl:text> |&#xA;</xsl:text>-->
                <xsl:text> | </xsl:text>
            </xsl:when>
            <xsl:when test="parent::rng:interleave and following-sibling::rng:*">
                <!--<xsl:text> &amp;&#xA;</xsl:text>-->
                <xsl:text> &amp; </xsl:text>
            </xsl:when>
            <xsl:when test="following-sibling::rng:*">
                <!--<xsl:text>,&#xA;</xsl:text>-->
                <xsl:text>,</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
