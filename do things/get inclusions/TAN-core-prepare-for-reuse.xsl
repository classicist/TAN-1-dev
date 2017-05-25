<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:saxon="http://saxon.sf.net/" exclude-result-prefixes="#all" version="2.0">

    <!-- This stylesheet, coupled with its major parameter, is intended to perform major structural alterations on any TAN file in preparation for its reuse. HTML is primarily in mind, so attributes are either converted to children elements or dropped altogether. Elements part of non-mixed content may be reordered, and elements can be marked as needing to be grouped if there are more than one of them as siblings. Further, any element or attribute may be prefaced by a <label>, whose text content will notify the significance of the data that follows. -->

    <xsl:param name="reorder-param-url-relative-to-this-stylesheet" as="xs:string?"
        select="'../configure%20parameters/reorder-and-relabel-TAN-nodes.xml'"/>
    <xsl:param name="reorder-param-url-relative-to-input" as="xs:string?"/>
    <xsl:variable name="reorder-param-url-resolved"
        select="
            if (string-length($reorder-param-url-relative-to-input) gt 0) then
                resolve-uri($reorder-param-url-relative-to-input, $doc-uri)
            else
                resolve-uri($reorder-param-url-relative-to-this-stylesheet, static-base-uri())"/>
    <xsl:variable name="params" as="document-node()?"
        select="doc($reorder-param-url-resolved)"/>
    <xsl:variable name="lbrace" select="'{'" as="xs:string"/>
    <xsl:variable name="rbrace" select="'}'" as="xs:string"/>
    <xsl:variable name="xpath-pattern" select="'\{[^\}]+?\}'"/>

    <xsl:template match="comment() | processing-instruction() | text()" mode="prep-tan-for-reuse">
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template match="*" mode="prep-tan-for-reuse">
        <xsl:param name="is-grouped" as="xs:boolean" select="false()"/>
        <xsl:variable name="this-element" select="."/>
        <xsl:variable name="this-element-name" select="name(.)"/>
        <xsl:variable name="this-param" select="$params/*/tan:element[@name = $this-element-name]"/>
        <xsl:variable name="this-action" select="($this-param/@action, $params/*/@action)[1]"/>
        <xsl:variable name="this-namespace" select="namespace-uri()"/>
        <xsl:variable name="is-div-with-tei-children" select="exists(self::tan:div/tei:*)"/>
        <xsl:variable name="is-div-with-tei-descendants" select="exists(self::tan:div//tei:*)"/>
        <xsl:variable name="attr-become-elements" as="xs:boolean"
            select="tan:true(($this-param/@convert-attributes-to-elements, $params/*/@convert-attributes-to-elements))[1]"
        />

        <xsl:choose>
            <xsl:when test="exists($this-param/@replace-with)">
                <xsl:apply-templates select="tan:evaluate($this-param/@replace-with, $this-element)" mode="#current"/>
            </xsl:when>
            <xsl:when test="$this-action = 'deep-skip'"/>
            <xsl:when test="$this-action = 'deep-copy'">
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="pass-1" as="element()">
                    <xsl:copy copy-namespaces="no">
                        <!-- First, deal with attributes and the label -->
                        <xsl:if test="$attr-become-elements">
                            <xsl:copy-of select="tan:get-label(., $is-grouped)"/>
                        </xsl:if>
                        <xsl:for-each select="@*">
                            <xsl:sort
                                select="($params/*/tan:attribute[@name = name(current())]/@priority, $params/*/@priority, 5)[1]"/>
                            <xsl:variable name="this-attr" select="."/>
                            <xsl:variable name="this-attr-name" select="name(.)"/>
                            <xsl:variable name="this-attr-param" select="$params/*/tan:attribute[@name = $this-attr-name]"/>
                            <xsl:variable name="this-attr-action" select="($this-attr-param/@action, $params/*/@action)[1]"/>
                            <xsl:choose>
                                <xsl:when test="matches($this-attr-action, 'skip')"/>
                                <xsl:when test="not($attr-become-elements)">
                                    <xsl:copy-of select="."/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- The following variable converts xml:id, xml:lang, etc. to simply tan names -->
                                    <xsl:variable name="this-attr-name"
                                        select="concat('attr-', replace($this-attr-name, 'xml:', ''))"/>
                                    <xsl:variable name="holds-id-refs"
                                        select="$id-idrefs//@attribute = $this-attr-name"/>
                                    <xsl:variable name="tokenized-values" select="tokenize(normalize-space(.), ' ')"/>
                                    <xsl:variable name="group-min" select="tan:group-min(.)"/>
                                    <xsl:choose>
                                        <xsl:when
                                            test="$group-min le count($tokenized-values) and $holds-id-refs = true() and count($tokenized-values) gt 1">
                                            <xsl:element name="{concat($this-attr-name,'s')}">
                                                <xsl:copy-of select="tan:get-label(., true())"/>
                                                <xsl:for-each select="$tokenized-values">
                                                    <xsl:element name="{$this-attr-name}">
                                                        <xsl:copy-of select="tan:get-label($this-attr, true())"/>
                                                        <xsl:value-of select="."/>
                                                    </xsl:element>
                                                </xsl:for-each>
                                            </xsl:element>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:element name="{$this-attr-name}" namespace="{$this-namespace}">
                                                <xsl:copy-of select="tan:get-label(., false())"/>
                                                <xsl:value-of select="."/>
                                            </xsl:element>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                        <xsl:if test="not($attr-become-elements)">
                            <xsl:copy-of select="tan:get-label(., $is-grouped)"/>
                        </xsl:if>
                        
                        <!-- Second: reorder, group, and process children nodes -->
                        <xsl:apply-templates select="tan:evaluate($this-param/@prepend, $this-element)" mode="#current"/>
                        <xsl:choose>
                            <xsl:when test="exists($this-param/@replace-content-with)">
                                <xsl:apply-templates select="tan:evaluate($this-param/@replace-content-with, $this-element)" mode="#current"/>
                            </xsl:when>
                            <xsl:when test="$is-div-with-tei-children = true()">
                                <xsl:apply-templates select="*" mode="#current"/>
                            </xsl:when>
                            <xsl:when
                                test="exists(*) and not(exists((tan:tok, tan:non-tok, tan:a, tan:b, tan:common))) and not(exists(text()[matches(., '\S')]))">
                                <!-- So far, <tok> and <non-tok> are the only elements that have been marked to to be grouped; if others come, then the choices  should be moved to the parameters -->
                                <xsl:variable name="pass-1" as="item()*">
                                    <xsl:for-each select="* | comment()">
                                        <xsl:sort
                                            select="($params/*/tan:element[@name = name(current())]/@priority, $params/*/@priority)[1]"/>
                                        <xsl:variable name="this-child-name" select="name(.)"/>
                                        <xsl:variable name="this-child-param" select="$params/*/tan:element[@name = $this-child-name]"/>
                                        <xsl:variable name="this-child-action" select="($this-child-param/@action, $params/*/@action)[1]"/>
                                        <xsl:if test="not($this-child-action = 'deep-skip')">
                                            <xsl:copy-of select="."/>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:variable>
                                <xsl:for-each-group select="$pass-1" group-by="name()">
                                    <xsl:variable name="group-min"
                                        select="tan:group-min(current-group()[1])"/>
                                    <xsl:choose>
                                        <xsl:when
                                            test="$group-min le count(current-group())">
                                            <xsl:element name="{concat(current-grouping-key(),'s')}">
                                                <xsl:copy-of
                                                    select="tan:get-label(current-group()[1], $is-grouped, true())"/>
                                                <xsl:apply-templates select="current-group()"
                                                    mode="#current">
                                                    <xsl:with-param name="is-grouped" select="true()"/>
                                                </xsl:apply-templates>
                                            </xsl:element>
                                        </xsl:when>
                                        <xsl:when
                                            test="$group-min gt count(current-group())">
                                            <xsl:apply-templates select="current-group()" mode="#current">
                                                <xsl:with-param name="is-grouped" select="false()"/>
                                            </xsl:apply-templates>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:for-each-group>
                                <!-- If there are intentionally placed white-space text children nodes, then we copy them. This may appear in cases where a gloss is placed inside a <non-tok> -->
                                <xsl:copy-of select="text()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="#current"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:apply-templates select="tan:evaluate($this-param/@append, $this-element)" mode="#current"/>
                    </xsl:copy>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$this-action = 'shallow-skip'">
                        <xsl:copy-of select="$pass-1/node()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- therefore it's a shallow-copy (usually the default) -->
                        <xsl:sequence select="$pass-1"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>



    <xsl:function name="tan:true" as="xs:boolean*">
        <!-- Input: a sequence of strings representing truth values -->
        <!-- Output: the same number of booleans; if the string is some approximation of y, yes, 1, or true, then it is true, and false otherwise -->
        <xsl:param name="string" as="xs:string*"/>
        <xsl:for-each select="$string">
            <xsl:choose>
                <xsl:when test="matches(., '^y(es)?|1|t(rue)?$', 'i')">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:when test="matches(., '^n(o)?|0|f(alse)?$', 'i')">
                    <xsl:value-of select="false()"/>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="tan:group-min" as="xs:integer*">
        <!-- Input: any sequence of attributes or elements; an attribute name whose truth value should be checked -->
        <!-- Output: the same number of booleans, indicating whether the attribute or element should be suppressed, grouped, or whatever (dependent upon the name of the attribute), given the parameters of the stylesheet -->
        <xsl:param name="attributes-or-elements" as="item()*"/>
        <xsl:for-each select="$attributes-or-elements">
            <xsl:variable name="node-name" select="name(.)"/>
            <xsl:variable name="node-type" as="xs:string?">
                <xsl:choose>
                    <xsl:when test=". instance of element()">element</xsl:when>
                    <xsl:when test=". instance of attribute()">attribute</xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of
                select="($params/*/*[name() = $node-type and @name = $node-name]/@group-min, $params/*/@group-min, 999999)[1]"
            />
        </xsl:for-each>
    </xsl:function>
    <xsl:function name="tan:evaluate" as="item()*">
        <!-- Input: a string to be evaluated as an XPath; a context node -->
        <!-- Output: the result of the string evaluated as an XPath statement against the context node -->
        <xsl:param name="xpath" as="xs:string?"/>
        <xsl:param name="context-node" as="node()?"/>
        <xsl:if test="string-length($xpath) gt 0">
            <xsl:analyze-string select="$xpath" regex="{$xpath-pattern}">
                <xsl:matching-substring>
                    <xsl:variable name="this-xpath" select="replace(., '[\{\}]', '')"/>
                    <xsl:choose>
                        <xsl:when test="function-available('saxon:evaluate')">
                            <!-- If saxon:evaluate is available, use it -->
                            <xsl:copy-of select="saxon:evaluate($this-xpath, $context-node)" copy-namespaces="no"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- otherwise, only some very common substitutions will be supported, e.g., an attribute value or the first <name> child -->
                            <xsl:choose>
                                <xsl:when test="$this-xpath = 'name($p1)'">
                                    <xsl:value-of select="name($context-node)"/>
                                </xsl:when>
                                <xsl:when test="matches($this-xpath, '^$p1/@')">
                                    <xsl:value-of
                                        select="$context-node/@*[name() = replace(., '^\$@', '')]"/>
                                </xsl:when>
                                <xsl:when test="matches($this-xpath, '^$p1/\w+$')">
                                    <xsl:value-of select="$context-node/*[name() = $this-xpath]"/>
                                </xsl:when>
                                <xsl:when test="matches($this-xpath, '^$p1/\w+\[\d+\]$')">
                                    <xsl:variable name="simple-xpath-analyzed" as="xs:string*">
                                        <xsl:analyze-string select="$this-xpath" regex="\[\d+\]$">
                                            <xsl:matching-substring>
                                                <xsl:value-of select="replace(., '\$p|\D', '')"/>
                                            </xsl:matching-substring>
                                            <xsl:non-matching-substring>
                                                <xsl:value-of select="."/>
                                            </xsl:non-matching-substring>
                                        </xsl:analyze-string>
                                    </xsl:variable>
                                    <xsl:value-of
                                        select="$context-node/*[name() = $simple-xpath-analyzed[1]][$simple-xpath-analyzed[2]]"
                                    />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:if>
    </xsl:function>
    <xsl:function name="tan:get-label" as="element()?">
        <xsl:param name="node" as="item()?"/>
        <xsl:param name="is-grouped" as="xs:boolean"/>
        <xsl:sequence select="tan:get-label($node, $is-grouped, false())"/>
    </xsl:function>
    <xsl:function name="tan:get-label" as="element()?">
        <!-- Input: any attribute or element; a yes/no value indicating whether the group label should be retrieved instead -->
        <!-- Output: a <label> with the value of the label specified by the parameter -->
        <xsl:param name="node" as="item()?"/>
        <xsl:param name="is-grouped" as="xs:boolean"/>
        <xsl:param name="is-group" as="xs:boolean"/>
        <xsl:variable name="node-name" select="name($node)"/>
        <xsl:variable name="node-is-attribute" select="$node instance of attribute()"/>
        <xsl:variable name="node-type" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$node instance of element()">element</xsl:when>
                <xsl:when test="$node-is-attribute">attribute</xsl:when>
                <xsl:when test="$node instance of comment()">comment</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="node-namespace"
            select="
                if ($node-is-attribute = true()) then
                    namespace-uri($node/parent::*)
                else
                    namespace-uri($node)"/>
        <xsl:variable name="this-param"
            select="$params/*/*[name() = $node-type and @name = $node-name]"/>
        <xsl:variable name="this-label" as="xs:string?"
            select="
                if ($is-group = true()) then
                    ($this-param/@group-label, $params/*/@group-label, (concat(($this-param/@label, $params/*/@label)[1], 's')))[1]
                else
                    if ($is-grouped = true()) then
                        ($this-param/@group-item-label, $params/*/@group-item-label, $this-param/@label, $params/*/@label)[1]
                    else
                        ($this-param/@label, $params/*/@label)[1]"
        />
        <xsl:variable name="label-format"
            select="($this-param/@format-label, $params/*/@format-label)[1]"/>
        <xsl:variable name="label-format-constructor"
            select="$params//tan:format-label[@xml:id = $label-format]"/>
        <xsl:variable name="label-value" select="tan:evaluate($this-label, $node)"/>
        <!--<xsl:message select="$is-group, $this-label, $label-value"/>-->
        <xsl:variable name="new-label" select="string-join($label-value, '')"/>
        <!-- format the label -->
        <xsl:if test="string-length($new-label) gt 0 and $node-type = ('element', 'attribute')">
            <xsl:element name="label" namespace="{$node-namespace}">
                <xsl:value-of
                    select="
                        if (exists($label-format-constructor)) then
                            tan:format-string($new-label, $label-format-constructor)
                        else
                            $new-label"
                />
            </xsl:element>
        </xsl:if>
    </xsl:function>

    <xsl:function name="tan:format-string" as="xs:string*">
        <!-- Input: any sequence of strings; and a specially constructed element with child <replace> and <change-case>s -->
        <!-- Output: the same strings, after transformation -->
        <xsl:param name="strings" as="xs:string*"/>
        <xsl:param name="format-element" as="element()"/>
        <xsl:for-each select="$strings">
            <xsl:variable name="this-string" select="."/>
            <xsl:apply-templates select="$format-element/*[1]" mode="format-string">
                <xsl:with-param name="string" select="$this-string"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:function>
    <xsl:template match="*" mode="format-string">
        <xsl:param name="string" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="following-sibling::*">
                <xsl:apply-templates select="following-sibling::*[1]" mode="format-string">
                    <xsl:with-param name="string" select="$string"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$string"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tan:replace" mode="format-string">
        <xsl:param name="string" as="xs:string"/>
        <xsl:variable name="new-string"
            select="replace($string, @pattern, @replacement, (@flags, '')[1])"/>
        <xsl:choose>
            <xsl:when test="following-sibling::*">
                <xsl:apply-templates select="following-sibling::*[1]" mode="format-string">
                    <xsl:with-param name="string" select="$new-string"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$new-string"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tan:change-case" mode="format-string">
        <xsl:param name="string" as="xs:string"/>
        <xsl:variable name="string-analyzed" select="tokenize($string, '\s+')"/>
        <xsl:variable name="to-upper" select="matches(@to, 'upper', 'i')"/>
        <xsl:variable name="to-lower" select="matches(@to, 'lower', 'i')"/>
        <xsl:variable name="words-picked" select="tokenize(@words, '\s+')"/>
        <xsl:variable name="initial-only" select="tan:true(@initial-only)"/>
        <xsl:variable name="new-string" as="xs:string*">
            <xsl:for-each select="$string-analyzed">
                <xsl:variable name="pos" select="position()"/>
                <xsl:choose>
                    <xsl:when
                        test="
                            string($pos) = $words-picked
                            or ($pos = count($string-analyzed) and $words-picked = 'last')
                            or matches($words-picked, '^any|all|\*$', 'i')">
                        <xsl:choose>
                            <xsl:when test="$to-upper = true()">
                                <xsl:value-of
                                    select="
                                        if ($initial-only = true()) then
                                            concat(upper-case(substring(., 1, 1)), substring(., 2))
                                        else
                                            upper-case(.)"
                                />
                            </xsl:when>
                            <xsl:when test="$to-lower = true()">
                                <xsl:value-of
                                    select="
                                        if ($initial-only = true()) then
                                            concat(lower-case(substring(., 1, 1)), substring(., 2))
                                        else
                                            upper-case(.)"
                                />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="following-sibling::*">
                <xsl:apply-templates select="following-sibling::*[1]" mode="format-string">
                    <xsl:with-param name="string" select="string-join($new-string, ' ')"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="string-join($new-string, ' ')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
