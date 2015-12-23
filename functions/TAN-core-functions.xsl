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
    
    <xsl:include href="TAN-parameters.xsl"/>

    <xsl:variable name="root" select="/"/>
    <xsl:variable name="head">
        <!--<xsl:apply-templates mode="include" select="/*/tan:head"/>-->
        <!--<xsl:for-each select="/*/tan:head">
            <xsl:apply-templates mode="include"/>
        </xsl:for-each>-->
        <xsl:variable name="head-pass-1">
            <xsl:for-each select="/*/tan:head">
                <xsl:apply-templates mode="include"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="head-pass-2">
            <xsl:for-each select="$head-pass-1">
                <xsl:apply-templates mode="strip-duplicates"/>
            </xsl:for-each>
        </xsl:variable>
        <!--<xsl:for-each select="$head-pass-1"><xsl:apply-templates mode="strip-duplicates"/></xsl:for-each>-->
        <xsl:sequence select="$head-pass-2"/>
    </xsl:variable>
    <xsl:variable name="body">
        <xsl:for-each select="/*/tan:body | /*/*/tei:body">
            <xsl:apply-templates mode="include"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:function name="tan:resolve-element" as="node()*">
        <xsl:param name="tan-element" as="node()*"/>
        <xsl:for-each select="$tan-element">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="include"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:function>
    <xsl:variable name="self-expanded" as="document-node()">
        <xsl:for-each select="/">
            <xsl:copy>
                <xsl:apply-templates mode="expand"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:variable>
    <xsl:template mode="expand" match="*[not(self::tan:body or self::tan:head)]">
        <xsl:copy>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template mode="expand" match="tan:head">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:sequence select="$head"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template mode="expand" match="tan:body">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:sequence select="$body"/>
        </xsl:copy>
    </xsl:template>
    <xsl:variable name="doc-id" select="/*/@id"/>
    <xsl:variable name="doc-uri" select="base-uri(/*)"/>
    <xsl:variable name="doc-parent-directory" select="replace($doc-uri, '[^/]+$', '')"/>
    <xsl:variable name="doc-ver-dates"
        select="distinct-values(//(@when | @ed-when | @when-accessed))"/>
    <xsl:variable name="doc-ver-nos"
        select="
            for $i in $doc-ver-dates
            return
                tan:dateTime-to-decimal($i)"/>
    <xsl:variable name="doc-ver"
        select="$doc-ver-dates[index-of($doc-ver-nos, max($doc-ver-nos))[1]]"/>
    <xsl:variable name="all-ids" select="$head//@xml:id"/>
    <xsl:variable name="all-iris" select="$head//tan:IRI"/>
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
    <xsl:variable name="experimental-root-names" select="'TAN-X'"/>
    <xsl:variable name="all-root-names"
        select="$class-1-root-names, $class-2-root-names, $class-3-root-names, $experimental-root-names"
    />
    
    <!--<xsl:variable name="inclusion-errors"
        select="$errors//tan:group[@affects-attribute = 'include']/tan:error" as="xs:string*"/>
    
    <xsl:variable name="relationship-keywords-for-tan-versions"
        select="$keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']/descendant-or-self::tan:group[@class = 'version']//tan:keyword"
        as="xs:string*"/>
    <xsl:variable name="relationship-keywords-for-tan-editions"
        select="$keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']/descendant-or-self::tan:group[@class = 'edition']//tan:keyword"
        as="xs:string*"/>
    <xsl:variable name="relationship-keywords-for-class-1-editions"
        select="$keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']/descendant-or-self::tan:group[@class = 'edition']/descendant-or-self::tan:group[@class = 'class1']//tan:keyword"
        as="xs:string*"/>
    <xsl:variable name="relationship-keywords-for-tan-files"
        select="
            $keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']//tan:keyword"
        as="xs:string*"/>
    <xsl:variable name="relationship-keywords-all"
        select="$keywords//tan:group[@affects-element = 'relationship']/descendant-or-self::tan:group[@class = 'tan']//tan:keyword"
        as="xs:string*"/>-->

    <xsl:variable name="elements-that-must-always-refer-to-tan-files"
        select="
            ('recommended-tokenization',
            'tokenization',
            'morphology',
            'inclusion')"/>
    <xsl:variable name="tag-urn-regex-pattern" select="'tag:([\-a-zA-Z0-9._%+]+@)?[\-a-zA-Z0-9.]+\.[A-Za-z]{2,4},\d{4}(-(0\d|1[0-2]))?(-([0-2]\d|3[01]))?:\S+'"/>

    <!-- variables related to tokenization -->
    <!-- Keywords reserved for officially supplied TAN-R-tok patterns -->
    <!--<xsl:variable name="tokenization-which-reserved"
        select="
            'general-1',
            'general-words-only-1',
            'precise-1'"/>-->
    <xsl:variable name="tokenization-which-reserved"
        select="$keywords//tan:group[tokenize(@affects-element, '\s+') = 'tokenization']//tan:keyword"
        as="xs:string*"/>
    <!-- Reserved URLs for officially supplied TAN-R-tok patterns -->
    <xsl:variable name="tokenization-which-reserved-url"
        select="
            for $i in ('../TAN-R-tok/general-1.xml',
            '../TAN-R-tok/general-words-only-1.xml',
            '../TAN-R-tok/precise-1.xml')
            return
                resolve-uri($i)"/>
    <xsl:variable name="tokenizations-core"
        select="
            for $i in $tokenization-which-reserved-url
            return
                doc($i)"/>
    <!-- Error messages for failures to name or access tokenization patterns -->
    <!--<xsl:variable name="tokenization-errors"
        select="
            'location fails to point to an available document',
            'a required @which is missing',
            'points to a recommended-tokenization element where the location element fails to point to an available document',
            '@which is neither in the source nor is it a reserved keyword',
            'core TAN-R-tok invoked, but is somehow unavailable',
            'tokenizations fail to accommodate every language used by a source'
            "/>-->
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
        <xsl:variable name="decimal-val"
            select="
                for $i in $dateTimes
                return
                    tan:dateTime-to-decimal($i)"/>
        <xsl:variable name="most-recent"
            select="
                if (exists($decimal-val)) then
                    index-of($decimal-val, max($decimal-val))[1]
                else
                    ()"/>
        <xsl:copy-of select="$dateTimes[$most-recent]"/>
    </xsl:function>

    <xsl:function name="tan:normalize-feature-test" as="xs:string*">
        <!-- Used to check for validity of @feature-test expressions; used to validate both 
            TAN-LM (class 2) and TAN-R-mor (class 3) files.
         Input: @feature-test string
         Output: @feature-test, normalized
      -->
        <xsl:param name="strings" as="xs:string*"/>
        <xsl:copy-of select="for $i in $strings return normalize-space(replace($i, '([\(\),\|])', ' $1 '))"/>
    </xsl:function>

    <xsl:function name="tan:escape" as="xs:string*">
        <!-- Input: any string; Output: that string prepared for regular expression searches,
        i.e., with reserved characters escaped out. -->
        <xsl:param name="strings" as="xs:string*"/>
        <xsl:copy-of
            select="for $i in $strings return replace($i, '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))', '\\$1')"/>
    </xsl:function>

    <!-- CONTEXT DEPENDENT FUNCTIONS -->
    <xsl:function name="tan:first-loc-available" as="element()?">
        <!-- One-parameter version of the function below, using the default, $doc-uri
        -->
        <xsl:param name="parent-element" as="element()?"/>
        <xsl:sequence select="tan:first-loc-available($parent-element, $doc-uri)"/>
    </xsl:function>
    <xsl:function name="tan:first-loc-available" as="element()?">
        <!-- Input: An element that contains one or more tan:location elements
            Output: the first tan:location element pointing to a document available
        -->
        <xsl:param name="parent-element" as="element()?"/>
        <xsl:param name="base-uri" as="xs:anyURI?"/>
        <xsl:variable name="norm-uri"
            select="
                if (not(exists($base-uri))) then
                    $doc-uri
                else
                    $base-uri"
            as="xs:anyURI"/>
        <xsl:sequence
            select="
                (for $i in $parent-element/tan:location,
                    $j in resolve-uri($i, $norm-uri)
                return
                    if (doc-available($j)) then
                        $i
                    else
                        ())[1]"
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

    <xsl:function name="tan:element-to-comment" as="comment()">
        <xsl:param name="element" as="element()*"/>
        <xsl:comment>
            <xsl:sequence select="$element"/>
        </xsl:comment>
    </xsl:function>

    <xsl:function name="tan:resolve-doc" as="document-node()*">
        <xsl:param name="TAN-documents" as="document-node()*"/>
        <xsl:for-each select="$TAN-documents">
            <xsl:copy>
                <xsl:copy-of select="processing-instruction()"/>
                <xsl:apply-templates mode="include"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="tan:resolve-include" as="element()*">
        <!-- One-parameter version of the main two-parameter function, below -->
        <xsl:param name="element-with-include-attr" as="element()*"/>
        <xsl:sequence select="tan:resolve-include($element-with-include-attr, $doc-uri)"/>
    </xsl:function>
    <xsl:function name="tan:resolve-include" as="node()*">
        <!-- Input: any TAN element with @include
        Output: a set of replacement TAN elements, found by looking at the chain of inclusions -->
        <xsl:param name="elements-to-be-checked-for-inclusion" as="node()*"/>
        <xsl:param name="urls-so-far" as="xs:anyURI*"/>
        <xsl:variable name="new-urls">
            <xsl:for-each select="$elements-to-be-checked-for-inclusion">
                <xsl:variable name="incl-refs" select="tokenize(current()/@include, '\s+')"/>
                <xsl:if test="@include">
                    <xsl:sequence
                        select="root()/*/tan:head/tan:inclusion[@xml:id = $incl-refs]/tan:location"
                    />
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="new-sequence" as="node()*">
            <xsl:for-each select="$elements-to-be-checked-for-inclusion">
                <xsl:choose>
                    <xsl:when test="@include">
                        <xsl:variable name="incl-refs" select="tokenize(current()/@include, '\s+')"/>
                        <xsl:variable name="these-inclusions"
                            select="root(current())/*/tan:head/tan:inclusion[@xml:id = $incl-refs]"/>
                        <xsl:variable name="these-inclusion-1st-las"
                            select="
                                for $i in $these-inclusions
                                return
                                    tan:first-loc-available($i, base-uri($i))"/>
                        <xsl:variable name="this-name" select="name()"/>
                        <xsl:variable name="these-replacement-elements"
                            select="
                                for $i in $these-inclusion-1st-las
                                return
                                    doc(resolve-uri($i, base-uri($i)))//*[name(.) = $this-name][not(parent::tan:div)]"/>
                        <xsl:variable name="these-errors" as="xs:integer?">
                            <xsl:choose>
                                <xsl:when test="not(exists($these-replacement-elements))">
                                    <xsl:copy-of select="2"/>
                                </xsl:when>
                                <xsl:when test="$these-inclusions/tan:location = $urls-so-far">
                                    <xsl:copy-of select="3"/>
                                </xsl:when>
                                <xsl:when test="count(distinct-values($this-name)) gt 1">
                                    <xsl:copy-of select="4"/>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="exists($these-errors)">
                                <xsl:copy>
                                    <xsl:attribute name="error" select="$these-errors"/>
                                </xsl:copy>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="$these-replacement-elements"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$new-sequence[@error] or not($new-sequence//@include)">
                <xsl:sequence select="$new-sequence"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence
                    select="
                        tan:resolve-include($new-sequence, ($urls-so-far,
                        $new-urls))"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="*[not(@include)]" mode="include">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="include"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="*[@include]" mode="include">
        <xsl:sequence select="tan:resolve-include(.)"/>
    </xsl:template>

    <xsl:template match="node()" mode="strip-duplicates">
        <xsl:if
            test="every $i in current()/preceding-sibling::*
                satisfies not(deep-equal(current(), $i))">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
