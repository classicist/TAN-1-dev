<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns="http://docbook.org/ns/docbook"
    xmlns:saxon="http://icl.com/saxon" xmlns:lxslt="http://xml.apache.org/xslt"
    xmlns:redirect="http://xml.apache.org/xalan/redirect" xmlns:exsl="http://exslt.org/common"
    xmlns:doc="http://nwalsh.com/xsl/documentation/1.0" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
    xmlns:kalv="tag:kalvesmaki.com,2015:ns" extension-element-prefixes="saxon redirect lxslt exsl"
    exclude-result-prefixes="xs math xd saxon lxslt redirect exsl doc kalv" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Updated </xd:b> Oct 20, 2015</xd:p>
            <xd:p>Stylesheet to transform master-list.xml into a series of Docbook inclusions for
                the TAN guidelines, documenting how the schemas work.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="sequence" select="//kalv:section/@which"/>

    <xsl:variable name="ex-collection" select="collection('../../examples/?select=*.xml;recurse=yes'),collection('../../TAN-R-tok/?select=*.xml;recurse=yes')"/>
    <xsl:variable name="rng-collection" select="collection('../../schemas/?select=*.rng;recurse=yes')"/>
    <xsl:variable name="sch-collection" select="collection('../../schemas/?select=*.sch;recurse=yes')"/>
    <xsl:variable name="fn-collection" select="collection('../../functions/?select=*.xsl;recurse=yes')"/>
    <xsl:variable name="element-names" select="$rng-collection//rng:element/@name"/>

    <xsl:template match="/kalv:*">
        <!-- [1] may be inserted below to restrict to testing; remove it to get everything -->
        <xsl:for-each select="$rng-collection[1]">
            <xsl:variable name="this-rng-pos" select="position()"/>
            <xsl:variable name="this" select="."/>
            <xsl:variable name="this-name" select="replace(base-uri($this),'.+/(.+)\.rng$','$1')"/>
            <xsl:variable name="these-elements">
                <xsl:apply-templates select="$this//rng:element">
                    <xsl:sort select="lower-case(@name)"/>
                </xsl:apply-templates>
                <!--<xsl:for-each select="$this//rng:element">
                    <xsl:call-template name="rng-element"/>
                </xsl:for-each>-->
            </xsl:variable>
            <xsl:result-document href="{concat($this-name,'.xml')}">
                <section>
                    <xsl:attribute name="version" select="'5.0'"/>
                    <title>
                        <xsl:value-of select="$this-name"/> elements at a glance</title>
                    <para>all elements: <xsl:value-of select="distinct-values($element-names[not(matches(.,'ns\d*:'))])"/></para>
                    <para>duplicate elements: <xsl:value-of select="$element-names[index-of($element-names,.)[2]]"/></para>
                    <para>
                        <table frame="all">
                            <title>Synopsis of elements</title>
                            <tgroup cols="4">
                                <colspec colname="c1" colnum="1" colwidth="1.59*"/>
                                <colspec colname="c2" colnum="2" colwidth="1*"/>
                                <colspec colname="c3" colnum="3" colwidth="1.44*"/>
                                <colspec colname="c4" colnum="4" colwidth="1.75*"/>
                                <thead>
                                    <row>
                                        <entry>name</entry>
                                        <entry>definition</entry>
                                        <entry>description</entry>
                                        <entry>used by</entry>
                                    </row>
                                </thead>
                                <tbody>
                                    <xsl:sequence select="$these-elements"/>
                                </tbody>
                            </tgroup>
                        </table>
                    </para>
                </section>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="rng:element" name="rng-element">
        <xsl:variable name="this-name" select="@name"/>
        <row xml:id="{concat('tan-element-',$this-name)}">
            <entry>
                <code>
                    <xsl:value-of select="$this-name"/>
                </code>
            </entry>
            <entry/>
            <entry>
                <xsl:value-of select="preceding-sibling::a:documentation"/>
            </entry>
            <entry>
                <xsl:for-each
                    select="$rng-collection//rng:ref[@name = $this-name]/ancestor::rng:element/@name">
                    <code>
                        <xsl:value-of select="."/>
                        <xref linkend="{concat('tan-element-',.)}"/>
                    </code>
                </xsl:for-each>
            </entry>
        </row>
    </xsl:template>
    <!-- placed here to suppress warning message -->
    <xsl:template match="kalv:component"/>
</xsl:stylesheet>
