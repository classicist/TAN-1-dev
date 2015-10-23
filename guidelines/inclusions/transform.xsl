<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns="http://docbook.org/ns/docbook"
    xmlns:saxon="http://icl.com/saxon" xmlns:lxslt="http://xml.apache.org/xslt"
    xmlns:redirect="http://xml.apache.org/xalan/redirect" xmlns:exsl="http://exslt.org/common"
    xmlns:doc="http://nwalsh.com/xsl/documentation/1.0" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
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
    <xsl:variable name="rng-collection-without-TEI" select="$rng-collection[not(matches(base-uri(.),'TAN-TEI'))]"/>
    <xsl:variable name="sch-collection" select="collection('../../schemas/?select=*.sch;recurse=yes')"/>
    <xsl:variable name="fn-collection" select="collection('../../functions/?select=*.xsl;recurse=yes')"/>
    <xsl:variable name="element-names-excl-TEI" select="$rng-collection[not(matches(base-uri(.),'TAN-TEI'))]//rng:element/@name"/>
    <xsl:variable name="attribute-names-excl-TEI" select="$rng-collection[not(matches(base-uri(.),'TAN-TEI'))]//rng:attribute/@name"/>

    <xsl:template match="/kalv:*">
        <!-- [1] may be inserted below to restrict to testing; remove it to get everything -->
        <xsl:for-each select="$rng-collection[1]">
            <xsl:variable name="this-rng-pos" select="position()"/>
            <xsl:variable name="this" select="."/>
            <xsl:variable name="this-name" select="replace(base-uri($this),'.+/(.+)\.rng$','$1')"/>
            <xsl:variable name="these-element-names" as="xs:string*">
                <xsl:for-each select="$this//rng:element/@name">
                    <xsl:sort/>
                    <xsl:copy-of select="."/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="these-attribute-names" as="xs:string*">
                <xsl:for-each select="$this//rng:attribute/@name">
                    <xsl:sort/>
                    <xsl:copy-of select="."/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="these-element-summaries">
                <xsl:apply-templates select="$this//rng:element">
                    <xsl:sort select="lower-case(@name)"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:variable name="these-attribute-summaries">
                <xsl:apply-templates select="$this//rng:attribute">
                    <xsl:sort select="lower-case(@name)"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:result-document href="{concat($this-name,'.xml')}">
                <section>
                    <xsl:attribute name="version" select="'5.0'"/>
                    <title>
                        <xsl:value-of select="$this-name"/> elements and attributes summarized</title>
                    <para><emphasis>Elements</emphasis>: <xsl:copy-of select="$these-element-names"/></para>
                    <para><emphasis>Attributes</emphasis>: <xsl:copy-of select="$these-attribute-names"/></para>
                    <xsl:sequence select="$these-element-summaries"/>
                    <xsl:sequence select="$these-attribute-summaries"/>
                </section>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="rng:element | rng:attribute" name="rng-element">
        <xsl:variable name="this-name" select="@name"/>
        <xsl:variable name="prefix"
            select="
                if (name() = 'element') then
                    '&lt;'
                else
                    '@'"/>
        <xsl:variable name="suffix"
            select="
                if (name() = 'element') then
                    '>'
                else
                    ''"/>
        <section xml:id="{concat('tan-',name(.),'-',$this-name)}">
            <title>
                <code>
                    <xsl:value-of select="$prefix"/>
                    <xsl:value-of select="$this-name"/>
                    <xsl:value-of select="$suffix"/>
                </code>
            </title>
            <xsl:apply-templates select="a:documentation"/>
            <xsl:variable name="formaldef" as="xs:string?">
                <xsl:variable name="raw" as="xs:string*">
                    <xsl:apply-templates select="rng:*" mode="formaldef"/>
                </xsl:variable>
                <xsl:variable name="raw-joined" select="string-join($raw, '')"/>
                <xsl:variable name="strip-trailing-spaces"
                    select="replace($raw-joined, '([\(])\s+', '$1')"/>
                <xsl:variable name="strip-preceding-spaces" select="replace($strip-trailing-spaces,'\s+([\)])','$1')"/>
                <xsl:variable name="add-trailing-spaces"
                    select="replace($strip-preceding-spaces, '([,])', '$1 ')"/>
                <xsl:variable name="strip-preceding-spaces"
                    select="replace($add-trailing-spaces, '\s+([\?])', '$1')"/>
                <xsl:variable name="final" select="$strip-preceding-spaces"/>
                <xsl:value-of select="normalize-space($final)"/>
            </xsl:variable>
            <para>Definition: <code><xsl:value-of select="$formaldef"/></code></para>
            <para>Parent(s): <xsl:for-each
                select="kalv:get-parent-elements(./(ancestor::rng:define, ancestor::rng:element)[last()])">
                    <code>
                        <xsl:value-of select="@name"/>
                        <xref linkend="{concat('tan-element-',@name)}"/>
                    </code>
                </xsl:for-each></para>
        </section>
    </xsl:template>
    
    <xsl:template match="a:documentation">
        <para>
            <xsl:value-of
                select="
                    concat(upper-case(substring(name(..), 1, 1)),
                    substring(name(..), 2))"
            />
            <xsl:text>: </xsl:text>
            <code>
                <xsl:value-of select="../@name"/>
            </code>:
            <emphasis><xsl:sequence select="kalv:tag-codes(.)"/></emphasis>
        </para>
    </xsl:template>
    
    <!-- Formal definition templates -->
    <xsl:template match="rng:optional" mode="formaldef">
        <xsl:apply-templates mode="formaldef"/>
        <xsl:text>?</xsl:text>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:choice" mode="formaldef">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates mode="formaldef"/>
        <xsl:text>)</xsl:text>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:ref" mode="formaldef">
        <xsl:variable name="name" select="@name"/>
        <xsl:if test="parent::rng:choice and preceding-sibling::rng:ref">|</xsl:if>
        <!--<xsl:value-of select="@name"/>-->
        <xsl:apply-templates select="$rng-collection-without-TEI//rng:define[@name = $name]" mode="formaldef"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:define[count(rng:*) gt 1]" mode="formaldef">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="rng:*" mode="formaldef"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="rng:define[count(rng:*) le 1]" mode="formaldef">
        <xsl:apply-templates select="rng:*" mode="formaldef"/>
    </xsl:template>
    <xsl:template match="rng:element" mode="formaldef">
        &lt;<xsl:value-of select="@name"/>&gt;
        <xref linkend="{concat('tan-element-',@name)}"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:attribute" mode="formaldef">
        @<xsl:value-of select="@name"/>
        <xref linkend="{concat('tan-attribute-',@name)}"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template name="comma-check">
        <xsl:if test="following-sibling::rng:*">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:function name="kalv:tag-codes" as="item()*">
        <xsl:param name="text" as="xs:string?"/>
        <xsl:variable name="code-check" select="analyze-string($text,'&lt;[^&gt;]+&gt;|@[-\w]+')"/>
        <!--<xsl:sequence select="$code-check"/>-->
        <xsl:for-each select="$code-check/*">
            <xsl:choose>
                <xsl:when test="self::fn:non-match">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <code><xsl:value-of select="."/></code>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>
    <xsl:function name="kalv:get-parent-element-names" as="xs:string*">
        <xsl:param name="self-name" as="xs:string"/>
        <xsl:copy-of select="kalv:get-parent-elements($rng-collection-without-TEI//(rng:element, rng:attribute)[@name=$self-name]//(ancestor::rng:define, ancestor::rng:element)[last()])"/>
    </xsl:function>
    <xsl:function name="kalv:get-parent-elements" as="element()*">
        <xsl:param name="current-elements" as="element()*"/>
        <xsl:variable name="elements-to-define" select="$current-elements[self::rng:define]"/>
        <xsl:choose>
            <xsl:when test="exists($elements-to-define)">
                <xsl:variable name="new-elements" select="for $i in $elements-to-define/@name return $rng-collection-without-TEI//rng:ref[@name = $i]//(ancestor::rng:define, ancestor::rng:element)[last()]"/>
                <xsl:copy-of select="kalv:get-parent-elements((($current-elements except $current-elements[name(.) = 'define']),$new-elements))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$current-elements"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- placed here to suppress warning message -->
    <xsl:template match="kalv:component"/>
</xsl:stylesheet>
