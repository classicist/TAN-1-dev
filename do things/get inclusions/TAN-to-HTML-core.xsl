<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">

    <!-- This stylesheet takes a TAN file that has been prepared for reuse (see TAN-core-prepare-for-reuse.xsl) and inserts it into an HTML template. It ignores any attributes in the TAN file, and focuses exclusively on changing each element into an html <div>, adding values to @class and @id as specified in the parameters. The name of the TAN or TEI element is automatically added to the @class -->

    <!-- to do: put <!DOCTYPE html [
    <!ENTITY nbsp "&#160;"> at head 
]>
 -->

    <xsl:include href="../../../stylesheets/configure%20parameters/html-colors.xsl"/>

    <xsl:param name="html-template-url-relative-to-this-stylesheet" as="xs:string?"
        select="'../configure%20templates/template.html'"/>
    <xsl:param name="html-template-url-relative-to-input" as="xs:string?"/>
    <xsl:variable name="html-template-url-resolved"
        select="
            if (string-length($html-template-url-relative-to-input) gt 0) then
                resolve-uri($html-template-url-relative-to-input, $doc-uri)
            else
                resolve-uri($html-template-url-relative-to-this-stylesheet, static-base-uri())"/>
    <xsl:param name="html-template" as="document-node()?" select="doc($html-template-url-resolved)"/>
    <xsl:param name="id-of-html-element-to-be-replaced-by-tan-file" as="xs:string?"/>
    <xsl:param name="css-urls-to-include" as="xs:string*"/>
    <xsl:param name="javascript-urls-to-include-at-body-end" as="xs:string*"/>
    <xsl:param name="work-color-sequence" select="$rgb-goldenrod, $rgb-LightPink, $rgb-LightBlue"/>
    <xsl:param name="language-specific-font-families" as="element()*">
        <group xmlns="tag:textalign.net,2015:ns">
            <font-family>noto</font-family>
            <font-family>Serto Urhoy</font-family>
            <font-family>Estrangelo Nisibin</font-family>
            <for-lang>syr</for-lang>
            <for-lang>syc</for-lang>
        </group>
        <group xmlns="tag:textalign.net,2015:ns">
            <font-family>antinoou</font-family>
            <font-family>noto</font-family>
            <for-lang>cop</for-lang>
        </group>
        <group xmlns="tag:textalign.net,2015:ns">
            <font-family>Minion Pro</font-family>
            <font-family>Garamond Premiere Pro</font-family>
            <font-family>Gentium Plus</font-family>
            <font-family>serif</font-family>
            <for-lang>grc</for-lang>
        </group>
    </xsl:param>
    <xsl:param name="children-whose-name-and-vals-should-be-added-to-html-div-attr-class"
        as="xs:string*"
        select="('attr-type', 'attr-group-type', 'attr-roles', 'attr-context', 'attr-src', 'attr-cert', 'attr-reuse-type', 'attr-which')"/>

    <xsl:function name="tan:tan-to-html" as="document-node()*">
        <!-- Input: any TAN documents, prepared or synthesized -->
        <!-- Output: one HTML document per input, with every element converted to a <div> and the original name of the element being placed as a value of @class; furthermore, any URLs found in text nodes will be converted to <a href=""> elements. -->
        <xsl:param name="tan-docs-prepped-for-html" as="document-node()*"/>
        <xsl:for-each select="$tan-docs-prepped-for-html">
            <xsl:document>
                <xsl:apply-templates select="$html-template" mode="tan-to-html-core">
                    <xsl:with-param name="tan-doc" select="." tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="tan:class" as="xs:string*">
        <!-- Input: any elements (probably html) with @class -->
        <!-- Output: the values of @class -->
        <xsl:param name="html-elements" as="element()*"/>
        <xsl:copy-of
            select="
                for $i in $html-elements/@class
                return
                    tokenize(tan:normalize-text($i), ' ')"
        />
    </xsl:function>


    <xsl:template match="html:*" mode="tan-to-html-core">
        <xsl:param name="tan-doc" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="@id = $id-of-html-element-to-be-replaced-by-tan-file">
                <xsl:apply-templates select="$tan-doc" mode="tan-to-html-core"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="html:head" mode="tan-to-html-core">
        <xsl:param name="tan-doc" tunnel="yes"/>
        <xsl:variable name="doc-specific-css" as="xs:string*">
            <xsl:for-each select="$tan-doc/tan:TAN-A-div/tan:body//tan:equate-works">
                <xsl:variable name="pos" select="position()"/>
                <xsl:variable name="this-work-colors" as="xs:string*"
                    select="
                        for $i in subsequence($work-color-sequence, (($pos - 1) * 3) + 1, 3)
                        return
                            string($i)"/>
                <xsl:variable name="src-count" select="count(descendant::tan:source)"/>
                <xsl:for-each select="descendant::tan:source">
                    <xsl:variable name="pos2" select="position()"/>
                    <xsl:variable name="this-lang" select="tan:body/tan:attr-lang/text()"/>
                    <xsl:variable name="this-lang-css" as="xs:string*">
                        <xsl:for-each
                            select="$language-specific-font-families[tan:for-lang = $this-lang]/tan:font-family">
                            <xsl:choose>
                                <xsl:when test="matches(., '\s')">
                                    <xsl:value-of select="concat($quot, ., $quot)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:variable name="this-src-opacity" select="string($pos2 div $src-count)"/>
                    <xsl:value-of
                        select="concat('td.attr-src--', tan:attr-id, ', div.equate-works #', tan:attr-id, '{background:rgba(', string-join($this-work-colors, ','), ',', $this-src-opacity, ')}')"/>
                    <xsl:if test="exists($this-lang-css)">
                        <xsl:value-of
                            select="concat('td.attr-src--', tan:attr-id, '{font-family:', string-join($this-lang-css, ', '), '}')"
                        />
                    </xsl:if>
                    <xsl:if test="$this-lang = ('syr', 'syc', 'ara', 'hbo')">
                        <xsl:value-of
                            select="concat('td.attr-src--', tan:attr-id, '{text-align:right}')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="not(exists(html:title))">
                <title>
                    <xsl:value-of select="$tan-doc/*/tan:head/tan:name[1]"/>
                </title>
            </xsl:if>
            <xsl:for-each select="$css-urls-to-include">
                <link rel="stylesheet" type="text/css" href="{.}"/>
            </xsl:for-each>
            <style type="text/css">
                <xsl:value-of select="$doc-specific-css"/>
            </style>
            <xsl:copy-of select="node()"/>
        </xsl:copy>
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>
    <xsl:template match="html:body" mode="tan-to-html-core">
        <xsl:param name="tan-doc" tunnel="yes"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="exists(.//*[@id = $id-of-html-element-to-be-replaced-by-tan-file])">
                    <xsl:apply-templates mode="#current"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$tan-doc" mode="tan-to-html-core"/>
                    <xsl:copy-of select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="$javascript-urls-to-include-at-body-end">
                <script src="{.}"/>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="comment()" mode="tan-to-html-core">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="processing-instruction()" mode="tan-to-html-core"/>
    <xsl:template match="text()[not(matches(., '\S'))]" mode="tan-to-html-core">
        <xsl:if test="parent::tan:tok or parent::tan:non-tok">
            <xsl:value-of select="tan:html-space(.)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="text()[matches(., '\S')]" mode="tan-to-html-core">
        <xsl:copy-of select="tan:html-space(tan:hyperlink-text(.))"/>
    </xsl:template>


    <xsl:template match="tan:attr-href" mode="tan-to-html-core">
        <xsl:variable name="this-href" select="."/>
        <xsl:variable name="new-div" select="tan:element-to-html-div(., (), (), true())"/>
        <xsl:variable name="base-uri" select="(root(.)/*/tan:attr-base-uri/text(), base-uri(.))[1]"/>
        <div>
            <xsl:copy-of select="$new-div/@*"/>
            <xsl:apply-templates select="$new-div/*" mode="tan-to-html-core"/>
            <a href="{$this-href}">
                <xsl:value-of select="$this-href"/>
            </a>
        </div>
            
                
            
        
    </xsl:template>
    <xsl:template match="tan:* | tei:*" mode="tan-to-html-core">
        <xsl:param name="adjoins-mixed-content" as="xs:boolean" select="false()"/>
        <xsl:param name="parent-is-ltr" as="xs:boolean" select="true()"/>
        <xsl:variable name="this-element" select="."/>
        <xsl:variable name="this-for-element" select="name($this-element)"/>
        <xsl:variable name="this-parent-name" select="name(..)"/>
        <xsl:variable name="this-non-space-text"
            select="replace(string-join(text(), ''), '\P{L}+', '')"/>
        <!-- covers Arabic, Syriac, Thaana, Hebrew -->
        <xsl:variable name="is-rtl" as="xs:boolean"
            select="
                matches($this-non-space-text, '^[\p{IsHebrew}\p{IsArabic}\p{IsSyriac}\p{IsThaana}]+$')
                or matches(tan:attr-lang/text(), '^(syr|ara|hbo|syc|heb|aao|abh|abv|acm|acq|acw|acx|acy|adf|aeb|aec|afb|ajp|apc|apd|arb|arq|ars|ary|arz|auz|avl|ayh|ayl|ayn|ayp|bbz|pga|shu|ssh)')"/>
        <xsl:variable name="is-ltr" as="xs:boolean"
            select="matches($this-non-space-text, '^[^\p{IsHebrew}\p{IsArabic}\p{IsSyriac}\p{IsThaana}]+$')"/>
        <xsl:variable name="contains-mixed-content"
            select="exists(*) and exists(text()[matches(., '\S')])"/>

        <xsl:variable name="extra-class-vals" as="xs:string*">
            <xsl:value-of select="@class"/>
            <xsl:if test="$adjoins-mixed-content = true()">
                <xsl:text>mixed</xsl:text>
            </xsl:if>
            <xsl:if test="exists(tan:source) and $this-for-element = ('sources', 'equate-works')">
                <xsl:text>sortable</xsl:text>
            </xsl:if>
            <xsl:for-each
                select="*[name() = $children-whose-name-and-vals-should-be-added-to-html-div-attr-class]">
                <xsl:value-of
                    select="
                        for $i in tokenize(text(), ' ')
                        return
                            concat(name(.), '--', $i)"
                />
            </xsl:for-each>
            <xsl:if test="self::tan:div">
                <xsl:value-of select="root()//id($this-element/@type)/tan:group"/>
            </xsl:if>
            <!-- To support TAN-A-tok and TAN-LM files mark <tok> or <non-tok>s with glosses -->
            <xsl:value-of select="(self::tan:xref, tan:xref)/tan:attr-gloss"/>
            <!-- To support TAN-A-tok and TAN-LM files that embed glosses within a <tok> or <non-tok> -->
            <xsl:value-of select="self::tan:gloss/tan:attr-gloss"/>
        </xsl:variable>
        <xsl:variable name="id-val" as="xs:string?">
            <xsl:choose>
                <xsl:when test="tan:ref">
                    <xsl:value-of select="replace(@ref, '\s', '_')"/>
                </xsl:when>
                <xsl:when test="tan:attr-id">
                    <xsl:choose>
                        <xsl:when test="ancestor::tan:head">
                            <!-- If the element is in the head, we prefix the element's name, because TAN allows duplicate "id" values (values of @which) for different kinds of elements -->
                            <xsl:value-of select="concat(name($this-element), '-', tan:attr-id)"/>
                        </xsl:when>
                        <xsl:when test="self::tan:div"/>
                        <xsl:otherwise>
                            <xsl:value-of select="tan:attr-id"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="new-div"
            select="tan:element-to-html-div(., $extra-class-vals, $id-val, true())"/>
        <div>
            <xsl:copy-of select="$new-div/@*"/>
            <xsl:if test="$parent-is-ltr = true() and $is-rtl = true()">
                <xsl:attribute name="dir" select="'rtl'"/>
            </xsl:if>
            <xsl:if test="$parent-is-ltr = false() and $is-ltr = true()">
                <xsl:attribute name="dir" select="'ltr'"/>
            </xsl:if>
            <xsl:copy-of select="$new-div/*"/>
            <xsl:apply-templates select="$this-element/node()" mode="tan-to-html-core">
                <xsl:with-param name="adjoins-mixed-content" select="$contains-mixed-content"/>
                <xsl:with-param name="parent-is-ltr"
                    select="
                        if ($is-rtl = true()) then
                            false()
                        else
                            if ($is-ltr = true()) then
                                true()
                            else
                                $parent-is-ltr"
                />
            </xsl:apply-templates>
        </div>

    </xsl:template>


    <xsl:function name="tan:hyperlink-text" as="item()*">
        <xsl:param name="text" as="xs:string*"/>
        <xsl:copy-of select="tan:hyperlink-text($text, ())"/>
    </xsl:function>
    <xsl:function name="tan:hyperlink-text" as="item()*">
        <!-- Input: any text that might have URLs to be hyperlinked in HTML -->
        <!-- Output: the same text with <a href=""> enclosing any URLs that are picked up. -->
        <xsl:param name="text" as="xs:string*"/>
        <xsl:param name="truncate-long-urls-at-length" as="xs:integer?"/>
        <xsl:for-each select="$text">
            <xsl:analyze-string select="." regex="((ht|f)tps?://|file:/)[\w+]+\.[\S]+">
                <xsl:matching-substring>
                    <xsl:variable name="url-norm" select="."/>
                    <a href="{$url-norm}">
                        <xsl:choose>
                            <xsl:when test="$truncate-long-urls-at-length gt 0">
                                <xsl:value-of
                                    select="
                                        concat(substring($url-norm, 1, $truncate-long-urls-at-length), if (string-length($url-norm) gt $truncate-long-urls-at-length) then
                                            '&#x2026;'
                                        else
                                            ())"
                                />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$url-norm"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </a>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:for-each>
    </xsl:function>

    <xsl:template match="html:*" mode="html-space">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:function name="tan:html-space" as="item()*">
        <!-- Input: any html -->
        <!-- Output: any front or end spaces replaced with &#xa0; -->
        <xsl:param name="html" as="item()*"/>
        <xsl:apply-templates select="$html" mode="html-space"/>
    </xsl:function>
    <xsl:template match="text()" mode="html-space">
        <xsl:value-of select="replace(., '^\s|\s$', '&#xa0;')"/>
    </xsl:template>

    <xsl:function name="tan:element-to-html-div" as="element()?">
        <!-- Input: any non-HTML element, along with a list of attribute names and values that should be retained  as children <div>s, a list of values to be added to the element name to make up the new @class attribute, and perhaps a value for the @id of the new div -->
        <!-- Output: a new HTML div reflecting the choices above -->
        <xsl:param name="non-html-element" as="element()?"/>
        <xsl:param name="vals-to-append-to-attr-class" as="xs:string*"/>
        <xsl:param name="id-ref" as="xs:string?"/>
        <xsl:param name="shallow-copy" as="xs:boolean"/>
        <xsl:variable name="this-namespace" select="namespace-uri($non-html-element)"/>
        <xsl:variable name="is-tei" select="$this-namespace = 'http://www.tei-c.org/ns/1.0'"/>
        <xsl:variable name="namespace-prefix"
            select="
                if ($is-tei = true()) then
                    'tei-'
                else
                    ()"/>
        <xsl:variable name="this-for-element"
            select="concat($namespace-prefix, name($non-html-element))"/>
        <div
            class="{normalize-space(string-join(($this-for-element, $vals-to-append-to-attr-class),' '))}">
            <xsl:if test="string-length($id-ref) gt 0">
                <xsl:attribute name="id" select="$id-ref"/>
            </xsl:if>
            <xsl:if test="$shallow-copy = false()">
                <xsl:copy-of select="$non-html-element/node()"/>
            </xsl:if>
        </div>
    </xsl:function>

    <xsl:function name="tan:element-to-tr" as="element()?">
        <!-- Input: any element that is to be thought of as a table row, with anomalous descendants (an unpredictable number of leaf elements and of levels of descendants) -->
        <!-- Output: the element converted to a <tr> populated only with its descendants converted to <td>s, with @colspan or @rowspan values added where relevant, indicating how much row or column space a descendant should take. -->
        <xsl:param name="element-to-convert-to-row" as="element()?"/>
        <xsl:param name="max-depth" as="xs:integer"/>
        <xsl:variable name="element-name" select="name($element-to-convert-to-row)"/>
        <xsl:for-each select="1 to $max-depth">
            <xsl:variable name="this-depth" select="."/>
            <xsl:variable name="rowspan-val" select="$max-depth - $this-depth + 1"/>
            <xsl:element name="{$element-name}">
                <xsl:copy-of select="$element-to-convert-to-row/@*"/>
                <xsl:for-each
                    select="$element-to-convert-to-row//*[count(ancestor::*) = $this-depth]">
                    <xsl:variable name="colspan-val" select="count(.//*[not(*)])"/>
                    <xsl:choose>
                        <xsl:when test="exists(*)">
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:if test="$colspan-val gt 1">
                                    <xsl:attribute name="colspan" select="$colspan-val"/>
                                </xsl:if>
                                <xsl:value-of select="(@label, ' ')[1]"/>
                            </xsl:copy>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:if test="$rowspan-val gt 1">
                                    <xsl:attribute name="rowspan" select="$rowspan-val"/>
                                </xsl:if>
                                <xsl:value-of select="(@label, ' ')[1]"/>
                            </xsl:copy>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>
</xsl:stylesheet>
