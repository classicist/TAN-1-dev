<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:include href="TAN-class-2-prepare-for-reuse.xsl"/>

    <xsl:variable name="self-prepped-for-reuse-prelim-a1">
        <xsl:apply-templates select="$self-prepped" mode="distribute-anas"/>
    </xsl:variable>
    <xsl:variable name="self-prepped-for-reuse-prelim-a2"
        select="tan:stamp-id($self-prepped-for-reuse-prelim-a1, 'ana', 'gloss')"/>
    <xsl:variable name="morphologies-prepped-for-reuse">
        <xsl:for-each select="$morphologies-prepped">
            <xsl:variable name="this-id" select="/*/@morphology"/>
            <xsl:document>
                <xsl:apply-templates mode="prep-tan-lm-morphologies-for-reuse">
                    <xsl:with-param name="this-doc-id" select="$this-id" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="self-prepped-for-reuse-prelim-b">
        <xsl:apply-templates select="$self-prepped-for-reuse-prelim-a2" mode="prep-tan-lm-for-reuse"/>
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
        mode="prep-tan-lm-for-reuse distribute-anas">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="*" mode="prep-tan-lm-for-reuse prep-tan-lm-source-for-reuse prep-tan-lm-morphologies-for-reuse distribute-anas">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:ana" mode="distribute-anas">
        <xsl:variable name="this-ana" select="."/>
        <xsl:for-each-group select="tan:tok" group-by="@group">
            <ana>
                <xsl:copy-of select="$this-ana/@*"/>
                <xsl:copy-of select="current-group()"/>
                <xsl:copy-of select="$this-ana/(node() except tan:tok)"/>
            </ana>
        </xsl:for-each-group> 
    </xsl:template>
    
    <xsl:template match="tan:TAN-LM" mode="prep-tan-lm-for-reuse">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <xsl:apply-templates select="$sources-prepped" mode="prep-tan-lm-source-for-reuse">
                <xsl:with-param name="alignments" select="tan:body//tan:ana" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:morphology" mode="prep-tan-lm-for-reuse">
        <xsl:variable name="this-id" select="@xml:id"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="$morphologies-prepped-for-reuse"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:m" mode="prep-tan-lm-for-reuse">
        <xsl:variable name="this-morphology-id" select="(ancestor-or-self::*/@morphology)[last()]"/>
        <xsl:variable name="this-morphology" select="$morphologies-prepped-for-reuse/*[@morphology = $this-morphology-id]"/>
        <xsl:variable name="is-categorized" select="exists($this-morphology/tan:body/tan:category)" as="xs:boolean"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="prep-tan-lm-for-reuse">
                <xsl:with-param name="this-morphology" select="$this-morphology"/>
                <xsl:with-param name="is-categorized" select="$is-categorized"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:f" mode="prep-tan-lm-for-reuse">
        <xsl:param name="this-morphology"/>
        <xsl:param name="is-categorized" as="xs:boolean"/>
        <xsl:variable name="this-n" select="@n"/>
        <xsl:variable name="this-code" select="text()"/>
        <xsl:variable name="this-feature"
            select="
                if ($is-categorized) then
                    $this-morphology/tan:body/tan:category[number($this-n)]/tan:feature[@code = $this-code]
                else
                    $this-morphology/tan:body/tan:feature[@code = $this-code]"
        />
        <xsl:variable name="this-feature-ref" select="$this-feature/@id"/>
        <xsl:if test="exists($this-feature-ref)">
            <xsl:copy>
                <xsl:attribute name="which" select="$this-feature-ref"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:body" mode="prep-tan-lm-source-for-reuse">
        <xsl:variable name="this-source-id" select="../@src"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="prep-tan-lm-source-for-reuse">
                <xsl:with-param name="source-id" select="$this-source-id" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:tok" mode="prep-tan-lm-source-for-reuse">
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
    <xsl:template match="tei:*" mode="prep-tan-lm-source-for-reuse"/>
    
    <xsl:template match="tan:category" mode="prep-tan-lm-morphologies-for-reuse">
        <xsl:variable name="this-cat-no" select="count(preceding-sibling::tan:category) + 1"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="prep-tan-lm-morphologies-for-reuse">
                <xsl:with-param name="this-cat-no" select="$this-cat-no"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:feature" mode="prep-tan-lm-morphologies-for-reuse">
        <xsl:param name="this-cat-no"/>
        <xsl:param name="this-doc-id" tunnel="yes"/>
        <xsl:variable name="cat-no-insertion"
            select="
                if (exists($this-cat-no)) then
                    concat(string($this-cat-no), '-')
                else
                    ()"
        />
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="id" select="concat($this-doc-id, '-', $cat-no-insertion, @code)"/>
            <xsl:copy-of select="node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
