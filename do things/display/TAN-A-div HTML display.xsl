<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">
    <xsl:import href="../../../tools/TEI%20stylesheets/html/html.xsl"/>
    <xsl:import href="../get%20inclusions/TAN-to-HTML-core.xsl"/>
    <xsl:output method="html" indent="yes"/>
    
    <xsl:include href="../get%20inclusions/TAN-A-div-prepare-for-reuse.xsl"/>
    <xsl:include href="../../functions/TAN-A-div-functions.xsl"/>
    
    <xsl:param name="html-template" as="document-node()?" select="doc('../configure%20templates/template-tan-a-div.html')"/>
    
    <xsl:template match="node() | @*" mode="leaf-div-to-html-table leaf-div-to-html-table-pass1 leaf-div-to-html-table-pass2">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Dummy template to suppress Saxon warning message -->
    <xsl:template match="tan:squelch"/>
    
    <xsl:template match="html:body" mode="leaf-div-to-html-table leaf-div-to-html-table-pass1">
        <xsl:variable name="src-order" as="xs:string*"
            select="
                for $i in html:div[tan:class(.) = 'TAN-A-div']/html:div[tan:class(.) = 'head']//html:div[tan:class(.) = 'source']/html:div[tan:class(.) = 'attr-id']
                return
                    concat('attr-src--', $i)"
        />
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="src-order" select="$src-order" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="html:div[tan:class(.) = 'claim']" mode="leaf-div-to-html-table-pass1">
        <xsl:param name="src-order" as="xs:string*" tunnel="yes"/>
        <xsl:copy-of select="tan:html-div-to-table(., $src-order, ('object', 'subject'))"/>
    </xsl:template>
    <xsl:template match="html:div[tan:class(.) = ('declarations')]" mode="leaf-div-to-html-table-pass1">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="html:div[tan:class(.) = 'ver'][html:table]" mode="leaf-div-to-html-table-pass2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <table>
                <tbody>
                    <tr>
                        <td>
                            <xsl:apply-templates select="node() except html:table" mode="#current"/>
                        </td>
                        <td>
                            <xsl:copy-of select="html:table"/>
                        </td>
                    </tr>
                </tbody>
            </table>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="html:div[html:div[tan:class(.) = 'ver']]" mode="leaf-div-to-html-table">
        <xsl:param name="src-order" as="xs:string*" tunnel="yes"/>
        <xsl:copy-of select="tan:html-div-to-table(., $src-order, 'ver')"/>
    </xsl:template>
    
    <xsl:function name="tan:html-div-to-table" as="element()">
        <!-- Input: any html div that should be converted to a table -->
        <!-- Output: a <table>, with any child <label> in the <thead>. <tbody> is formed by collecting all <ver> descendants, grouping and sorting them by @src, then building them into a table, one <tr> per item in the largest group. For any group that is short, all <ver>s are put into a single <td> with a @rowspan and width to accommodate. Any descendant <table>s that are not children of <ver> are placed as a single <td> at the end of the first <tr> -->
        <xsl:param name="element-to-turn-into-table" as="element()"/>
        <xsl:param name="src-order" as="xs:string*"/>
        <xsl:param name="class-name" as="xs:string+"/>
        <xsl:variable name="these-cells-grouped" as="element()*">
            <xsl:for-each-group
                select="$element-to-turn-into-table//html:div[(tan:class(.) = $class-name)][not(parent::html:td)]"
                group-by="tan:class(.)[matches(., '^attr-src--')]">
                <group key="{current-grouping-key()}">
                    <xsl:for-each select="current-group()">
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="node()"/>
                        </xsl:copy>
                    </xsl:for-each>
                </group>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="qty-of-sources" select="count($these-cells-grouped)"/>
        <xsl:variable name="max-depth"
            select="
                max(for $i in $these-cells-grouped
                return
                    count($i/*))"
        />
        <!-- In the next variable we exclude tables whose parents are html:td, because that is distinctive of source-specific alignments, which should remain in place -->
        <xsl:variable name="non-src-specific-tables"
            select="$element-to-turn-into-table//html:table[tan:class(.) = 'claim'][not(parent::html:td)]"
        />
        <!--<xsl:variable name="topic-table-groups"
            select="$element-to-turn-into-table//html:div[tan:class(.) = 'topic']"/>-->
        <xsl:variable name="col-count"
            select="
                count($these-cells-grouped) + (if (exists($non-src-specific-tables)) then
                    1
                else
                    0)"
        />
        <table>
            <xsl:copy-of select="$element-to-turn-into-table/@*"/>
            <thead>
                <tr>
                    <td colspan="{$col-count}">
                        <xsl:copy-of select="$element-to-turn-into-table/*[tan:class(.) = ('label')]"
                        />
                    </td>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="1 to $max-depth">
                    <xsl:variable name="this-depth" select="."/>
                    <tr>
                        <xsl:for-each select="$these-cells-grouped/*[$this-depth]">
                            <xsl:sort select="index-of($src-order, (tan:class(.)[matches(., '^attr-src--')]))[1]"/>
                            <xsl:choose>
                                <xsl:when test="$this-depth = 1 and not(count(../*) = $max-depth)">
                                    <!-- style="width:{100 idiv ($col-count)}%" -->
                                    <td rowspan="{$max-depth}">
                                        <xsl:copy-of select="@*"/>
                                        <xsl:copy-of select="self::*, following-sibling::*"/>
                                    </td>
                                </xsl:when>
                                <xsl:when test="$this-depth gt 1 and not(count(../*) = $max-depth)"
                                />
                                <xsl:otherwise>
                                    <td>
                                        <xsl:copy-of select="@*"/>
                                        <xsl:copy-of select="node()"/>
                                    </td>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                        <xsl:if test="exists($non-src-specific-tables) and $this-depth = 1">
                            <td class="last" rowspan="{$max-depth}">
                                <xsl:copy-of select="$non-src-specific-tables"/>
                            </td>
                        </xsl:if>
                        <!--<xsl:if test="exists($topic-table-groups) and $this-depth = 1">
                            <td class="last" rowspan="{$max-depth}">
                                <xsl:copy-of select="$topic-table-groups"/>
                            </td>
                        </xsl:if>-->
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:function>
    
    <xsl:variable name="self-html-divs-only" select="tan:tan-to-html($self-prepped-for-reuse)"/>
    
    <xsl:variable name="self-html-leaf-divs-in-tables" as="document-node()?">
        <xsl:variable name="pass1">
            <xsl:apply-templates select="$self-html-divs-only" mode="leaf-div-to-html-table-pass1"/>
        </xsl:variable>
        <xsl:variable name="pass2">
            <xsl:apply-templates select="$pass1" mode="leaf-div-to-html-table-pass2"/>
        </xsl:variable>
        <xsl:document>
            <!-- results, diagnostics -->
            <!--<xsl:copy-of select="$pass1"/>-->
            <!--<xsl:copy-of select="$pass2"/>-->
            <xsl:apply-templates select="$pass2" mode="leaf-div-to-html-table"/>
        </xsl:document>
    </xsl:variable>


    <xsl:template match="/*">
        <!-- diagnostics, results -->
        <!--<xsl:copy-of select="$self-resolved"/>-->
        <!--<xsl:copy-of select="$self-and-sources-prepped-prelim"/>-->
        <!--<xsl:copy-of select="$self-prepped"/>-->
        <!--<xsl:copy-of select="$sources-prepped"/>-->
        <xsl:copy-of select="$sources-chosen"/>
        <!--<xsl:copy-of select="$self-and-select-sources-merged"/>-->
        <!--<xsl:copy-of select="$self-prepped-for-reuse-prelim-a"/>-->
        <!--<xsl:copy-of select="$self-prepped-for-reuse-prelim-b"/>-->
        <!--<xsl:copy-of select="$self-prepped-for-reuse"/>-->
        <!--<xsl:copy-of select="$self-html-divs-only"/>-->
        <xsl:copy-of select="$self-html-leaf-divs-in-tables"/>
    </xsl:template>

</xsl:stylesheet>
