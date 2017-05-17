<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:include href="TAN-core-prepare-for-reuse.xsl"/>

    <!-- Two ways to filter out sources (both will be applied): -->
    <!-- (1) A regular expression applied to the @id value of each source -->
    <xsl:param name="src-id-regex-filter" as="xs:string?" select="()"/>
    <!-- (2) idrefs to the id values of <source> -->
    <xsl:param name="src-id-name-filter" as="xs:string*" select="()"/>

    <xsl:param name="work-filter" as="xs:string?" select="'1'"/>

    <xsl:param name="compare-src-text" as="element()*">
        <!-- In this parameter, we create pairs of source idrefs. Every leaf div in @src will be processed via tan:diff-raw() against any corresponding leaf div found in @to -->
        <compare src="example-source" to="old-example-source"/>
    </xsl:param>

    <xsl:variable name="src-id-filter-norm"
        select="
            if (string-length($src-id-regex-filter) lt 1) then
                ()
            else
                replace($src-id-regex-filter, '\*', '.+')"/>
    <xsl:variable name="sources-chosen" as="document-node()+"
        select="
            $sources-prepped[if (exists($src-id-filter-norm)) then
                matches(*/@src, $src-id-filter-norm)
            else
                true()][(if (exists($src-id-name-filter)) then
                */@src = $src-id-name-filter
            else
                true())]"/>
    <xsl:variable name="sources-chosen-ids" select="$sources-chosen/*/@src"/>
    <xsl:variable name="self-and-select-sources-merged"
        select="tan:merge-tan-a-div-prepped($self-prepped, $sources-chosen, false(), $work-filter)"/>

    <xsl:variable name="self-prepped-for-reuse-prelim-a">
        <xsl:apply-templates select="$self-and-select-sources-merged"
            mode="prep-tan-a-div-for-reuse-pass-a-populate-claims"/>
    </xsl:variable>
    <xsl:variable name="self-prepped-for-reuse-prelim-b">
        <xsl:apply-templates select="$self-prepped-for-reuse-prelim-a"
            mode="prep-tan-a-div-for-reuse-pass-b-collate-claims"/>
    </xsl:variable>
    <xsl:variable name="self-prepped-for-reuse">
        <xsl:apply-templates select="$self-prepped-for-reuse-prelim-b" mode="prep-tan-for-reuse"/>
    </xsl:variable>

    <xsl:template match="comment() | processing-instruction() | text()"
        mode="prep-tan-a-div-for-reuse-pass-a-populate-claims prep-tan-a-div-for-reuse-pass-b-collate-claims">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="*"
        mode="prep-tan-a-div-for-reuse-pass-a-populate-claims prep-tan-a-div-for-reuse-pass-b-collate-claims">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:head" mode="prep-tan-a-div-for-reuse-pass-a-populate-claims">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
        <xsl:if test="string-length($work-filter) gt 0">
            <parameter>Sources have been restricted to specific works: <xsl:value-of
                    select="$work-filter"/></parameter>
        </xsl:if>
        <xsl:if test="count($sources-chosen-ids) != count($src-ids)">
            <parameter>Sources <xsl:value-of select="$src-ids[not(. = $sources-chosen-ids)]"/>
                excluded</parameter>
        </xsl:if>
    </xsl:template>



    <!-- we drop sources not used from the header altogether -->
    <xsl:template match="tan:source[not(@xml:id = $sources-chosen-ids)]"
        mode="prep-tan-a-div-for-reuse-pass-a-populate-claims"/>
    <xsl:template match="tan:claim" mode="prep-tan-a-div-for-reuse-pass-a-populate-claims">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <!-- Placeholder for future adaptations of the claim -->
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:subject[tan:div] | tan:object[tan:div]"
        mode="prep-tan-a-div-for-reuse-pass-a-populate-claims">
        <xsl:variable name="this-src" select="@src"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="* except tan:div"/>
            <xsl:for-each select="tan:div">
                <xsl:variable name="this-div" select="."/>
                <xsl:variable name="div-text"
                    select="tan:convert-ref-to-div-fragment($sources-prepped[*/@src = $this-src], $this-div, true(), true())"/>
                <xsl:for-each select="$div-text">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:choose>
                            <xsl:when test="exists(tei:*)">
                                <xsl:copy-of select="tei:*"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="text()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>


    <!-- we dispense with claim here, because we're moving claims into the text itself -->
    <xsl:template match="tan:claim" mode="prep-tan-a-div-for-reuse-pass-b-collate-claims"/>
    <xsl:template match="tan:equate-works" mode="prep-tan-a-div-for-reuse-pass-b-collate-claims">
        <xsl:variable name="these-srcs" select="tan:work/@src"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <work>
                <xsl:for-each-group select="tan:work/*" group-by=".">
                    <xsl:copy-of select="current-group()[1]"/>
                </xsl:for-each-group>
            </work>
            <xsl:for-each select="/tan:TAN-A-div/tan:head/tan:source[@xml:id = $these-srcs]">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="src" select="@xml:id"/>
                    <xsl:copy-of select="node()"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:copy>

    </xsl:template>
    <xsl:template match="tan:TAN-A-div/tan:work"
        mode="prep-tan-a-div-for-reuse-pass-b-collate-claims">
        <xsl:variable name="all-claims" select="preceding-sibling::tan:body/tan:claim"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="all-claims" select="$all-claims" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:div" mode="prep-tan-a-div-for-reuse-pass-b-collate-claims">
        <xsl:param name="all-claims" as="element()*" tunnel="yes"/>
        <xsl:variable name="these-srcs" select="tokenize(@src, ' ')"/>
        <xsl:variable name="this-ref" select="@ref"/>
        <xsl:variable name="source-specific-text-claims"
            select="$all-claims[tan:*[@src = $these-srcs][tan:div[1]/@ref = $this-ref][not(@work)]]"/>
        <xsl:variable name="work-specific-text-claims"
            select="$all-claims[tan:*[@src = $these-srcs][tan:div[1]/@ref = $this-ref][@work]]"/>
        <xsl:choose>
            <xsl:when test="not(exists(tan:div)) and not(exists(tan:ver))"/>
            <!-- If the <div> is empty, maybe because all the children have been realigned, skip it -->
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="prep-tan-a-div-for-reuse-pass-b-collate-claims">
                        <xsl:with-param name="special-claims" select="$source-specific-text-claims"
                        />
                    </xsl:apply-templates>
                    <xsl:for-each select="$work-specific-text-claims">
                        <xsl:variable name="this-subject-or-object"
                            select="tan:*[@src = $these-srcs][tan:div[1]/@ref = $this-ref][@work]"/>
                        <xsl:variable name="this-type"
                            select="
                                for $i in $this-subject-or-object
                                return
                                    name($i)"/>
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="*[not(name(.) = $this-type)]"/>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tan:ver" mode="prep-tan-a-div-for-reuse-pass-b-collate-claims">
        <xsl:param name="special-claims" as="element()*"/>
        <!--<xsl:param name="inherited-topics" as="element()*"/>-->
        <xsl:variable name="this-src" select="@src"/>
        <xsl:variable name="this-ref" select="../@ref"/>
        <xsl:variable name="this-orig-ref" select="../@orig-ref"/>
        <xsl:variable name="these-claims"
            select="$special-claims[@src = $this-src][tan:div[1]/@ref = $this-ref][not(@work)]"/>
        <xsl:variable name="this-attr-element"
            select="preceding-sibling::tan:attr[@src = $this-src and @orig-ref = $this-orig-ref]"/>
        <xsl:variable name="cf-src-id" select="($compare-src-text[@src = $this-src]/@to)[1]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <!-- We copy the pre-aligned ref, in case we want @pre-realign-ref but not <attr> -->
            <xsl:copy-of select="$this-attr-element/@pre-realign-ref"/>
            <xsl:choose>
                <xsl:when test="exists($cf-src-id)">
                    <xsl:variable name="text-to-compare-against"
                        select="$sources-prepped[*/@src = $cf-src-id]/tan:TAN-T/tan:body//tan:div[@ref = $this-ref]"/>
                    <xsl:choose>
                        <xsl:when test="exists($text-to-compare-against)">
                            <xsl:copy-of
                                select="tan:raw-diff(text(), $text-to-compare-against/text())/*"
                                copy-namespaces="no"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="not(exists(tei:*))">
                                <xsl:value-of select="text()"/>
                            </xsl:if>
                            <xsl:apply-templates select="tei:*" mode="#current"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="not(exists(tei:*))">
                        <xsl:value-of select="text()"/>
                    </xsl:if>
                    <xsl:apply-templates select="tei:*" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="$these-claims">
                <xsl:variable name="this-subject-or-object"
                    select="tan:*[@src = $this-src][tan:div[1]/@ref = $this-ref][not(@work)]"/>
                <xsl:variable name="this-type"
                    select="
                        for $i in $this-subject-or-object
                        return
                            name($i)"/>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of select="*[not(name(.) = $this-type)]"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
