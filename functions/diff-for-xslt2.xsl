<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs xd" version="2.0">
    <!-- String difference function for XSLT 2.0 -->    
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
        <xsl:variable name="pass1" select="tan:diff-loop($string1, $string2, $diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment, $stagger-exp-adjustment)"/>
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
    <xsl:function name="tan:diff-loop">
        <xsl:param name="string1" as="xs:string?"/>
        <xsl:param name="string2" as="xs:string?"/>
        <xsl:param name="diminishment-base" as="xs:double"/>
        <xsl:param name="diminishment-exp-adjustment" as="xs:double"/>
        <xsl:param name="stagger-base-adjustment" as="xs:double"/>
        <xsl:param name="stagger-exp-adjustment" as="xs:double"/>
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
                    <xsl:when test="string-length($s1-head) lt 1 or string-length($s2-head) lt 1">
                        <xsl:copy-of select="($s1-head, $s2-head)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="tan:diff-loop($s1-head, $s2-head, $diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment, $stagger-exp-adjustment)"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:copy-of select="$first-diff-norm/tan:common"/>
                <xsl:choose>
                    <xsl:when test="string-length($s1-tail) lt 1 or string-length($s2-tail) lt 1">
                        <xsl:copy-of select="($s1-tail, $s2-tail)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="tan:diff-loop($s1-tail, $s2-tail, $diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment, $stagger-exp-adjustment)"/>
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
        <xsl:param name="loop-count" as="xs:double"/>
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
                    $diminishment-base-norm"
        />
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
        
        <xsl:variable name="new-loop-count" select="$loop-count + 1" as="xs:double"/>
        <xsl:variable name="loop-result"
            select="tan:diff-core($long-string, $short-string, $short-string-length, $new-segment-length, $new-segment-position, $new-diminishment-base, $diminishment-exp-adjustment, $stagger-base-adjustment-norm, $stagger-exp-adjustment, $new-loop-count, $new-line-count)"/>
        <xsl:choose>
            <xsl:when test="($loop-count = 550) or ($segment-length lt 1)">
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
</xsl:stylesheet>
