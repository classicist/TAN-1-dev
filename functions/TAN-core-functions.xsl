<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Updated </xd:b>Aug 31, 2015</xd:p>
            <xd:p>Functions and variables for core TAN files (i.e., applicable to TAN file types of
                more than one class). Used by Schematron validation, but suitable for general use in
                other contexts.</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:param name="separator-type-and-n" select="'.'" as="xs:string"/>
    <xsl:param name="separator-type-and-n-regex" select="'\.'" as="xs:string"/>
    <xsl:param name="separator-hierarchy" select="':'" as="xs:string"/>
    <xsl:param name="separator-hierarchy-regex" select="':'" as="xs:string"/>

    <xsl:variable name="head" select="/*/tan:head"/>
    <xsl:variable name="body" select="/*/tan:body | /*/*/tei:body"/>
    <xsl:variable name="doc-id" select="/*/@id"/>
    <xsl:variable name="doc-uri" select="base-uri(.)"/>
    <xsl:variable name="doc-parent-directory" select="replace($doc-uri, '[^/]+$', '')"/>
    <xsl:variable name="doc-ver-dates"
        select="distinct-values(//(@when | @ed-when | @when-accessed))"/>
    <xsl:variable name="doc-ver-nos"
        select="
            for $i in $doc-ver-dates
            return
                tan:dateTime-to-decimal($i)"/>
    <xsl:variable name="doc-ver" select="$doc-ver-dates[index-of($doc-ver-nos,max($doc-ver-nos))[1]]"/>
    <xsl:variable name="all-iris" select="//tan:IRI"/>
    <xsl:variable name="tan-iri-namespace"
        select="substring-before(substring-after($doc-id, 'tag:'), ':')"/>

    <xsl:variable name="class-1-root-names" select="
            ('TAN-T',
            'TEI')"/>
    <xsl:variable name="class-2-root-names"
        select="
            ('TAN-A-div',
            'TAN-A-tok',
            'TAN-LM')"/>
    <xsl:variable name="class-3-root-names"
        select="
            ('TAN-R-tok',
            'TAN-R-mor')"/>
    <xsl:variable name="all-root-names"
        select="
            $class-1-root-names,
            $class-2-root-names,
            $class-3-root-names"/>
    <xsl:variable name="relationship-keywords-for-tan-versions"
        select="
            ('new version',
            'old version')"/>
    <xsl:variable name="relationship-keywords-for-tan-editions"
        select="
            ('parent edition',
            'child edition',
            'sibling edition',
            'ancestor edition',
            'descendant edition',
            'cousin edition')"/>
    <xsl:variable name="relationship-keywords-for-class-1-editions"
        select="
            ('alternatively divided edition',
            'alternatively normalized edition')"/>
    <xsl:variable name="relationship-keywords-for-tan-files"
        select="
            ($relationship-keywords-for-tan-versions,
            $relationship-keywords-for-tan-editions,
            $relationship-keywords-for-class-1-editions,
            'dependent')"/>
    <xsl:variable name="relationship-keywords-all"
        select="
            $relationship-keywords-for-tan-files,
            'auxiliary'"/>

    <xsl:variable name="elements-that-must-always-refer-to-tan-files"
        select="
            ('recommended-tokenization',
            'tokenization',
            'morphology')"/>

    <!-- variables related to tokenization -->
    <!-- Keywords reserved for officially supplied TAN-R-tok patterns -->
    <xsl:variable name="tokenization-which-reserved"
        select="
            'general-1',
            'general-words-only-1',
            'precise-1'"/>
    <!-- Reserved URLs for officially supplied TAN-R-tok patterns -->
    <xsl:variable name="tokenization-which-reserved-url"
        select="
            ('../TAN-R-tok/general-1.xml',
            '../TAN-R-tok/general-words-only-1.xml',
            '../TAN-R-tok/precise-1.xml')"/>
    <xsl:variable name="tokenizations-core"
        select="
            for $i in $tokenization-which-reserved-url
            return
                doc($i)"/>
    <!-- Error messages for failures to name or access tokenization patterns -->
    <xsl:variable name="tokenization-errors"
        select="
        'no location points to an available document',
        'no @which',
        'no location in the recommended-tokenization element points to an available document',
        '@which is neither in the source nor is it a reserved keyword',
        'core TAN-R-tok invoked, but no document available',
        'source uses language unsupported by the tokenizations chosen'
        "/>
    <!-- Are officially supplied TAN-R-tok patterns available -->
    <xsl:variable name="tokenization-which-reserved-doc-available"
        select="
            for $i in $tokenization-which-reserved-url
            return
                if (doc-available($i)) then
                    $i
                else
                    $tokenization-errors[5]"/>

    <!-- If one wishes to see if the an entire string matches the following patterns defined by these 
        variables, they must appear between the regular expression anchors ^ and $. -->
    <xsl:variable name="roman-numeral-pattern"
        select="'m{0,4}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})'"/>
    <xsl:variable name="letter-numeral-pattern"
        select="'a+|b+|c+|d+|e+|f+|g+|h+|i+|j+|k+|l+|m+|n+|o+|p+|q+|r+|s+|t+|u+|v+|w+|x+|y+|z+'"/>

    <!-- CONTEXT INDEPENDENT FUNCTIONS -->
    <xsl:function name="tan:dec-to-hex" as="xs:string">
        <!-- Change any integer into a hexadecimal string
            Input: xs:integer 
         Output: hexadecimal equivalent as a string 
         E.g., 31 - > '1F'
      -->
        <xsl:param name="in" as="xs:integer"/>
        <xsl:sequence
            select="
                if ($in eq 0)
                then
                    '0'
                else
                    concat(if ($in gt 16)
                    then
                        tan:dec-to-hex($in idiv 16)
                    else
                        '',
                    substring('0123456789ABCDEF',
                    ($in mod 16) + 1, 1))"
        />
    </xsl:function>

    <xsl:function name="tan:hex-to-dec" as="xs:integer?">
        <!-- Change any hexadecimal string into an integer
         E.g., '1F' - > 31
      -->
        <xsl:param name="str" as="xs:string?"/>
        <xsl:variable name="len" select="string-length($str)"/>
        <xsl:value-of
            select="
                if ($len lt 1)
                then
                    0
                else
                    tan:hex-to-dec(substring($str, 1, $len - 1)) * 16 + string-length(substring-before('0123456789ABCDEF', substring($str, $len)))"
        />
    </xsl:function>

    <xsl:function name="tan:rom-to-int" as="xs:integer?">
        <!-- Change any roman numeral less than 5000 into an integer
         E.g., 'xliv' - > 44
      -->
        <xsl:param name="arg" as="xs:string"/>
        <xsl:variable name="arg-lower" select="lower-case($arg)"/>
        <xsl:variable name="rom-cp"
            select="
                (109,
                100,
                99,
                108,
                120,
                118,
                105)"
            as="xs:integer+"/>
        <xsl:variable name="rom-cp-vals"
            select="
                (1000,
                500,
                100,
                50,
                10,
                5,
                1)"
            as="xs:integer+"/>
        <xsl:choose>
            <xsl:when test="matches($arg-lower, concat('^', $roman-numeral-pattern, '$'))">
                <xsl:variable name="arg-seq" select="string-to-codepoints($arg-lower)"/>
                <xsl:variable name="arg-val-seq"
                    select="
                        for $i in $arg-seq
                        return
                            $rom-cp-vals[index-of($rom-cp, $i)]"/>
                <xsl:variable name="arg-val-mod"
                    select="
                        (for $i in (1 to count($arg-val-seq) - 1)
                        return
                            if ($arg-val-seq[$i] lt $arg-val-seq[$i + 1]) then
                                -1
                            else
                                1),
                        1"/>
                <xsl:value-of
                    select="
                        sum(for $i in (1 to count($arg-val-seq))
                        return
                            $arg-val-seq[$i] * $arg-val-mod[$i])"
                />
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:aaa-to-int" as="xs:integer?">
        <!-- Change any numerical sequence in the form of a, b, c, ... z, aa, bb, ..., aaa, bbb, .... into an integer
         E.g., 'ccc' - > 55
      -->
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:variable name="arg-lower" select="lower-case($arg)"/>
        <xsl:choose>
            <xsl:when test="matches($arg-lower, concat('^', $letter-numeral-pattern, '$'))">
                <xsl:variable name="arg-length" select="string-length($arg-lower)"/>
                <xsl:variable name="arg-val" select="string-to-codepoints($arg-lower)[1] - 96"/>
                <xsl:value-of select="$arg-val + ($arg-length - 1) * 26"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:replace-sequence" as="xs:string?">
        <!-- Input: single string and a sequence of tan:replace elements.
         Output: string that results from each tan:replace being sequentially applied to the input string.
         Invoked by class 2 and class 3 (TAN-R-tok) files -->
        <xsl:param name="text" as="xs:string?"/>
        <xsl:param name="replace" as="node()+"/>
        <xsl:variable name="newtext">
            <xsl:choose>
                <xsl:when test="not($replace[1]/tan:flags)">
                    <xsl:value-of
                        select="replace($text, $replace[1]/tan:pattern, $replace[1]/tan:replacement)"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="replace($text, $replace[1]/tan:pattern, $replace[1]/tan:replacement, $replace[1]/tan:flags)"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="count($replace) = 1">
                <xsl:value-of select="$newtext"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="tan:replace-sequence($newtext, $replace except $replace[1])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:tokenize" as="xs:string*">
        <!-- Input: single string and a tokenize node from a TAN-R-tok file. 
         Output: tokenized sequence of strings -->
        <xsl:param name="text" as="xs:string?"/>
        <xsl:param name="tokenize" as="node()"/>
        <xsl:copy-of
            select="
                if ($tokenize/tan:flags)
                then
                    tokenize($text, $tokenize/tan:pattern, $tokenize/tan:flags)
                else
                    tokenize($text, $tokenize/tan:pattern)"
        />
    </xsl:function>

    <xsl:function name="tan:dateTime-to-decimal" as="xs:decimal?">
        <!-- Input: ISO-compliant date or dateTime 
         Output: decimal between 0 and 1 that acts as a proxy for the date and time.
         These decimal values can then be sorted and compared.
         E.g., (2015-05-10) - > 0.2015051
        -->
        <xsl:param name="time-or-dateTime" as="item()?"/>
        <xsl:variable name="utc" select="xs:dayTimeDuration('PT0H')"/>
        <xsl:variable name="dateTime">
            <xsl:choose>
                <xsl:when test="$time-or-dateTime castable as xs:dateTime">
                    <xsl:value-of select="$time-or-dateTime"/>
                </xsl:when>
                <xsl:when test="$time-or-dateTime castable as xs:date">
                    <xsl:value-of select="fn:dateTime($time-or-dateTime, xs:time('00:00:00'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="fn:dateTime(xs:date('1900-01-01'), xs:time('00:00:00'))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dt-adjusted-as-string"
            select="string(fn:adjust-dateTime-to-timezone($dateTime, $utc))"/>
        <xsl:value-of
            select="number(concat('0.', replace(replace($dt-adjusted-as-string, '[-+]\d+:\d+$', ''), '\D+', '')))"
        />
    </xsl:function>
    <xsl:function name="tan:most-recent-dateTime" as="item()?">
        <!-- Input: a series of ISO-compliant date or dateTimes
         Output: the most recent one -->
        <xsl:param name="dateTimes" as="item()*"/>
        <xsl:variable name="decimal-val" select="for $i in $dateTimes return tan:dateTime-to-decimal($i)"/>
        <xsl:variable name="most-recent" select="index-of($decimal-val,max($decimal-val))[1]"/>
        <xsl:copy-of select="$dateTimes[$most-recent]"/>
    </xsl:function>

    <xsl:function name="tan:normalize-feature-test" as="xs:string">
        <!-- Used to check for validity of @feature-test expressions; used to validate both 
            TAN-LM (class 2) and TAN-R-mor (class 3) files.
         Input: @feature-test string
         Output: @feature-test, normalized
      -->
        <xsl:param name="string" as="xs:string"/>
        <xsl:value-of select="normalize-space(replace($string, '([\(\),\|])', ' $1 '))"/>
    </xsl:function>

    <!-- CONTEXT DEPENDENT FUNCTIONS -->
    <xsl:function name="tan:resolve-url" as="xs:string?">
        <!-- Input: any string purporting to be a location of a file, and a base directory to be used
            in case the first string is a relative URL.
        Output: if input is a relative URL then that same string appended to the second parameter. If 
        the second parameter is empty or a zero-length string, the main document's parent directory will 
        be substituted. If input is not relative, only the the input is returned.
        E.g., ('../example-a.xml',()) - > 'file:/Users/admin/Documents/project/example-a.xml' -->
        <xsl:param name="input-url" as="xs:string?"/>
        <xsl:param name="input-base" as="xs:string?"/>
        <xsl:variable name="base-check" select="if (exists($input-base) and $input-base != '') then $input-base else $doc-parent-directory"/>
        <xsl:value-of
            select="
                if (resolve-uri($input-url) = $input-url) then
                    $input-url
                else
                    concat($base-check, $input-url)"
        />
    </xsl:function>
    <xsl:function name="tan:must-refer-to-external-tan-file" as="xs:boolean">
        <!-- Input: node in a TAN document. Output: boolean value indicating whether the node or its 
         parent names or refers to a TAN file. -->
        <xsl:param name="node" as="node()"/>
        <xsl:variable name="class-2-elements-that-must-always-refer-to-tan-files"
            select="('source')"/>
        <xsl:value-of
            select="
                if (
                ((name($node),
                name($node/parent::node())) = $elements-that-must-always-refer-to-tan-files)
                or ($node[(tan:relationship,
                preceding-sibling::tan:relationship) = $relationship-keywords-for-tan-files])
                or ((((name($node),
                name($node/parent::node())) = $class-2-elements-that-must-always-refer-to-tan-files)
                )
                and name($node/ancestor::node()[last() - 1]) = $class-2-root-names)
                )
                then
                    true()
                else
                    false()"
        />
    </xsl:function>

    <xsl:function name="tan:flatref" as="xs:string">
        <!-- Input: div node in a TAN-T(EI) document. Output: string value concatenating the reference values 
         from the topmost div ancestor to the node. -->
        <xsl:param name="node" as="node()"/>
        <xsl:value-of
            select="
                string-join(for $j in ($node/ancestor-or-self::tan:div | $node/ancestor-or-self::tei:div)
                return
                    concat($j/@type, $separator-type-and-n, $j/@n), $separator-hierarchy)"
        />
    </xsl:function>

</xsl:stylesheet>
