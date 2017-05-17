<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:include href="TAN-class-2-prepare-for-reuse.xsl"/>

    <xsl:variable name="self-prepped-for-reuse-prelim-a"
        select="tan:stamp-id($self-prepped, 'align', 'gloss')"/>
    <xsl:variable name="self-prepped-for-reuse-prelim-b">
        <xsl:apply-templates select="$self-prepped-for-reuse-prelim-a" mode="prep-tan-a-tok-for-reuse"/>
    </xsl:variable>
    <xsl:variable name="self-prepped-for-reuse-prelim-c"
        select="tan:embed-glosses($self-prepped-for-reuse-prelim-b)"/>
    <xsl:variable name="self-prepped-for-reuse" as="document-node()">
        <xsl:document>
            <xsl:apply-templates select="$self-prepped-for-reuse-prelim-c" mode="prep-tan-for-reuse"
            />
        </xsl:document>
    </xsl:variable>

    <xsl:template match="comment() | processing-instruction() | text()"
        mode="prep-tan-a-tok-for-reuse">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="*" mode="prep-tan-a-tok-for-reuse prep-tan-a-tok-source-for-reuse">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:TAN-A-tok" mode="prep-tan-a-tok-for-reuse">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="node()"/>
            <xsl:apply-templates select="$sources-prepped" mode="prep-tan-a-tok-source-for-reuse">
                <xsl:with-param name="alignments" select="tan:body/tan:align" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:body" mode="prep-tan-a-tok-source-for-reuse">
        <xsl:variable name="this-source-id" select="../@src"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="prep-tan-a-tok-source-for-reuse">
                <xsl:with-param name="source-id" select="$this-source-id" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:tok" mode="prep-tan-a-tok-source-for-reuse">
        <xsl:param name="alignments" as="element()*" tunnel="yes"/>
        <xsl:param name="source-id" as="xs:string" tunnel="yes"/>
        <xsl:variable name="this-element" select="."/>
        <xsl:variable name="this-ref" select="../@ref"/>
        <xsl:variable name="this-n" select="@n"/>
        <xsl:variable name="this-tok-aligned"
            select="$alignments/tan:tok[@src = $source-id and @ref = $this-ref and @n = $this-n]"/>
        <xsl:variable name="whole-word-alignments" select="$this-tok-aligned[not(tan:c)]"/>
        <xsl:variable name="partial-word-alignments" select="$this-tok-aligned[tan:c]"/>
        <xsl:choose>
            <xsl:when test="exists($partial-word-alignments)">
                <xsl:variable name="this-analyzed" select="tan:chop-string(text())"/>
                <xsl:for-each-group select="1 to count($this-analyzed)"
                    group-adjacent="string-join($partial-word-alignments[tan:c/@n = current()]/../@gloss, ' ')">
                    <tok>
                        <xsl:copy-of select="$this-element/@*"/>
                        <xsl:for-each select="tokenize(current-grouping-key(),' ')">
                            <xsl:variable name="this-gloss-id" select="."/>
                            <xsl:variable name="this-alignment" select="$partial-word-alignments[../@gloss = $this-gloss-id]"/>
                            <xref>
                                <xsl:attribute name="gloss" select="$this-gloss-id"/>
                                <xsl:if test="exists($this-alignment/ancestor-or-self::*/@cert)">
                                    <xsl:attribute name="cert"
                                        select="tan:product($this-alignment/ancestor-or-self::*/@cert)"/>
                                </xsl:if>
                            </xref>
                        </xsl:for-each>
                        <xsl:for-each select="$whole-word-alignments">
                            <xref>
                                <xsl:copy-of select="../@gloss"/>
                                <xsl:if test="exists(ancestor-or-self::*/@cert)">
                                    <xsl:attribute name="cert"
                                        select="tan:product(ancestor-or-self::*/@cert)"/>
                                </xsl:if>
                            </xref>
                        </xsl:for-each>
                        <xsl:value-of
                            select="string-join($this-analyzed[position() = current-group()], '')"/>
                    </tok>
                </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:for-each select="$this-tok-aligned">
                        <xref>
                            <xsl:copy-of select="../@gloss"/>
                            <xsl:if test="exists(ancestor-or-self::*/@cert)">
                                <xsl:attribute name="cert"
                                    select="tan:product(ancestor-or-self::*/@cert)"/>
                            </xsl:if>
                        </xref>
                    </xsl:for-each>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>

            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- At this point we need to ditch residual TEI elements. -->
    <xsl:template match="tei:*" mode="prep-tan-a-tok-source-for-reuse"/>

</xsl:stylesheet>
