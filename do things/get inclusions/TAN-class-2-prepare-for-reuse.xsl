<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:saxon="http://saxon.sf.net/" exclude-result-prefixes="#all" version="2.0">

    <xsl:include href="TAN-core-prepare-for-reuse.xsl"/>

    <xsl:function name="tan:embed-glosses" as="item()*">
        <!-- Input: any class-2 document prepared for reuse and with glosses about tokens (TAN-A-tok, TAN-LM) -->
        <!-- Output: the same document with the relevant glosses placed inside <anchor>s that perforate <tok> and <non-tok>, placed according to the appropriate midpoint for that particular annotation. -->
        <!-- We assume that the sources have  been placed as the last child of the root element, and that every <tok> in the sources already has (or lacks) <xref gloss="[GLOSS ID NO]"/> -->
        <!-- This function was written primarily to create HTML editions of interlinear glosses showing word-for-word translation pairs and lexicomorphology. The notion is that these glosses should be inserted at the midpoint of the range of text they annotate, and that HTML + Javascript should do the job of arranging the interlinear gloss. -->
        <xsl:param name="class-2-prepped-for-reuse" as="document-node()?"/>
        <xsl:variable name="this-tan-type" select="tan:tan-type($class-2-prepped-for-reuse/*)"/>
        <!-- We first mark the string length of the divs in the sources -->
        <xsl:variable name="pass-a-string-length-analyzed">
            <xsl:apply-templates select="$class-2-prepped-for-reuse"
                mode="pass-a-string-length-analyzed"/>
        </xsl:variable>
        <!-- We now prepare the glosses, which are in the <body> of the class2 file -->
        <xsl:variable name="glosses-with-midpoints" as="element()*">
            <xsl:for-each select="$pass-a-string-length-analyzed/tan:*/tan:body//*[@gloss]">
                <xsl:variable name="this-gloss-id" select="@gloss"/>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:for-each
                        select="$pass-a-string-length-analyzed/tan:*/tan:body/following-sibling::*">
                        <!-- We now traverse the sources that have been embedded after the class 2 file's body, and identify the midpoint where that gloss will appear in that given source -->
                        <xsl:variable name="this-src" select="@src"/>
                        <xsl:variable name="these-gloss-refs"
                            select="descendant::*[tan:xref/@gloss = $this-gloss-id]"/>
                        <xsl:variable name="this-start-pos"
                            select="number($these-gloss-refs[1]/@string-pos)"/>
                        <xsl:variable name="this-end" select="$these-gloss-refs[last()]"/>
                        <xsl:variable name="this-end-pos"
                            select="number($this-end/@string-pos) + number($this-end/@string-length)"/>
                        <xsl:variable name="this-midpoint"
                            select="floor(avg(($this-start-pos, $this-end-pos)))"/>
                        <xsl:if test="exists($these-gloss-refs)">
                            <anchor>
                                <xsl:copy-of select="$this-src"/>
                                <xsl:attribute name="at" select="$this-midpoint"/>
                            </anchor>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:copy-of select="*"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="pass-b-anchor-glosses">
            <xsl:apply-templates select="$pass-a-string-length-analyzed"
                mode="pass-b-anchor-glosses">
                <xsl:with-param name="glosses" select="$glosses-with-midpoints" tunnel="yes"/>
                <xsl:with-param name="this-tan-type" select="$this-tan-type" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <!-- diagnostics, results -->
        <!--<xsl:copy-of select="$pass-a-string-length-analyzed"/>-->
        <!--<xsl:copy-of select="$glosses-with-midpoints"/>-->
        <xsl:copy-of select="$pass-b-anchor-glosses"/>
    </xsl:function>

    <xsl:template match="comment() | processing-instruction() | text()"
        mode="pass-a-string-length-analyzed pass-b-anchor-glosses">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="*" mode="pass-a-string-length-analyzed pass-b-anchor-glosses">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:TAN-T/tan:body" mode="pass-a-string-length-analyzed">
        <xsl:copy-of select="tan:analyze-string-length(.)"/>
    </xsl:template>
    <xsl:template match="tan:TAN-T" mode="pass-b-anchor-glosses">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="src" select="@src" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/*" mode="pass-b-anchor-glosses">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="* except tan:TAN-T"/>
            <xsl:apply-templates select="tan:TAN-T" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:tok | tan:non-tok" mode="pass-b-anchor-glosses">
        <xsl:param name="glosses" tunnel="yes"/>
        <xsl:param name="src" tunnel="yes"/>
        <xsl:param name="this-tan-type" tunnel="yes"/>
        <xsl:variable name="this-pos" select="xs:integer(@string-pos)"/>
        <xsl:variable name="this-range"
            select="($this-pos to ($this-pos + xs:integer(@string-length) - 1))"/>
        <xsl:variable name="these-glosses"
            select="$glosses/tan:anchor[@src = $src and xs:integer(@at) = $this-range]"/>
        <xsl:variable name="this-analyzed" select="tan:chop-string(text())"/>
        <xsl:choose>
            <xsl:when test="exists($these-glosses)">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of select="*"/>
                    <xsl:for-each select="$this-analyzed">
                        <xsl:variable name="pos" select="position()"/>
                        <xsl:variable name="glosses-to-be-anchored"
                            select="$these-glosses[@at = $this-pos + $pos - 1]"/>
                        <xsl:if test="exists($glosses-to-be-anchored)">
                            <anchor>
                                <xsl:for-each select="$glosses-to-be-anchored">
                                    <xsl:variable name="this-content">
                                        <xsl:choose>
                                            <xsl:when test="$this-tan-type = 'TAN-LM'">
                                                <xsl:copy-of select="following-sibling::tan:lm"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:copy-of select="normalize-space(string-join(following-sibling::*[not(@src = $src)]//text(), ' '))"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    <gloss>
                                        <xsl:copy-of select="parent::*/@*"/>
                                        <xsl:copy-of select="$this-content"/>
                                        <xsl:if
                                            test="not(exists($this-content)) or not(matches($this-content, '\S'))">
                                            <xsl:text>∅</xsl:text>
                                        </xsl:if>
                                    </gloss>
                                </xsl:for-each>
                            </anchor>
                        </xsl:if>
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
