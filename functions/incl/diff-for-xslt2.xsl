<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs xd" version="2.0">
    <!-- String difference function for XSLT 2.0 -->

    <xsl:param name="loop-tolerance" as="xs:integer" select="550"/>

    <xsl:function name="tan:raw-diff" as="element()">
        <!-- 2-param version of fuller one below -->
        <xsl:param name="string-a" as="xs:string?"/>
        <xsl:param name="string-b" as="xs:string?"/>
        <xsl:copy-of select="tan:raw-diff($string-a, $string-b, true())"/>
    </xsl:function>
    <xsl:function name="tan:raw-diff" as="element()">
        <!-- Input: any two strings; boolean indicating whether results should snap to nearest word -->
        <!-- Output: an element with <a>, <b>, and <common> children showing where strings a and b match and depart -->
        <!-- This function was written after tan:diff, intended to be a cruder and faster way to check two strings against each other, suitable for validation without hanging due to nested recursion objections. -->
        <xsl:param name="string-a" as="xs:string?"/>
        <xsl:param name="string-b" as="xs:string?"/>
        <xsl:param name="snap-to-word" as="xs:boolean"/>
        <xsl:variable name="a-prepped" as="element()">
            <a>
                <xsl:value-of select="$string-a"/>
            </a>
        </xsl:variable>
        <xsl:variable name="b-prepped" as="element()">
            <b>
                <xsl:value-of select="$string-b"/>
            </b>
        </xsl:variable>
        <xsl:variable name="strings-prepped" as="element()+">
            <xsl:for-each select="$a-prepped, $b-prepped">
                <xsl:sort select="string-length(text())"/>
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="strings-diffed" as="element()*"
            select="tan:raw-diff-loop($strings-prepped[1], $strings-prepped[2], true(), true(), 0)"/>
        <xsl:variable name="results-sorted-1" as="element()">
            <raw-diff>
                <xsl:for-each-group select="$strings-diffed" group-starting-with="tan:common">
                    <xsl:copy-of select="current-group()/self::tan:common"/>
                    <xsl:if test="exists(current-group()/self::tan:a)">
                        <a>
                            <xsl:value-of select="string-join(current-group()/self::tan:a, '')"/>
                        </a>
                    </xsl:if>
                    <xsl:if test="exists(current-group()/self::tan:b)">
                        <b>
                            <xsl:value-of select="string-join(current-group()/self::tan:b, '')"/>
                        </b>
                    </xsl:if>
                </xsl:for-each-group>
            </raw-diff>
        </xsl:variable>
        <xsl:variable name="results-sorted-2" as="element()">
            <raw-diff>
                <xsl:copy-of select="tan:group-adjacent-elements($results-sorted-1/*)"/>
            </raw-diff>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$snap-to-word">
                <xsl:variable name="snap1" as="element()">
                    <xsl:apply-templates select="$results-sorted-2" mode="snap-to-word-pass-1"/>
                </xsl:variable>
                <xsl:variable name="snap2" as="element()">
                    <!-- It happens that sometimes matching words get restored in this process, either at the beginning or the end of an <a> or <b>; this step moves those common words back into the common pool -->
                    <snap2>
                        <xsl:for-each-group select="$snap1/*" group-starting-with="tan:common">
                            <xsl:copy-of select="current-group()/self::tan:common"/>
                            <xsl:variable name="text-a"
                                select="string-join(current-group()/(self::tan:a, self::tan:a-or-b), '')"/>
                            <xsl:variable name="text-b"
                                select="string-join(current-group()/(self::tan:b, self::tan:a-or-b), '')"/>
                            <xsl:variable name="a-toks" as="xs:string*">
                                <xsl:analyze-string select="$text-a" regex="\s+">
                                    <xsl:matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:variable>
                            <xsl:variable name="b-toks" as="xs:string*">
                                <xsl:analyze-string select="$text-b" regex="\s+">
                                    <xsl:matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:variable>
                            <xsl:variable name="a-tok-qty" select="count($a-toks)"/>
                            <xsl:variable name="b-tok-qty" select="count($b-toks)"/>
                            <xsl:variable name="non-matches-from-start" as="xs:integer*">
                                <xsl:for-each select="$a-toks">
                                    <xsl:variable name="pos" select="position()"/>
                                    <xsl:if test="not(. = $b-toks[$pos])">
                                        <xsl:value-of select="$pos"/>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:if test="$a-tok-qty lt $b-tok-qty">
                                    <xsl:value-of select="$a-tok-qty + 1"/>
                                </xsl:if>
                            </xsl:variable>
                            <xsl:variable name="b-toks-rev"
                                select="reverse($b-toks[position() ge $non-matches-from-start[1]])"/>
                            <xsl:variable name="non-matches-from-end" as="xs:integer*">
                                <xsl:for-each
                                    select="reverse($a-toks[position() ge $non-matches-from-start[1]])">
                                    <xsl:variable name="pos" select="position()"/>
                                    <xsl:if test="not(. = $b-toks-rev[$pos])">
                                        <xsl:value-of select="$pos"/>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:if test="$a-tok-qty lt $b-tok-qty">
                                    <xsl:value-of select="$a-tok-qty + 1"/>
                                </xsl:if>
                            </xsl:variable>
                            <xsl:variable name="a-analyzed" as="element()*">
                                <xsl:for-each select="$a-toks">
                                    <xsl:variable name="pos" select="position()"/>
                                    <xsl:variable name="rev-pos" select="$a-tok-qty - $pos"/>
                                    <xsl:choose>
                                        <xsl:when test="$pos lt $non-matches-from-start[1]">
                                            <common-head>
                                                <xsl:value-of select="."/>
                                            </common-head>
                                        </xsl:when>
                                        <xsl:when test="$rev-pos + 1 lt $non-matches-from-end[1]">
                                            <common-tail>
                                                <xsl:value-of select="."/>
                                            </common-tail>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <a>
                                                <xsl:value-of select="."/>
                                            </a>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:variable name="b-analyzed" as="element()*">
                                <xsl:for-each
                                    select="$b-toks[position() ge $non-matches-from-start[1] and position() le ($b-tok-qty - $non-matches-from-end[1] + 1)]">
                                    <b>
                                        <xsl:value-of select="."/>
                                    </b>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:for-each-group select="($a-analyzed, $b-analyzed)"
                                group-by="name()">
                                <xsl:sort
                                    select="index-of(('common-head', 'a', 'b', 'common-tail'), current-grouping-key())"/>
                                <xsl:variable name="element-name"
                                    select="replace(current-grouping-key(), '-.+', '')"/>
                                <xsl:element name="{$element-name}">
                                    <xsl:value-of select="string-join(current-group(), '')"/>
                                </xsl:element>
                            </xsl:for-each-group>
                        </xsl:for-each-group>
                    </snap2>
                </xsl:variable>
                <raw-diff>
                    <!-- diagnostics, results -->
                    <!--<xsl:copy-of select="$strings-prepped"/>-->
                    <!--<xsl:copy-of select="$strings-diffed"/>-->
                    <!--<xsl:copy-of select="$results-sorted-1"/>-->
                    <!--<xsl:copy-of select="$results-sorted-2"/>-->
                    <!--<xsl:copy-of select="$snap1"/>-->
                    <!--<xsl:copy-of select="$snap2"/>-->
                    <xsl:copy-of select="tan:group-adjacent-elements($snap2/*)"/>
                </raw-diff>
            </xsl:when>
            <xsl:otherwise>
                <!--<test><xsl:copy-of select="$strings-diffed"/></test>-->
                <!--<xsl:sequence select="$results-sorted-1"/>-->
                <xsl:sequence select="$results-sorted-2"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:group-adjacent-elements" as="element()*">
        <!-- Input: any sequence of elements -->
        <!-- Output: the same elements, but adjacent elements of the same name grouped together -->
        <xsl:param name="elements" as="element()*"/>
        <xsl:for-each-group select="$elements" group-adjacent="name()">
            <xsl:element name="{current-grouping-key()}">
                <xsl:copy-of select="current-group()/@*"/>
                <xsl:copy-of select="current-group()/node()"/>
            </xsl:element>
        </xsl:for-each-group>
    </xsl:function>
    <xsl:template match="*" mode="snap-to-word-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:common" mode="snap-to-word-pass-1">
        <xsl:variable name="regex-1"
            select="
                if (exists(preceding-sibling::*)) then
                    '^\S+'
                else
                    ()"/>
        <xsl:variable name="regex-2"
            select="
                if (exists(following-sibling::*)) then
                    '\S+$'
                else
                    ()"/>
        <xsl:variable name="content-analyzed" as="element()">
            <content>
                <xsl:choose>
                    <xsl:when test="exists($regex-1) or exists($regex-2)">
                        <xsl:analyze-string select="text()"
                            regex="{string-join(($regex-1, $regex-2),'|')}">
                            <xsl:matching-substring>
                                <a-or-b>
                                    <xsl:value-of select="."/>
                                </a-or-b>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <common>
                                    <xsl:value-of select="."/>
                                </common>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                    <xsl:otherwise>
                        <common>
                            <xsl:value-of select="text()"/>
                        </common>
                    </xsl:otherwise>
                </xsl:choose>
            </content>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="matches($content-analyzed/tan:common, '\S')">
                <xsl:copy-of select="$content-analyzed/*"/>
            </xsl:when>
            <xsl:otherwise>
                <a-or-b>
                    <xsl:value-of select="."/>
                </a-or-b>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--<xsl:param name="vertical-stops"
        select="
            ((for $i in reverse(1 to 20)
            return
                $i * 0.05), 0.025)"
        as="xs:double*"/>-->
    <!--<xsl:param name="vertical-stops"
        select="(1.0, 0.95, 0.9, 0.8, 0.65, 0.5, 0.35, 0.2, 0.1, 0.05, 0.025, 0.01)" as="xs:double*"/>-->
    <xsl:param name="vertical-stops"
        select="
            for $i in (0 to 14)
            return
                math:pow(2, (-0.5 * $i))"/>
    <xsl:function name="tan:raw-diff-loop">
        <xsl:param name="short-string" as="element()?"/>
        <xsl:param name="long-string" as="element()?"/>
        <xsl:param name="start-at-beginning" as="xs:boolean"/>
        <xsl:param name="check-vertically-before-horizontally" as="xs:boolean"/>
        <xsl:param name="loop-counter" as="xs:integer"/>
        <!-- If diagnostics are needed, set the following variable to something that will give messages at the right times -->
        <xsl:variable name="diagnostic-flag" as="xs:boolean" select="$loop-counter = -1"/>
        <xsl:variable name="short-size" select="string-length($short-string)"/>
        <xsl:if test="$diagnostic-flag">
            <xsl:message>start at beginning <xsl:value-of select="$start-at-beginning"/>; check v
                before h <xsl:value-of select="$check-vertically-before-horizontally"
                /></xsl:message>
            <xsl:message>short string <xsl:value-of select="substring($short-string, 1, 10)"
                />...</xsl:message>
            <xsl:message>long string <xsl:value-of select="substring($long-string, 1, 10)"
                />...</xsl:message>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$loop-counter ge $loop-tolerance">
                <xsl:if test="$diagnostic-flag">
                    <xsl:message>Can't go beyond loop <xsl:value-of select="$loop-tolerance"
                        /></xsl:message>
                </xsl:if>
                <xsl:copy-of select="$short-string, $long-string"/>
            </xsl:when>
            <xsl:when test="$short-size lt 1 or string-length($long-string) lt 1">
                <xsl:copy-of select="$long-string"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="horizontal-search-on-long" as="element()*">
                    <xsl:for-each select="$vertical-stops">
                        <xsl:variable name="vertical-pos" select="position()"/>
                        <xsl:variable name="percent-of-short-to-check"
                            select="min((max((., 0.0000001)), 1.0))"/>
                        <xsl:variable name="number-of-horizontal-passes"
                            select="
                                if ($check-vertically-before-horizontally) then
                                    1
                                else
                                    xs:integer((1 - $percent-of-short-to-check) * 50) + 1"/>
                        <xsl:variable name="length-of-short-substring"
                            select="ceiling($short-size * $percent-of-short-to-check)"/>
                        <xsl:variable name="length-of-play-in-short"
                            select="$short-size - $length-of-short-substring"/>
                        <xsl:variable name="horizontal-stagger"
                            select="$length-of-play-in-short div max(($number-of-horizontal-passes - 1, 1))"/>
                        <xsl:if test="$diagnostic-flag">
                            <xsl:message select="$horizontal-stagger"/>
                        </xsl:if>
                        <xsl:variable name="horizontal-pass-sequence"
                            select="
                                if ($start-at-beginning) then
                                    (1 to $number-of-horizontal-passes)
                                else
                                    reverse(1 to $number-of-horizontal-passes)"/>
                        <xsl:for-each select="$horizontal-pass-sequence">
                            <xsl:variable name="horizontal-pos" select="."/>
                            <xsl:variable name="starting-pos-of-short-substring"
                                select="ceiling(($horizontal-pos - 1) * $horizontal-stagger) + 1"/>
                            <xsl:variable name="picked-search-text"
                                select="
                                    concat(if ($check-vertically-before-horizontally and $start-at-beginning) then
                                        '^'
                                    else
                                        (), substring($short-string, $starting-pos-of-short-substring, $length-of-short-substring), if ($check-vertically-before-horizontally and not($start-at-beginning)) then
                                        '$'
                                    else
                                        ())"/>
                            <xsl:if test="$diagnostic-flag">
                                <xsl:message select="$picked-search-text"/>
                            </xsl:if>
                            <xsl:variable name="this-search" as="element()*">
                                <xsl:if test="string-length($picked-search-text) gt 0">
                                    <xsl:analyze-string select="$long-string"
                                        regex="{tan:escape($picked-search-text)}">
                                        <xsl:matching-substring>
                                            <common loop="{$loop-counter}">
                                                <xsl:value-of select="."/>
                                            </common>
                                        </xsl:matching-substring>
                                        <xsl:non-matching-substring>
                                            <xsl:element name="{name($long-string)}">
                                                <xsl:attribute name="loop" select="$loop-counter"/>
                                                <xsl:value-of select="."/>
                                            </xsl:element>
                                        </xsl:non-matching-substring>
                                    </xsl:analyze-string>
                                </xsl:if>
                            </xsl:variable>
                            <xsl:if test="exists($this-search/self::tan:common)">
                                <result short-search-start="{$starting-pos-of-short-substring}"
                                    short-search-length="{$length-of-short-substring}">
                                    <xsl:copy-of select="$this-search"/>
                                </result>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="first-result"
                    select="($horizontal-search-on-long/self::tan:result)[1]"/>
                <xsl:choose>
                    <xsl:when test="not(exists($first-result))">
                        <xsl:choose>
                            <xsl:when test="not($check-vertically-before-horizontally = true())">
                                <xsl:copy-of select="$long-string, $short-string"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of
                                    select="tan:raw-diff-loop($short-string, $long-string, $start-at-beginning, false(), $loop-counter + 1)"
                                />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="short-search-start"
                            select="xs:integer($first-result/@short-search-start)"/>
                        <xsl:variable name="short-search-length"
                            select="xs:integer($first-result/@short-search-length)"/>
                        <xsl:variable name="long-head"
                            select="$first-result/tan:common[1]/preceding-sibling::*"/>
                        <xsl:variable name="long-tail-prelim"
                            select="$first-result/tan:common[1]/following-sibling::*"/>
                        <!-- The long tail should include matches past the first -->
                        <xsl:variable name="long-tail" as="element()?">
                            <xsl:if test="exists($long-tail-prelim)">
                                <xsl:element name="{name($long-tail-prelim[1])}">
                                    <xsl:attribute name="loop" select="$loop-counter"/>
                                    <xsl:value-of select="string-join($long-tail-prelim, '')"/>
                                </xsl:element>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="short-head" as="element()">
                            <xsl:element name="{name($short-string)}">
                                <xsl:attribute name="loop" select="$loop-counter"/>
                                <xsl:value-of
                                    select="substring($short-string, 1, $short-search-start - 1)"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:variable name="short-tail" as="element()">
                            <xsl:element name="{name($short-string)}">
                                <xsl:attribute name="loop" select="$loop-counter"/>
                                <xsl:value-of
                                    select="substring($short-string, $short-search-start + $short-search-length)"
                                />
                            </xsl:element>
                        </xsl:variable>
                        <xsl:variable name="head-input" as="element()*">
                            <xsl:for-each select="$long-head, $short-head">
                                <xsl:sort select="string-length(.)"/>
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:variable name="tail-input" as="element()*">
                            <xsl:for-each select="$long-tail, $short-tail">
                                <xsl:sort select="string-length(.)"/>
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:variable>
                        <!-- need to loop again on head fragments -->
                        <xsl:copy-of
                            select="
                                tan:raw-diff-loop($head-input[1], $head-input[2], false(), true(), $loop-counter + 1)"/>
                        <!--<xsl:copy-of select="$head-input"/>-->
                        <xsl:copy-of select="$first-result/tan:common[1]"/>

                        <!-- need to loop again on tail fragments -->
                        <xsl:if test="$diagnostic-flag">
                            <xsl:message select="$tail-input[1], $tail-input[2]"/>
                        </xsl:if>
                        <xsl:copy-of
                            select="
                                tan:raw-diff-loop($tail-input[1], $tail-input[2], true(), true(), $loop-counter + 1)"
                        />
                    </xsl:otherwise>
                </xsl:choose>
                <!--<xsl:copy-of select="$horizontal-search-on-long"/>-->


            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xd:doc scope="component">
        <xd:desc>Returns &lt;diff>, with attributes indicating parameters used, and children
            &lt;s1>, &lt;s2>, and &lt;common>, indicating where the first and second strings diverge
            and match.</xd:desc>
        <xd:param name="string1">String to be compared.</xd:param>
        <xd:param name="string2">String to be compared.</xd:param>
    </xd:doc>
    <xsl:function name="tan:diff" as="element()">
        <!-- two-parameter version of the full version below. The stagger and diminishment
        factors are designed to get small as the length of the shortest string gets larger.
        -->
        <xsl:param name="string1" as="xs:string?"/>
        <xsl:param name="string2" as="xs:string?"/>
        <xsl:variable name="len1" select="string-length($string1)"/>
        <xsl:variable name="len2" select="string-length($string2)"/>
        <xsl:variable name="shortest-len" select="min(($len1, $len2))"/>
        <!--<xsl:variable name="factor" select="1 div math:sqrt(math:log10($shortest-len + 11))"/>-->
        <!--<xsl:variable name="factor" select="math:pow((1 div math:log10($shortest-len + 11)), 3)"/>-->
        <!--<xsl:variable name="factor" select="1 div (($shortest-len div 2) + 1)"/>-->
        <xsl:copy-of select="tan:diff($string1, $string2, .95, 0, 1, 2)"/>
    </xsl:function>
    <xsl:function name="tan:diff" as="element()">
        <!-- Input: any two strings.
        Output: The differences between the two strings in the form of:
            <diff>
            <s1>[text unique to string 1]</s1>
            <s2>[text unique to string 2]</s2>
            <common>[text shared by both strings]</common>
        </diff>
        The algorithm is designed for XSLT 2, in which too many nested loops prove fatal, and with
        the assumption that the user could settle for a difference that finds a long common substring, 
        and not perhaps the longest common substring.
        -->
        <xsl:param name="string1" as="xs:string?"/>
        <xsl:param name="string2" as="xs:string?"/>
        <xsl:param name="diminishment-base" as="xs:double"/>
        <xsl:param name="diminishment-exp-adjustment" as="xs:double"/>
        <xsl:param name="stagger-base-adjustment" as="xs:double"/>
        <xsl:param name="stagger-exp-adjustment" as="xs:double"/>
        <xsl:variable name="short-length" select="string-length($string2)"/>
        <xsl:variable name="pass1"
            select="tan:diff-loop($string1, $string2, $diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment, $stagger-exp-adjustment, 0)"/>
        <diff diminishment-base="{$diminishment-base}"
            diminishment-exp-adjustment="{$diminishment-exp-adjustment}"
            stagger-base-adjustment="{$stagger-base-adjustment}"
            stagger-exp-adjustment="{$stagger-exp-adjustment}">
            <xsl:for-each-group select="$pass1" group-adjacent="name(.)">
                <xsl:element name="{current-grouping-key()}">
                    <xsl:value-of select="current-group()/text()"/>
                </xsl:element>
            </xsl:for-each-group>
        </diff>
    </xsl:function>
    <xsl:function name="tan:diff-loop" as="node()*">
        <xsl:param name="string1" as="xs:string?"/>
        <xsl:param name="string2" as="xs:string?"/>
        <xsl:param name="diminishment-base" as="xs:double"/>
        <xsl:param name="diminishment-exp-adjustment" as="xs:double"/>
        <xsl:param name="stagger-base-adjustment" as="xs:double"/>
        <xsl:param name="stagger-exp-adjustment" as="xs:double"/>
        <xsl:param name="loop-count" as="xs:integer"/>
        <xsl:variable name="len1" select="string-length($string1)"/>
        <xsl:variable name="len2" select="string-length($string2)"/>
        <xsl:variable name="string1-is-long" select="$len1 ge $len2" as="xs:boolean"/>
        <xsl:variable name="aaa"
            select="
                if ($string1-is-long = true()) then
                    $string1
                else
                    $string2"/>
        <xsl:variable name="bb"
            select="
                if ($string1-is-long = true()) then
                    $string2
                else
                    $string1"/>
        <xsl:variable name="len-bb" select="min(($len1, $len2))"/>
        <xsl:variable name="first-diff"
            select="tan:diff-core($aaa, $bb, $len-bb, $len-bb, 1, $diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment, $stagger-exp-adjustment, 1, 1)"/>
        <!--<xsl:variable name="first-diff"
            select="tan:diff-core-draft($aaa, $bb, $len-bb, $len-bb, 1, $diminishment-factor, $stagger-factor)"/>-->
        <xsl:variable name="first-diff-norm" as="element()*">
            <diff>
                <xsl:apply-templates select="$first-diff" mode="diff-rectify">
                    <xsl:with-param name="string1-is-long" select="$string1-is-long" tunnel="yes"/>
                </xsl:apply-templates>
            </diff>
        </xsl:variable>
        <xsl:variable name="s1-head" select="$first-diff-norm/tan:common/preceding-sibling::tan:s1"/>
        <xsl:variable name="s2-head" select="$first-diff-norm/tan:common/preceding-sibling::tan:s2"/>
        <xsl:variable name="s1-tail" select="$first-diff-norm/tan:common/following-sibling::tan:s1"/>
        <xsl:variable name="s2-tail" select="$first-diff-norm/tan:common/following-sibling::tan:s2"/>
        <xsl:choose>
            <xsl:when test="not(exists($first-diff-norm/tan:common))">
                <xsl:copy-of select="$first-diff-norm/*"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when
                        test="($loop-count = $loop-tolerance) or string-length($s1-head) lt 1 or string-length($s2-head) lt 1">
                        <xsl:copy-of select="($s1-head, $s2-head)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of
                            select="tan:diff-loop($s1-head, $s2-head, $diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment, $stagger-exp-adjustment, $loop-count + 1)"
                        />
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:copy-of select="$first-diff-norm/tan:common"/>
                <xsl:choose>
                    <xsl:when test="string-length($s1-tail) lt 1 or string-length($s2-tail) lt 1">
                        <xsl:copy-of select="($s1-tail, $s2-tail)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of
                            select="tan:diff-loop($s1-tail, $s2-tail, $diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment, $stagger-exp-adjustment, $loop-count + 1)"
                        />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="*" mode="diff-rectify">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="diff-rectify"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:aaa" mode="diff-rectify">
        <xsl:param name="string1-is-long" as="xs:boolean" tunnel="yes"/>
        <xsl:element name="{if ($string1-is-long = true()) then 's1' else 's2'}">
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tan:bb" mode="diff-rectify">
        <xsl:param name="string1-is-long" as="xs:boolean" tunnel="yes"/>
        <xsl:element name="{if ($string1-is-long = false()) then 's1' else 's2'}">
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>


    <xsl:function name="tan:diff-core" as="element()*">
        <xsl:param name="long-string" as="xs:string?"/>
        <xsl:param name="short-string" as="xs:string?"/>
        <xsl:param name="short-string-length" as="xs:double"/>
        <xsl:param name="segment-length" as="xs:double"/>
        <xsl:param name="segment-position" as="xs:double"/>
        <!-- Diminishment base, which must always be a double between 0 and 1, indicates how much smaller a segment should be
        when starting a new line. By default, the segments get rapidly smaller, because the diminishment is, by
        default, squared for the beginning of a new line. The diminishment can be accelerated (decelerated) by
        increasing (decreasing) the diminishment exponent adjustment, which is normally greater than -1 -->
        <xsl:param name="diminishment-base" as="xs:double"/>
        <xsl:param name="diminishment-exp-adjustment" as="xs:double"/>
        <!-- By default, stagger is calculated as 2 ^ ($line-count - 3), which means that at the second line,
            segments will overlap by half lengths, at the third line, segments will be adjacent to each other,
            and at the fourth line, segments will be as distant from each other as they are long. Any increase
            (decrease, but cannot be -1 or less) to the base (2) will exaggerate (mitigate) the effect. Every 
            increase (decrease) of one to the exponent (3) will set back (move ahead) the staggering sequence,
            e.g., adjacent segments will happen at the fourth (second) line. -->
        <xsl:param name="stagger-base-adjustment" as="xs:double"/>
        <xsl:param name="stagger-exp-adjustment" as="xs:double"/>
        <xsl:param name="loop-count" as="xs:integer"/>
        <xsl:param name="line-count" as="xs:double"/>


        <xsl:variable name="new-segment"
            select="tan:escape(substring($short-string, $segment-position, $segment-length))"/>
        <xsl:variable name="omitted-head"
            select="substring($short-string, 1, $segment-position - 1)"/>
        <xsl:variable name="omitted-tail"
            select="substring($short-string, $segment-position + $segment-length)"/>
        <xsl:variable name="match-pass1" as="element()">
            <match>
                <xsl:analyze-string select="$long-string"
                    regex="{if (string-length($new-segment) lt 1) then 'out of range' else $new-segment}">
                    <xsl:matching-substring>
                        <common>
                            <xsl:value-of select="."/>
                        </common>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <aaa>
                            <xsl:value-of select="."/>
                        </aaa>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </match>
        </xsl:variable>
        <xsl:variable name="match" as="element()">
            <xsl:variable name="this-tail" select="$match-pass1/tan:common[1]/following-sibling::*"/>
            <match>
                <xsl:copy-of select="$match-pass1/tan:common[1]/preceding-sibling::tan:aaa"/>
                <xsl:copy-of select="$match-pass1/tan:common[1]"/>
                <xsl:if test="exists($this-tail)">
                    <aaa>
                        <xsl:value-of select="$this-tail/text()"/>
                    </aaa>
                </xsl:if>
            </match>
        </xsl:variable>



        <xsl:variable name="diminishment-base-norm"
            select="max((min(($diminishment-base, .9999999)), .0000001))"/>
        <xsl:variable name="stagger-base-adjustment-norm"
            select="max(($stagger-base-adjustment, -0.9999999))"/>
        <xsl:variable name="stagger-factor" as="xs:double"
            select="math:pow(2 + $stagger-base-adjustment-norm, ($line-count - (3 + $stagger-exp-adjustment)))"/>
        <xsl:variable name="next-segment-position"
            select="$segment-position + ceiling($segment-length * $stagger-factor)"/>
        <xsl:variable name="is-end-of-line"
            select="
                ($segment-length + $next-segment-position gt $short-string-length)"/>
        <xsl:variable name="new-line-count"
            select="
                if ($is-end-of-line = true()) then
                    $line-count + 1
                else
                    $line-count"/>
        <xsl:variable name="new-diminishment-base" as="xs:double"
            select="
                if ($is-end-of-line = true()) then
                    math:pow($diminishment-base-norm, (2 + $diminishment-exp-adjustment))
                else
                    $diminishment-base-norm"/>
        <xsl:variable name="new-segment-length" as="xs:double"
            select="
                if ($is-end-of-line = true()) then
                    floor($segment-length * $new-diminishment-base)
                else
                    $segment-length"/>
        <xsl:variable name="new-segment-position" as="xs:double"
            select="
                if ($is-end-of-line = true()) then
                    1
                else
                    $next-segment-position"/>

        <xsl:variable name="new-loop-count" select="$loop-count + 1" as="xs:integer"/>
        <xsl:variable name="loop-result"
            select="tan:diff-core($long-string, $short-string, $short-string-length, $new-segment-length, $new-segment-position, $new-diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment-norm, $stagger-exp-adjustment, $new-loop-count, $new-line-count)"/>
        <xsl:choose>
            <xsl:when test="($loop-count = $loop-tolerance) or ($segment-length lt 1)">
                <seg pos="{$segment-position}" len="{$segment-length}">
                    <xsl:value-of select="$new-segment"/>
                </seg>
                <aaa>
                    <xsl:value-of select="$long-string"/>
                </aaa>
                <bb>
                    <xsl:value-of select="$short-string"/>
                </bb>
            </xsl:when>
            <xsl:when test="exists($match/tan:common)">
                <xsl:copy-of select="$match/tan:common/preceding-sibling::tan:aaa"/>
                <xsl:if test="string-length($omitted-head) gt 0">
                    <bb>
                        <xsl:value-of select="$omitted-head"/>
                    </bb>
                </xsl:if>
                <xsl:copy-of select="$match/tan:common"/>
                <xsl:copy-of select="$match/tan:common/following-sibling::tan:aaa"/>
                <xsl:if test="string-length($omitted-tail) gt 0">
                    <bb>
                        <xsl:value-of select="$omitted-tail"/>
                    </bb>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$loop-result"/>
            </xsl:otherwise>
            <!--<xsl:otherwise>
                <!-\- This <otherwise> retained for troubleshooting -\->
                <pass n="{$loop-count}" len="{$segment-length}" pos="{$segment-position}"
                    dim="{$diminishment-base}" stag="{$stagger-factor}"/>
                <xsl:choose>
                    <xsl:when test="$is-end-of-line = true()">
                        <start-again line="{$new-line-count}">
                            <xsl:copy-of select="$loop-result"/>
                        </start-again>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$loop-result"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>-->
        </xsl:choose>
    </xsl:function>


    <xsl:function name="tan:diff-core-draft" as="element()*">
        <xsl:param name="long-string" as="xs:string?"/>
        <xsl:param name="short-string" as="xs:string?"/>
        <xsl:param name="short-string-length" as="xs:double?"/>
        <xsl:param name="length-to-try" as="xs:double?"/>
        <xsl:param name="position-to-try" as="xs:double?"/>
        <xsl:param name="diminishment-factor" as="xs:double"/>
        <xsl:param name="stagger-factor" as="xs:double"/>
        <xsl:variable name="new-segment"
            select="tan:escape(substring($short-string, $position-to-try, $length-to-try))"/>
        <xsl:variable name="omitted-head" select="substring($short-string, 1, $position-to-try - 1)"/>
        <xsl:variable name="omitted-tail"
            select="substring($short-string, $position-to-try + $length-to-try)"/>
        <xsl:variable name="match-pass1" as="element()">
            <match>
                <xsl:analyze-string select="$long-string" regex="{$new-segment}">
                    <xsl:matching-substring>
                        <common>
                            <xsl:value-of select="."/>
                        </common>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <aaa>
                            <xsl:value-of select="."/>
                        </aaa>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </match>
        </xsl:variable>
        <xsl:variable name="match" as="element()">
            <xsl:variable name="this-tail" select="$match-pass1/tan:common[1]/following-sibling::*"/>
            <match>
                <xsl:copy-of select="$match-pass1/tan:common[1]/preceding-sibling::tan:aaa"/>
                <xsl:copy-of select="$match-pass1/tan:common[1]"/>
                <xsl:if test="exists($this-tail)">
                    <aaa>
                        <xsl:value-of select="$this-tail/text()"/>
                    </aaa>
                </xsl:if>
            </match>
        </xsl:variable>
        <xsl:variable name="is-end-of-line"
            select="$position-to-try + $length-to-try gt $short-string-length"/>
        <xsl:variable name="new-position"
            select="
                if ($is-end-of-line = true()) then
                    1
                else
                    $position-to-try + ceiling($length-to-try * $stagger-factor)"/>
        <xsl:variable name="new-length"
            select="
                if ($is-end-of-line = true()) then
                    floor($length-to-try * $diminishment-factor)
                else
                    $length-to-try"/>
        <xsl:choose>
            <xsl:when test="$new-length = 0">
                <aaa>
                    <xsl:value-of select="$long-string"/>
                </aaa>
                <bb>
                    <xsl:value-of select="$short-string"/>
                </bb>
            </xsl:when>
            <xsl:when test="exists($match/tan:common)">
                <xsl:copy-of select="$match/tan:common/preceding-sibling::tan:aaa"/>
                <xsl:if test="string-length($omitted-head) gt 0">
                    <bb>
                        <xsl:value-of select="$omitted-head"/>
                    </bb>
                </xsl:if>
                <xsl:copy-of select="$match/tan:common"/>
                <xsl:copy-of select="$match/tan:common/following-sibling::tan:aaa"/>
                <xsl:if test="string-length($omitted-tail) gt 0">
                    <bb>
                        <xsl:value-of select="$omitted-tail"/>
                    </bb>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of
                    select="tan:diff-core-draft($long-string, $short-string, $short-string-length, $new-length, $new-position, $diminishment-factor, $stagger-factor)"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!--<xsl:function name="tan:test-loop" as="element()">
        <xsl:param name="outer-loop-limit" as="xs:integer"/>
        <xsl:param name="inner-loop-limit" as="xs:integer"/>
        <loop><xsl:copy-of select="tan:outer-loop($outer-loop-limit, $inner-loop-limit, 0)"/></loop>
    </xsl:function>
    <xsl:function name="tan:outer-loop">
        <xsl:param name="outer-loop-limit"/>
        <xsl:param name="inner-loop-limit"/>
        <xsl:param name="counter"/>
        <xsl:choose>
            <xsl:when test="$counter gt $outer-loop-limit"/>
            <xsl:otherwise>
                <outer><xsl:value-of select="$counter"/>
                    <xsl:copy-of select="tan:inner-loop($inner-loop-limit, 0)"/>
                </outer>
                <xsl:copy-of
                    select="tan:outer-loop($outer-loop-limit, $inner-loop-limit, $counter + 1)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="tan:inner-loop">
        <xsl:param name="inner-loop-limit"/>
        <xsl:param name="counter"/>
        <xsl:choose>
            <xsl:when test="$counter gt $inner-loop-limit"/>
            <xsl:otherwise>
                <inner><xsl:value-of select="$counter"/></inner>
                <xsl:copy-of select="tan:inner-loop($inner-loop-limit, $counter + 1)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>-->

</xsl:stylesheet>
