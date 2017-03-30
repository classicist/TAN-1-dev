<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   exclude-result-prefixes="#all" version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>March 2017</xd:p>
         <xd:p>Variables, functions, and templates for all TAN files. Written primarily for
            Schematron validation, but suitable for general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="../regex/regex-ext-tan-functions.xsl"/>
   <xsl:include href="../errors/TAN-core-errors.xsl"/>
   <xsl:include href="diff-for-xslt2.xsl"/>

   <xsl:character-map name="tan">
      <!-- This map included, so that users of TAN files can see where ZWJs and soft hyphens are in use. -->
      <xsl:output-character character="&#x200d;" string="&amp;#x200d;"/>
      <xsl:output-character character="&#xad;" string="&amp;#xad;"/>
   </xsl:character-map>

   <!-- CORE GLOBAL VARIABLES -->

   <!-- general -->
   <xsl:variable name="regex-escaping-characters" as="xs:string"
      select="'[\.\[\]\\\|\-\^\$\?\*\+\{\}\(\)]'"/>
   <xsl:variable name="regex-characters-not-permitted" select="'[&#xA0;&#x2000;-&#x200a;]'"/>
   <xsl:variable name="quot" select="'&quot;'"/>
   <xsl:variable name="apos" select='"&apos;"'/>
   <xsl:variable name="empty-doc" as="document-node()">
      <xsl:document/>
   </xsl:variable>
   <xsl:variable name="erroneously-looped-doc" as="document-node()">
      <xsl:document>
         <xsl:copy-of select="tan:error('inc03')"/>
      </xsl:document>
   </xsl:variable>
   <xsl:variable name="now" select="tan:dateTime-to-decimal(current-dateTime())"/>

   <xsl:variable name="elements-that-must-always-refer-to-tan-files"
      select="
         ('morphology',
         'inclusion',
         'key')"/>
   <xsl:variable name="tag-urn-regex-pattern"
      select="'tag:([\-a-zA-Z0-9._%+]+@)?[\-a-zA-Z0-9.]+\.[A-Za-z]{2,4},\d{4}(-(0\d|1[0-2]))?(-([0-2]\d|3[01]))?:\S+'"/>

   <xsl:variable name="all-functions" select="collection('../collection.xml')"/>
   <xsl:variable name="all-schemas" select="collection('../../schemas/collection.xml')"/>

   <xsl:variable name="TAN-namespace" select="'tag:textalign.net,2015'"/>
   <xsl:variable name="id-idrefs" select="doc('TAN-idrefs.xml')"/>

   <xsl:variable name="separator-hierarchy" select="' '" as="xs:string"/>
   <xsl:variable name="separator-hierarchy-regex" select="tan:escape($separator-hierarchy)"
      as="xs:string"/>
   <xsl:variable name="separator-hierarchy-minor" select="'#'" as="xs:string"/>
   <xsl:variable name="separator-hierarchy-minor-regex"
      select="tan:escape($separator-hierarchy-minor)" as="xs:string"/>

   <!-- If one wishes to see if an entire string matches the following patterns defined by these 
        variables, they must appear between the regular expression anchors ^ and $. -->
   <xsl:variable name="roman-numeral-pattern"
      select="'m{0,4}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})'"/>
   <xsl:variable name="letter-numeral-pattern"
      select="'a+|b+|c+|d+|e+|f+|g+|h+|i+|j+|k+|l+|m+|n+|o+|p+|q+|r+|s+|t+|u+|v+|w+|x+|y+|z+'"/>
   <xsl:variable name="n-type-pattern"
      select="
         (concat('^(', $roman-numeral-pattern, ')$'),
         '^(\d+)$',
         concat('^(\d+)(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')(\d+)$'),
         '(.)')"/>
   <xsl:variable name="n-type"
      select="
         ('i',
         '1',
         '1a',
         'a',
         'a1',
         '$')"/>
   <xsl:variable name="n-type-label"
      select="
         ('Roman numerals',
         'Arabic numerals',
         'Arabic numerals + alphabet numeral',
         'alphabet numeral',
         'alphabet numeral + Arabic numeral',
         'string')"/>
   <xsl:function name="tan:interpret-n-vals" as="element()*">
      <!-- Input: any strings representing values of @n -->
      <!-- Output: one element per @n, with at least one <val @type="[n-type]"> corresponding to the six types of numeral patterns/strings; if the input can be legitimately interpreted as that type, its converted value is in the element, otherwise it is empty -->
      <xsl:param name="ns" as="xs:string*"/>
      <xsl:for-each select="$ns">
         <xsl:variable name="this-n-norm" select="."/>
         <n orig="{.}">
            <xsl:if test="matches($this-n-norm, $n-type-pattern[1], 'i')">
               <val type="{$n-type[1]}">
                  <xsl:value-of select="tan:rom-to-int($this-n-norm)"/>
               </val>
            </xsl:if>
            <xsl:if test="matches($this-n-norm, $n-type-pattern[2])">
               <val type="{$n-type[2]}">
                  <xsl:value-of select="."/>
               </val>
            </xsl:if>
            <xsl:if test="matches($this-n-norm, $n-type-pattern[3], 'i')">
               <val type="{$n-type[3]}">
                  <xsl:value-of
                     select="concat(replace($this-n-norm, '\D+', ''), $separator-hierarchy-minor, tan:aaa-to-int(replace($this-n-norm, '\d+', '')))"
                  />
               </val>
            </xsl:if>
            <xsl:if test="matches($this-n-norm, $n-type-pattern[4], 'i')">
               <val type="{$n-type[4]}">
                  <xsl:value-of select="tan:aaa-to-int($this-n-norm)"/>
               </val>
            </xsl:if>
            <xsl:if test="matches($this-n-norm, $n-type-pattern[5], 'i')">
               <val type="{$n-type[5]}">
                  <xsl:value-of
                     select="concat(tan:aaa-to-int(replace($this-n-norm, '\d+', '')), $separator-hierarchy-minor, replace($this-n-norm, '\D+', ''))"
                  />
               </val>
            </xsl:if>
            <val type="$">
               <xsl:value-of select="."/>
            </val>
         </n>
      </xsl:for-each>
   </xsl:function>

   <!-- self -->
   <xsl:variable name="root" select="/"/>
   <xsl:variable name="self-resolved" select="tan:resolve-doc(/)" as="document-node()"/>
   <xsl:variable name="self-core-errors-marked" as="document-node()">
      <xsl:variable name="pass-1">
         <xsl:apply-templates select="$self-resolved" mode="core-attribute-errors"/>
      </xsl:variable>
      <xsl:document>
         <xsl:apply-templates select="$pass-1" mode="core-errors"/>
      </xsl:document>
   </xsl:variable>

   <xsl:variable name="head" select="$self-resolved/*/tan:head"/>
   <xsl:variable name="body" select="$self-resolved/*/(tan:body, tei:text/tei:body)"/>
   <xsl:variable name="doc-id" select="/*/@id"/>
   <xsl:variable name="doc-uri" select="base-uri(/*)"/>
   <xsl:variable name="doc-parent-directory" select="tan:uri-directory($doc-uri)"/>
   <xsl:variable name="source-ids"
      select="
         if (exists($head/tan:source/@xml:id)) then
            $head/tan:source/@xml:id
         else
            for $i in (1 to count($head/tan:source))
            return
               string($i)"/>
   <xsl:variable name="all-ids"
      select="($head//@xml:id, /tei:TEI//descendant-or-self::tei:*/@xml:id)"/>
   <xsl:variable name="all-iris" select="$head//tan:IRI[not(ancestor::tan:error)]"/>
   <xsl:variable name="duplicate-ids" select="$all-ids[index-of($all-ids, .)[2]]"/>
   <xsl:variable name="duplicate-iris" select="$all-iris[index-of($all-iris, .)[2]]"/>
   <xsl:variable name="doc-namespace"
      select="substring-before(substring-after($doc-id, 'tag:'), ':')"/>
   <xsl:variable name="primary-agent" as="element()?"
      select="($head/tan:agent[tan:IRI[matches(., concat('^tag:', $doc-namespace))]])[1]"/>

   <!-- inclusions -->
   <xsl:variable name="inclusions-1st-da" select="tan:get-1st-doc(/*/tan:head/tan:inclusion)"/>
   <xsl:variable name="inclusions-resolved"
      select="tan:resolve-doc($inclusions-1st-da, false(), 'incl', /*/tan:head/tan:inclusion/@xml:id, (), ())"
      as="document-node()*"/>
   <!-- keys -->
   <xsl:key name="item-via-node-name" match="tan:item"
      use="tokenize(string-join(((ancestor-or-self::*/@affects-element)[last()], (ancestor-or-self::*/@affects-attribute)[last()]), ' '), '\s+')"/>
   <xsl:variable name="TAN-keyword-files" as="document-node()*"
      select="collection('../../TAN-key/collection.xml')"/>
   <xsl:variable name="TAN-keywords" as="document-node()*">
      <xsl:for-each select="$TAN-keyword-files">
         <xsl:document>
            <xsl:variable name="pass1">
               <xsl:apply-templates mode="resolve-href"/>
            </xsl:variable>
            <xsl:apply-templates select="$pass1" mode="prep-tan-key"/>
         </xsl:document>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="relationship-keywords-for-tan-files"
      select="tan:get-attr-which-definition('relationship', (), 'TAN files')"/>
   <xsl:variable name="keys-1st-da" select="tan:get-1st-doc($head/tan:key)"/>
   <xsl:variable name="keys-resolved" select="tan:resolve-doc($keys-1st-da)"/>
   <xsl:variable name="keys-prepped" as="document-node()*">
      <xsl:for-each select="$keys-resolved">
         <xsl:document>
            <xsl:apply-templates mode="prep-tan-key"/>
         </xsl:document>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="all-keywords" select="($keys-resolved, $TAN-keywords)" as="document-node()*"/>
   <!-- sources -->
   <xsl:variable name="sources-1st-da" select="tan:get-1st-doc($head/tan:source)"/>
   <xsl:variable name="sources-resolved"
      select="tan:resolve-doc($sources-1st-da, false(), 'src', $source-ids, (), ())"/>
   <!-- see-also, context -->
   <xsl:variable name="see-alsos-1st-da" select="tan:get-1st-doc($head/tan:see-also)"/>
   <xsl:variable name="see-alsos-resolved" select="tan:resolve-doc($see-alsos-1st-da)"/>
   <xsl:variable name="contexts-resolved" select="$see-alsos-resolved[*/self::tan:TAN-c]"/>
   <!-- token definitions -->
   <xsl:variable name="token-definitions-reserved" select="$TAN-keywords//tan:token-definition"/>

   <!-- CORE FUNCTIONS -->

   <!-- Functions: sequences -->

   <xsl:function name="tan:duplicate-values" as="item()*">
      <!-- Input: any sequence of items -->
      <!-- Output: those items that appear in the sequence more than once -->
      <!-- This function parallels the standard fn:distinct-values() -->
      <xsl:param name="sequence" as="item()*"/>
      <xsl:copy-of select="$sequence[index-of($sequence, .)[2]]"/>
   </xsl:function>

   <xsl:function name="tan:most-common-value" as="item()?">
      <!-- Input: any sequence of items -->
      <!-- Output: the one item that appears most frequently -->
      <!-- If two or more items appear equally frequently, only the first is returned -->
      <xsl:param name="sequence" as="item()*"/>
      <xsl:for-each-group select="$sequence" group-by=".">
         <xsl:sort select="count(current-group())" order="descending"/>
         <xsl:if test="position() = 1">
            <xsl:copy-of select="current-group()[1]"/>
         </xsl:if>
      </xsl:for-each-group>
   </xsl:function>

   <xsl:function name="tan:distinct-items" as="item()*">
      <!-- Input: any sequence of items -->
      <!-- Output: Those items that are not deeply equal to any other item in the sequence -->
      <xsl:param name="items" as="item()*"/>
      <xsl:copy-of select="$items[1]"/>
      <xsl:for-each select="$items[position() gt 1]">
         <xsl:variable name="this-item" select="."/>
         <xsl:if
            test="
               not(some $i in 1 to position()
                  satisfies deep-equal($this-item, $items[$i]))">
            <xsl:copy-of select="."/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:sequence-expand" as="xs:integer*">
      <!-- Input: a string representing a TAN selector (used by @pos, @char, @seg), and an integer defining the value of 'last' -->
      <!-- Output: a sequence of numbers representing the positions selected, unsorted, and retaining duplicate values.
            Example: ("2 - 4, last-5 - last, 36", 50) -> (2, 3, 4, 45, 46, 47, 48, 49, 50, 36)
            Errors will be flagged as follows:
            0 = value that falls below 1
            -1 = value that surpasses the value of $max
            -2 = ranges that call for negative steps, e.g., '4 - 2' -->
      <xsl:param name="selector" as="xs:string?"/>
      <xsl:param name="max" as="xs:integer?"/>
      <!-- first normalize syntax -->
      <xsl:variable name="pass-1"
         select="replace(tan:normalize-text($selector), 'all|\*', '1 - last')"/>
      <xsl:variable name="pass-2" select="replace($pass-1, '(\d)\s*-\s*(last|max|\d)', '$1 - $2')"/>
      <xsl:variable name="pass-3" select="replace($pass-2, '(\d)\s+(\d)', '$1, $2')"/>
      <xsl:variable name="pass-4" as="xs:string*">
         <xsl:analyze-string select="$pass-3" regex="(last|max)(-\d+)?">
            <xsl:matching-substring>
               <xsl:variable name="second-numeral" select="replace(., '\D+', '')"/>
               <xsl:variable name="second-number"
                  select="
                     if (string-length($second-numeral) gt 0) then
                        number($second-numeral)
                     else
                        0"/>
               <xsl:value-of select="string(($max - $second-number))"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="item" select="tokenize(string-join($pass-4, ''), ' ?, +')"/>
      <xsl:for-each select="$item">
         <xsl:variable name="range"
            select="
               for $i in tokenize(., ' - ')
               return
                  xs:integer($i)"/>
         <xsl:choose>
            <xsl:when test="$range[1] lt 1 or $range[2] lt 1">
               <xsl:copy-of select="0"/>
            </xsl:when>
            <xsl:when test="$range[1] gt $max or $range[2] gt $max">
               <xsl:copy-of select="-1"/>
            </xsl:when>
            <xsl:when test="$range[1] ge $range[2]">
               <xsl:copy-of select="-2"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="$range[1] to $range[last()]"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:sequence-error" as="element()*">
      <xsl:param name="results-of-sequence-expand" as="xs:integer*"/>
      <xsl:copy-of select="tan:sequence-error($results-of-sequence-expand, ())"/>
   </xsl:function>
   <xsl:function name="tan:sequence-error" as="element()*">
      <!-- Input: any results of the function tan:sequence-expand() -->
      <!-- Output: error nodes, if any -->
      <xsl:param name="results-of-sequence-expand" as="xs:integer*"/>
      <xsl:param name="message" as="xs:string?"/>
      <xsl:for-each select="$results-of-sequence-expand[. lt 1]">
         <xsl:if test=". = 0">
            <xsl:copy-of select="tan:error('seq01', $message)"/>
         </xsl:if>
         <xsl:if test=". = -1">
            <xsl:copy-of select="tan:error('seq02', $message)"/>
         </xsl:if>
         <xsl:if test=". = -2">
            <xsl:copy-of select="tan:error('seq03', $message)"/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>


   <!-- Functions: date, time, version -->

   <xsl:function name="tan:dateTime-to-decimal" as="xs:decimal*">
      <!-- Input: any xs:date or xs:dateTime -->
      <!-- Output: decimal between 0 and 1 that acts as a proxy for the date and time. These decimal values can then be sorted and compared. -->
      <!-- Example: (2015-05-10) - > 0.2015051 -->
      <!-- If input is not castable as a date or dateTime, 0 is returned -->
      <xsl:param name="time-or-dateTime" as="item()*"/>
      <xsl:for-each select="$time-or-dateTime">
         <xsl:variable name="utc" select="xs:dayTimeDuration('PT0H')"/>
         <xsl:variable name="dateTime" as="xs:dateTime?">
            <xsl:choose>
               <xsl:when test=". castable as xs:dateTime">
                  <xsl:value-of select="."/>
               </xsl:when>
               <xsl:when test=". castable as xs:date">
                  <xsl:value-of select="fn:dateTime(., xs:time('00:00:00'))"/>
               </xsl:when>
            </xsl:choose>
         </xsl:variable>
         <xsl:variable name="dt-adjusted-as-string"
            select="string(fn:adjust-dateTime-to-timezone($dateTime, $utc))"/>
         <xsl:value-of
            select="
               if (exists($dateTime)) then
                  number(concat('0.', replace(replace($dt-adjusted-as-string, '[-+]\d+:\d+$', ''), '\D+', '')))
               else
                  0"
         />
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:most-recent-dateTime" as="item()?">
      <!-- Input: a series of ISO-compliant date or dateTimes -->
      <!-- Output: the most recent one -->
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
   <xsl:function name="tan:get-doc-hist" as="element()*">
      <!-- Input: any TAN document -->
      <!-- Output: a sequence of elements with @when, @ed-when, and @when-accessed, sorted from most recent to least; each element includes @when-sort, a decimal that represents the value of the most recent time-date stamp in that element -->
      <xsl:param name="TAN-doc" as="document-node()*"/>
      <xsl:for-each select="$TAN-doc">
         <xsl:variable name="doc-hist-raw" as="element()*">
            <xsl:for-each select=".//*[@when | @ed-when | @when-accessed]">
               <xsl:variable name="these-dates" as="xs:decimal*"
                  select="
                     for $i in (@when | @ed-when | @when-accessed)
                     return
                        tan:dateTime-to-decimal($i)"/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="when-sort" select="max($these-dates)"/>
                  <xsl:copy-of select="text()[matches(., '\S')]"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:variable>
         <history>
            <xsl:copy-of select="*/@*"/>
            <xsl:for-each select="$doc-hist-raw">
               <xsl:sort select="@when-sort" order="descending"/>
               <xsl:copy-of select="."/>
            </xsl:for-each>
         </history>
      </xsl:for-each>
   </xsl:function>


   <!-- Functions: text, numerals -->

   <xsl:function name="tan:normalize-text" as="xs:string*">
      <!-- one-parameter version of full function below -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:copy-of select="tan:normalize-text($text, false())"/>
   </xsl:function>
   <xsl:function name="tan:normalize-text" as="xs:string*">
      <!-- Input: any sequence of strings; a boolean indicating whether the results should be normalized further to a common form -->
      <!-- Output: that sequence, with each item's space normalized, and removal of any help requested -->
      <!-- A common form is one where the string is converted to lower-case, and hyphens are replaced by spaces -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:param name="render-common" as="xs:boolean"/>
      <xsl:variable name="pass1"
         select="
            for $i in $text
            return
               normalize-space(replace($i, $help-trigger-regex, ''))"/>
      <xsl:copy-of
         select="
            if ($render-common = true()) then
               lower-case(replace($pass1, '-', ' '))
            else
               $pass1"
      />
   </xsl:function>

   <xsl:function name="tan:rom-to-int" as="xs:integer*">
      <!-- Input: any roman numeral less than 5000 -->
      <!-- Output: the numeral converted to an integer -->
      <xsl:param name="arg" as="xs:string*"/>
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
      <xsl:for-each select="$arg">
         <xsl:variable name="arg-lower" select="lower-case(.)"/>
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
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:aaa-to-int" as="xs:integer*">
      <!-- Input: any alphabet numerals -->
      <!-- Output:the integer equivalent -->
      <!-- Sequence goes a, b, c, ... z, aa, bb, ..., aaa, bbb, ....  E.g., 'ccc' - > 55 -->
      <xsl:param name="arg" as="xs:string*"/>
      <xsl:for-each select="$arg">
         <xsl:variable name="arg-lower" select="lower-case(.)"/>
         <xsl:if test="matches($arg-lower, concat('^(', $letter-numeral-pattern, ')$'))">
            <xsl:variable name="arg-length" select="string-length($arg-lower)"/>
            <xsl:variable name="arg-val" select="string-to-codepoints($arg-lower)[1] - 96"/>
            <xsl:value-of select="$arg-val + ($arg-length - 1) * 26"/>
         </xsl:if>

      </xsl:for-each>
   </xsl:function>

   <xsl:variable name="alphabet-numeral-key" as="element()">
      <key>
         <convert grc="α" syc="ܐ" int="1"/>
         <convert grc="β" syc="ܒ" int="2"/>
         <convert grc="γ" syc="ܓ" int="3"/>
         <convert grc="δ" syc="ܕ" int="4"/>
         <convert grc="ε" syc="ܗ" int="5"/>
         <convert grc="ϛ" syc="ܘ" int="6"/>
         <convert grc="ζ" syc="ܙ" int="7"/>
         <convert grc="η" syc="ܚ" int="8"/>
         <convert grc="θ" syc="ܛ" int="9"/>
         <convert grc="ι" syc="ܝ" int="10"/>
         <convert grc="κ" syc="ܟ" int="20"/>
         <convert grc="λ" syc="ܠ" int="30"/>
         <convert grc="μ" syc="ܡ" int="40"/>
         <convert grc="ν" syc="ܢ" int="50"/>
         <convert grc="ξ" syc="ܣ" int="60"/>
         <convert grc="ο" syc="ܥ" int="70"/>
         <convert grc="π" syc="ܦ" int="80"/>
         <convert grc="ϙ" syc="ܨ" int="90"/>
         <convert grc="ρ" syc="ܩ" int="100"/>
         <convert grc="σ" syc="ܪ" int="200"/>
         <convert grc="τ" syc="ܫ" int="300"/>
         <convert grc="υ" syc="ܬ" int="400"/>
         <convert grc="φ" syc="" int="500"/>
         <convert grc="χ" syc="" int="600"/>
         <convert grc="ψ" syc="" int="700"/>
         <convert grc="ω" syc="" int="800"/>
         <convert grc="ϡ" syc="" int="900"/>
      </key>
   </xsl:variable>

   <xsl:function name="tan:letter-to-number" as="xs:integer*">
      <!-- Input: any sequence of strings that represent alphabetic numerals -->
      <!-- Output: those numerals -->
      <!-- NB, currently works only for Greek and Syriac; anything else produces null results -->
      <xsl:param name="numerical-letters" as="xs:anyAtomicType*"/>
      <xsl:for-each select="$numerical-letters">
         <xsl:variable name="pass1" as="xs:integer*">
            <xsl:analyze-string select="." regex=".">
               <xsl:matching-substring>
                  <xsl:variable name="this-letter" select="."/>
                  <xsl:choose>
                     <xsl:when test="matches(., '^\p{IsSyriac}+$')">
                        <xsl:copy-of
                           select="xs:integer(($alphabet-numeral-key/*[matches(@syc, $this-letter, 'i')][1]/@int))"
                        />
                     </xsl:when>
                     <xsl:when test="matches(., '^\p{IsGreek}+$')">
                        <xsl:copy-of
                           select="xs:integer(($alphabet-numeral-key/*[matches(@grc, $this-letter, 'i')][1]/@int))"
                        />
                     </xsl:when>
                  </xsl:choose>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <xsl:value-of select="sum($pass1)"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:grc-to-int" as="xs:integer*">
      <!-- Input: Greek letters that represent numerals -->
      <!-- Output: the numerical value of the letters -->
      <!-- NB, this does not take into account the use of letters representing numbers 1000 and greater -->
      <xsl:param name="greek-numerals" as="xs:string*"/>
      <xsl:value-of select="tan:letter-to-number($greek-numerals)"/>
   </xsl:function>
   <xsl:function name="tan:syc-to-int" as="xs:integer*">
      <!-- Input: Syriac letters that represent numerals -->
      <!-- Output: the numerical value of the letters -->
      <!-- NB, this does not take into account the use of letters representing numbers 1000 and greater -->
      <xsl:param name="syriac-numerals" as="xs:string*"/>
      <xsl:for-each select="$syriac-numerals">
         <xsl:variable name="orig-numeral-seq" as="xs:string*">
            <xsl:analyze-string select="." regex=".">
               <xsl:matching-substring>
                  <xsl:value-of select="."/>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <!-- The following removes redoubled numerals as often happens in Syriac, to indicate clearly that a character is a numeral not a letter. -->
         <xsl:variable name="duplicates-stripped"
            select="
               for $i in (1 to count($orig-numeral-seq))
               return
                  if ($orig-numeral-seq[$i] = $orig-numeral-seq[$i + 1]) then
                     ()
                  else
                     $orig-numeral-seq[$i]"/>
         <xsl:value-of select="tan:letter-to-number(string-join($duplicates-stripped, ''))"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:escape" as="xs:string*">
      <!-- Input: any sequence of strings -->
      <!-- Output: each string prepared for regular expression searches, i.e., with reserved characters escaped out. -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:copy-of
         select="
            for $i in $strings
            return
               replace($i, concat('(', $regex-escaping-characters, ')'), '\\$1')"
      />
   </xsl:function>

   <xsl:function name="tan:batch-replace" as="xs:string?">
      <!-- Input: a string, a sequence of <[ANY NAME] pattern="" replacement="" [flags=""]> -->
      <!-- Output: the string, after those replaces are processed in order -->
      <xsl:param name="string" as="xs:string?"/>
      <xsl:param name="replace-elements" as="element()*"/>
      <xsl:choose>
         <xsl:when test="not(exists($replace-elements))">
            <xsl:value-of select="$string"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="new-string"
               select="
                  if (exists($replace-elements[1]/@flags)) then
                     tan:replace($string, $replace-elements[1]/@pattern, $replace-elements[1]/@replacement, $replace-elements[1]/@flags)
                  else
                     tan:replace($string, $replace-elements[1]/@pattern, $replace-elements[1]/@replacement)"/>
            <xsl:value-of
               select="tan:batch-replace($new-string, $replace-elements[position() gt 1])"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>


   <!-- Functions: uris, filenames -->

   <xsl:function name="tan:cfn" as="xs:string*">
      <!-- Input: any items -->
      <!-- Output: the Current File Name, without extension, of the host document node of each item -->
      <xsl:param name="item" as="item()*"/>
      <xsl:for-each select="$item">
         <xsl:value-of select="replace(xs:string(tan:base-uri(.)), '.+/(.+)\.\w+$', '$1')"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:uri-directory" as="xs:string*">
      <!-- Input: any URIs, as strings -->
      <!-- Output: the file path -->
      <!-- NB, this function does not assume any URIs have been resolved -->
      <xsl:param name="uris" as="xs:string*"/>
      <xsl:for-each select="$uris">
         <xsl:value-of select="replace(., '[^/]+$', '')"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:base-uri" as="xs:anyURI?">
      <!-- Input: any node -->
      <!-- Output: the base uri of the node's document -->
      <!-- NB, this function differs from fn:base-uri in that it first looks for a @base-uri stamped at the document node. This is important because many TAN documents will be transformed, bound to variables, and so divorced from an original context dectable only through @base-uri. -->
      <xsl:param name="any-node" as="node()?"/>
      <xsl:copy-of select="(root($any-node)/*/@base-uri, base-uri($any-node))[1]"/>
   </xsl:function>
   <xsl:function name="tan:zip-uris" as="xs:anyURI*">
      <!-- Input: any string representing a uri -->
      <!-- Output: the same string with 'zip:' prepended if it represents a uri to a file in an archive (docx, jar, zip, etc.) -->
      <xsl:param name="uris" as="xs:string*"/>
      <xsl:for-each select="$uris">
         <xsl:value-of
            select="
               if (matches(., '!/')) then
                  concat('zip:', .)
               else
                  ."
         />
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:uri-relative-to" as="xs:string?">
      <!-- Input: two strings representing URIs -->
      <!-- Output: the first string resolved relative to the second string -->
      <xsl:param name="uri-to-revise" as="xs:string?"/>
      <xsl:param name="uri-to-revise-against" as="xs:string?"/>
      <xsl:variable name="uri-a-resolved" select="resolve-uri($uri-to-revise)"/>
      <xsl:variable name="uri-b-resolved" select="resolve-uri($uri-to-revise-against)"/>
      <xsl:variable name="path-a" as="element()">
         <path-a>
            <xsl:if test="string-length($uri-a-resolved) gt 0">
               <xsl:analyze-string select="$uri-a-resolved" regex="/">
                  <xsl:non-matching-substring>
                     <step>
                        <xsl:value-of select="."/>
                     </step>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:if>
         </path-a>
      </xsl:variable>
      <xsl:variable name="path-b" as="element()">
         <path-b>
            <xsl:if test="string-length($uri-b-resolved) gt 0">
               <xsl:analyze-string select="$uri-b-resolved" regex="/">
                  <xsl:non-matching-substring>
                     <step>
                        <xsl:value-of select="."/>
                     </step>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:if>
         </path-b>
      </xsl:variable>
      <xsl:variable name="path-a-steps" select="count($path-a/tan:step)"/>
      <xsl:variable name="last-common-step"
         select="
            (for $i in (1 to $path-a-steps)
            return
               if ($path-a/tan:step[$i] = $path-b/tan:step[$i]) then
                  ()
               else
                  $i)[1] - 1"/>
      <xsl:variable name="new-path-a" as="element()">
         <path-a>
            <xsl:for-each
               select="$path-b/(tan:step[position() gt $last-common-step] except tan:step[last()])">
               <step>..</step>
            </xsl:for-each>
            <xsl:copy-of select="$path-a/tan:step[position() gt $last-common-step]"/>
         </path-a>
      </xsl:variable>
      <xsl:value-of select="string-join($new-path-a/tan:step, '/')"/>
   </xsl:function>

   <!-- Functions: TAN structure -->

   <xsl:function name="tan:tan-type" as="xs:string*">
      <!-- Input: any nodes -->
      <!-- Output: the names of the root elements; if not present, a zero-length string is returned -->
      <xsl:param name="nodes" as="node()*"/>
      <xsl:for-each select="$nodes">
         <xsl:copy-of select="name(root()/*)"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:class-number" as="xs:integer*">
      <!-- Input: any nodes of a TAN document -->
      <!-- Output: one digit per node, specifying which TAN class the file fits, based on the name of the root element. If no match is found in the root element, 0 is returned -->
      <xsl:param name="nodes" as="node()*"/>
      <xsl:variable name="tan-classes" as="element()">
         <tan>
            <class n="1">
               <root>TAN-T</root>
               <root>TEI</root>
            </class>
            <class n="2">
               <root>TAN-A-div</root>
               <root>TAN-A-tok</root>
               <root>TAN-LM</root>
            </class>
            <class n="3">
               <root>TAN-mor</root>
               <root>TAN-key</root>
               <root>TAN-c</root>
            </class>
         </tan>
      </xsl:variable>
      <xsl:for-each select="$nodes">
         <xsl:variable name="this-root-name" select="tan:tan-type(.)"/>
         <xsl:variable name="this-class"
            select="$tan-classes/tan:class[tan:root = $this-root-name]/@n"/>
         <xsl:copy-of
            select="
               if (exists($this-class)) then
                  $this-class
               else
                  0"
         />
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:must-refer-to-external-tan-file" as="xs:boolean">
      <!-- Input: node in a TAN document. -->
      <!-- Output: boolean value indicating whether the node or its parent must name or refer to a TAN file. -->
      <xsl:param name="node" as="node()"/>
      <xsl:variable name="class-2-elements-that-must-always-refer-to-tan-files" select="('source')"/>
      <xsl:variable name="this-class" select="tan:class-number($node)"/>
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
            and $this-class = 2)
            )
            then
               true()
            else
               false()"
      />
   </xsl:function>

   <!-- Functions: file processing -->

   <xsl:function name="tan:first-loc-available" as="xs:string*">
      <!-- Input: An element that contains one or more tan:location elements -->
      <!-- Output: the value of the first tan:location/@href to point to a document available, resolved If no location is available nothing is returned. -->
      <xsl:param name="elements-that-are-locations-or-parents-of-locations" as="element()*"/>
      <xsl:for-each select="$elements-that-are-locations-or-parents-of-locations">
         <xsl:variable name="base-uri" select="tan:base-uri(.)"/>
         <xsl:copy-of
            select="
               (for $i in (self::tan:master-location, self::tan:location, tan:location)/@href,
                  $j in resolve-uri($i, string($base-uri))
               return
                  if (doc-available($j)) then
                     $j
                  else
                     ())[1]"
         />
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:get-1st-doc" as="document-node()*">
      <!-- Input: any TAN elements naming files (e.g., <source>, <see-also>, <inclusion>, <key>; an indication whether some basic errors should be checked if the retrieved file is a TAN document -->
      <!-- Output: the first document available for each element, plus/or any relevant error messages. -->
      <xsl:param name="TAN-elements" as="element()*"/>
      <xsl:for-each select="$TAN-elements">
         <xsl:variable name="this-element" select="."/>
         <xsl:variable name="this-class" select="tan:class-number(.)"/>
         <xsl:variable name="first-la" select="tan:first-loc-available(.)"/>
         <xsl:variable name="this-id" select="root(.)/*/@id"/>
         <xsl:choose>
            <xsl:when test="string-length($first-la) lt 1">
               <xsl:document>
                  <xsl:choose>
                     <xsl:when test="self::tan:inclusion">
                        <xsl:copy-of select="tan:error('inc04')"/>
                     </xsl:when>
                     <xsl:when test="self::tan:key">
                        <xsl:copy-of select="tan:error('whi04')"/>
                     </xsl:when>
                     <xsl:when test="$this-class = 1">
                        <xsl:copy-of select="tan:error('wrn01')"/>
                     </xsl:when>
                     <xsl:when
                        test="self::tan:source and not(exists(tan:location)) and tan:tan-type(.) = 'TAN-mor'"/>
                     <xsl:otherwise>
                        <xsl:copy-of select="tan:error('loc01')"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:document>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-doc" select="doc($first-la)"/>
               <xsl:choose>
                  <xsl:when test="$this-doc/*/@id = $this-id">
                     <xsl:document>
                        <xsl:copy-of select="tan:error('tan16')"/>
                     </xsl:document>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="$this-doc"></xsl:sequence>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:resolve-doc" as="document-node()*">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="TAN-documents" as="document-node()*"/>
      <xsl:copy-of select="tan:resolve-doc($TAN-documents, true(), (), (), (), ())"/>
   </xsl:function>
   <xsl:function name="tan:resolve-doc" as="document-node()*">
      <!-- Input: any number of TAN documents; boolean indicating whether documents should be breadcrumbed or not; optional name of an attribute and a sequence of strings to stamp in each document's root element as a way of providing another identifier for the document; a list of element names to which any inclusion should be restricted; a list of ids for documents that should not be used to generate inclusions.
      Output: those same documents, resolved, along the following steps:
           1. Stamp each document with @base-uri and the optional root attribute; resolve @href, putting the original (if different) in @orig-href
           2. Normalize @ref and @n, converting them whenever possible to Arabic numerals, and keeping the old versions as @orig-ref and @orig-n; if @n is a range or series, it will be expanded
           3. Resolve every element that has @include.
           4. Resolve every element that has @which.
           5. If anything happened at #3, remove any duplicate elements. -->
      <!-- This function and the functions connected with it are among the most important in the TAN library, since they provide critical stamping (for validation and diagnosing problems) and expand abbreviated parts (to explicitly state what is implied by @include and @which) of a TAN file. Perhaps more importantly, it is a recursive function that is used to resolve not only the beginning of the inclusion process but its middle and endpoints as well. -->
      <xsl:param name="TAN-documents" as="document-node()*"/>
      <xsl:param name="leave-breadcrumbs" as="xs:boolean"/>
      <xsl:param name="add-attr-to-root-element-named-what" as="xs:string?"/>
      <xsl:param name="add-what-val-to-new-root-attribute" as="xs:string*"/>
      <xsl:param name="restrict-inclusion-to-what-element-names" as="xs:string*"/>
      <xsl:param name="doc-ids-already-checked" as="xs:string*"/>
      <xsl:for-each select="$TAN-documents">
         <xsl:variable name="this-doc" select="."/>
         <xsl:variable name="this-doc-no" select="position()"/>
         <xsl:variable name="this-doc-stamped-attr-val"
            select="$add-what-val-to-new-root-attribute[$this-doc-no]"/>
         <xsl:variable name="this-doc-id" select="$this-doc/*/@id"/>
         <xsl:variable name="new-doc-ids-checked-so-far"
            select="($doc-ids-already-checked, $this-doc-id)"/>
         <xsl:variable name="elements-that-must-be-expanded"
            select="
               $this-doc//*[@include][if (exists($restrict-inclusion-to-what-element-names)) then
                  name() = $restrict-inclusion-to-what-element-names
               else
                  true()]"/>
         <xsl:variable name="included-docs-resolved" as="document-node()*">
            <xsl:for-each-group select="$elements-that-must-be-expanded"
               group-by="tokenize(tan:normalize-text(@include), ' ')">
               <xsl:variable name="this-inclusion-idref" select="current-grouping-key()"/>
               <xsl:variable name="this-inclusion-element"
                  select="$this-doc/*/tan:head/tan:inclusion[@xml:id = $this-inclusion-idref]"/>
               <xsl:variable name="this-inclusion-doc"
                  select="tan:get-1st-doc($this-inclusion-element)"/>
               <xsl:variable name="names-of-elements-to-fetch"
                  select="
                     for $i in current-group()
                     return
                        name($i)"
                  as="xs:string*"/>
               <xsl:choose>
                  <xsl:when test="not(exists($this-inclusion-element))">
                     <xsl:document>
                        <xsl:copy-of select="tan:error('tan05')"/>
                     </xsl:document>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of
                        select="tan:resolve-doc($this-inclusion-doc, false(), 'inclusion', $this-inclusion-idref, $names-of-elements-to-fetch, $new-doc-ids-checked-so-far)"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each-group>
         </xsl:variable>
         <xsl:variable name="doc-stamped" as="document-node()?">
            <xsl:document>
               <xsl:apply-templates mode="first-stamp">
                  <xsl:with-param name="leave-breadcrumbs" select="$leave-breadcrumbs" tunnel="yes"/>
                  <xsl:with-param name="stamp-root-element-with-attr-name"
                     select="$add-attr-to-root-element-named-what"/>
                  <xsl:with-param name="stamp-root-element-with-attr-val"
                     select="$this-doc-stamped-attr-val"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:variable>
         <xsl:variable name="doc-with-n-and-ref-converted" as="document-node()?">
            <xsl:variable name="elements-to-convert"
               select="$this-doc/(tan:*/tan:body, tei:TEI/tei:text/tei:body)/*"/>
            <xsl:variable name="ambiguous-numeral-types"
               select="
                  tan:analyze-elements-with-numeral-attributes($elements-to-convert, if (name($this-doc/*) = ('TAN-T', 'TEI')) then
                     'type'
                  else
                     (), true(), false())"
               as="element()*"/>
            <xsl:document>
               <xsl:apply-templates select="$doc-stamped" mode="arabic-numerals">
                  <xsl:with-param name="ambiguous-numeral-types" select="$ambiguous-numeral-types"
                     tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:variable>
         <xsl:variable name="doc-attr-include-expanded" as="document-node()?">
            <xsl:choose>
               <xsl:when test="not(exists($elements-that-must-be-expanded))">
                  <xsl:sequence select="$doc-with-n-and-ref-converted"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:document>
                     <xsl:apply-templates select="$doc-with-n-and-ref-converted"
                        mode="resolve-attr-include">
                        <xsl:with-param name="tan-doc-ids-checked-so-far"
                           select="$new-doc-ids-checked-so-far" tunnel="yes"/>
                        <xsl:with-param name="docs-whence-inclusion-resolved"
                           select="$included-docs-resolved" tunnel="yes"/>
                     </xsl:apply-templates>
                  </xsl:document>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:variable name="names-of-elements-with-attr-include" as="xs:string*"
            select="
               distinct-values(for $i in $elements-that-must-be-expanded
               return
                  name($i))"/>
         <xsl:variable name="extra-keys-1st-da"
            select="tan:get-1st-doc($doc-attr-include-expanded/*/tan:head/tan:key[not(@include)])"/>
         <xsl:variable name="extra-keys-resolved"
            select="tan:resolve-doc($extra-keys-1st-da, false(), (), (), ('group', 'item'), ())"
            as="document-node()*"/>
         <xsl:variable name="duplicate-keys-removed" as="document-node()*">
            <xsl:for-each select="$extra-keys-resolved">
               <xsl:variable name="pos" select="position()"/>
               <xsl:variable name="this-key" select="." as="document-node()"/>
               <xsl:if
                  test="
                     not(some $i in $extra-keys-resolved[position() lt $pos]
                        satisfies deep-equal($i/*, $this-key/*))">
                  <xsl:sequence select="."/>
               </xsl:if>
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="doc-attr-which-expanded" as="document-node()?">
            <xsl:document>
               <xsl:apply-templates select="$doc-attr-include-expanded" mode="resolve-keyword">
                  <xsl:with-param name="extra-keys" select="$duplicate-keys-removed" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:variable>
         <xsl:choose>
            <xsl:when test="*/@id = $doc-ids-already-checked">
               <xsl:sequence select="."/>
            </xsl:when>
            <xsl:otherwise>
               <!-- diagnostics, results -->
               <!--<xsl:copy-of select="$doc-stamped"/>-->
               <!--<xsl:copy-of select="$doc-attr-which-expanded"/>-->
               <!--<xsl:copy-of select="$doc-attr-include-expanded"/>-->
               <!--<xsl:document><xsl:copy-of select="$doc-attr-include-expanded/*/tan:head/tan:key"/></xsl:document>-->
               <!--<xsl:copy-of select="$extra-keys-1st-da"/>-->
               <!--<xsl:copy-of select="$extra-keys-resolved"/>-->
               <!--<xsl:copy-of select="$duplicate-keys-removed"/>-->
               <xsl:copy-of
                  select="tan:strip-duplicates($doc-attr-which-expanded, $names-of-elements-with-attr-include)"
               />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:key name="q-ref" match="*" use="tan:q-ref(.)"/>
   <xsl:function name="tan:q-ref" as="xs:string*">
      <!-- Input: any elements -->
      <!-- Output: the q-ref of each element-->
      <!-- A q-ref is defined as a concatenated string  consisting of, for each ancestor and self, the name plus the number indicating which sibling it is of that type of element. -->
      <!-- This function is useful when trying to correlate an unbreadmarked file (an original TAN file) against its breadcrumbed counterpart (e.g., $self-resolved), to check for errors. If any changes in element names, e.g., TEI - > TAN-T, are made during the standard preparation process, those changes are made here as well. -->
      <xsl:param name="elements" as="element()*"/>
      <xsl:for-each select="$elements">
         <xsl:variable name="pass1" as="xs:string*">
            <xsl:for-each select="ancestor-or-self::*">
               <xsl:variable name="this-name" select="name()"/>
               <xsl:copy-of
                  select="
                     if ($this-name = 'TEI') then
                        'TAN-T'
                     else
                        $this-name"/>
               <xsl:copy-of
                  select="
                     if (exists(@q)) then
                        @q
                     else
                        string(count(preceding-sibling::*[name(.) = $this-name]) + 1)"
               />
            </xsl:for-each>
         </xsl:variable>
         <xsl:value-of select="string-join($pass1, ' ')"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:get-via-q-ref" as="node()*">
      <!-- Input: any number of qrefs, any number of q-reffed documents -->
      <!-- Output: the elements corresponding to the q-refs -->
      <!-- This function is used by the core validation routine, especially to associate errors in included elements with the primary including element -->
      <xsl:param name="q-ref" as="xs:string*"/>
      <xsl:param name="q-reffed-document" as="document-node()*"/>
      <xsl:for-each select="$q-reffed-document">
         <xsl:copy-of select="key('q-ref', $q-ref, .)"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:tokenize-leaf-div" as="element()?">
      <!-- Input: single string and a <token-definition>. -->
      <!-- Output: <result> with matches and non matches enclosed by <tok> and <non-tok>, respectively -->
      <xsl:param name="text" as="xs:string?"/>
      <xsl:param name="token-definition" as="element(tan:token-definition)?"/>
      <xsl:param name="count-toks" as="xs:boolean?"/>
      <xsl:variable name="this-tok-def"
         select="
            if (count($token-definition) gt 0) then
               $token-definition
            else
               $token-definitions-reserved[1]"/>
      <xsl:variable name="regex" select="$this-tok-def/@regex"/>
      <xsl:variable name="flags" select="$this-tok-def/@flags"/>
      <xsl:variable name="results" as="element()">
         <results regex="{$regex}" flags="{$flags}">
            <xsl:analyze-string select="$text" regex="{$regex}">
               <xsl:matching-substring>
                  <tok>
                     <xsl:value-of select="."/>
                  </tok>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <non-tok>
                     <xsl:value-of select="."/>
                  </non-tok>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </results>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="$count-toks = true()">
            <xsl:apply-templates select="$results" mode="count-tokens"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$results"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:template match="tan:results" mode="count-tokens">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="max-toks" select="count(tan:tok)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:non-tok" mode="count-tokens">
      <non-tok n="{count(preceding-sibling::tan:non-tok) + 1}">
         <xsl:value-of select="."/>
      </non-tok>
   </xsl:template>
   <xsl:template match="tan:tok" mode="count-tokens">
      <tok n="{count(preceding-sibling::tan:tok) + 1}">
         <xsl:value-of select="."/>
      </tok>
   </xsl:template>

   <!-- Functions: IRI comparison -->

   <xsl:function name="tan:has-relationship" as="xs:boolean">
      <!-- Input: a <see-also> element, a sequence of strings identifying names of keywords, and any extra TAN-key files you want to check, other than the standard TAN-key files. -->
      <!-- Output: boolean value specifying whether the <see-also> has a <relationship> that has the keyword defined -->
      <!-- This function will first check to see if IRIs in a <relationship> match, and if no IRIs are found then the check is performed on @which (against a <name> in the key definition). -->
      <xsl:param name="see-also-element" as="element()"/>
      <xsl:param name="keyword" as="xs:string*"/>
      <xsl:param name="extra-keys" as="document-node()*"/>
      <xsl:variable name="all-keys" select="$extra-keys, $TAN-keywords"/>
      <xsl:variable name="relationship-definitions"
         select="tan:get-attr-which-definition('relationship', $extra-keys, ())"/>
      <xsl:variable name="this-relationship-IRIs"
         select="$see-also-element/tan:relationship/tan:IRI"/>
      <xsl:variable name="this-relationship-attr-which"
         select="tan:normalize-text($see-also-element/tan:relationship/@which)"/>
      <xsl:value-of
         select="
            if (exists($this-relationship-IRIs)) then
               $this-relationship-IRIs = $relationship-definitions[tan:name = $keyword]/tan:IRI
            else
               $this-relationship-attr-which = $relationship-definitions[tan:name = $keyword and tan:name = $this-relationship-attr-which]"
      />
   </xsl:function>
   <xsl:function name="tan:get-attr-which-definition" as="element()*">
      <!-- one-parameter version of the master one, below -->
      <xsl:param name="element-that-takes-attribute-which" as="item()"/>
      <xsl:copy-of
         select="tan:get-attr-which-definition($element-that-takes-attribute-which, $keys-1st-da, ())"
      />
   </xsl:function>
   <xsl:function name="tan:get-attr-which-definition" as="element()*">
      <!-- Input: any element that has @which (or a string value of the name of an element that takes @which); any TAN-key documents other than the standard TAN ones; and an optional name that restricts the search to a particular group -->
      <!-- Output: the tan:items that are valid keywords for the element in question -->
      <xsl:param name="element-that-takes-attribute-which" as="item()"/>
      <xsl:param name="extra-TAN-key-docs" as="document-node()*"/>
      <xsl:param name="group-name-filter" as="xs:string?"/>
      <xsl:variable name="element-name" as="xs:string?"
         select="
            if ($element-that-takes-attribute-which instance of xs:string) then
               $element-that-takes-attribute-which
            else
               name($element-that-takes-attribute-which)"/>
      <xsl:variable name="extra-keys-prepped" as="document-node()*">
         <xsl:for-each select="$extra-TAN-key-docs">
            <xsl:document>
               <xsl:apply-templates mode="prep-tan-key"/>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="all-TAN-key-docs" select="$extra-keys-prepped, $TAN-keywords"/>
      <xsl:sequence
         select="
            for $i in $all-TAN-key-docs
            return
               key('item-via-node-name', $element-name, $i)[if (string-length($group-name-filter) gt 0) then
                  (ancestor::tan:group/tan:name = $group-name-filter)
               else
                  true()]"
      />
   </xsl:function>



   <!-- TRANSFORMATIVE TEMPLATES -->

   <!-- Default templates, shared across modes -->
   <xsl:template match="node()"
      mode="resolve-href include resolve-attr-include resolve-keyword arabic-numerals strip-duplicates prep-tan-key">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:tail" mode="#all" priority="0">
      <!-- We ignore, but retain, tails throughout -->
      <xsl:copy-of select="."/>
   </xsl:template>

   <!-- Mode-specific templates -->
   <xsl:template match="/*" mode="first-stamp">
      <!-- The first-stamp mode ensures that when a document is handed over to a variable,
      the original document URI is not lost. It also provides (1) the breadcrumbing service, so that
      errors occurring downstream, in an inclusion or TAN-key file can be diagnosed, and (2) the option
      for @src to be imprinted on the root element, so that a class 1 TAN file can be tethered to a 
      class 2 file that uses it as a source.-->
      <xsl:param name="leave-breadcrumbs" as="xs:boolean" tunnel="yes"/>
      <xsl:param name="stamp-root-element-with-attr-name" as="xs:string?"/>
      <xsl:param name="stamp-root-element-with-attr-val" as="xs:string?"/>
      <xsl:variable name="this-base-uri" select="tan:base-uri(.)" as="xs:anyURI?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not(exists(@base-uri))">
            <xsl:attribute name="base-uri" select="$this-base-uri"/>
         </xsl:if>
         <xsl:if
            test="string-length($stamp-root-element-with-attr-name) gt 0 and string-length($stamp-root-element-with-attr-val) gt 0">
            <xsl:attribute name="{$stamp-root-element-with-attr-name}"
               select="$stamp-root-element-with-attr-val"/>
         </xsl:if>
         <xsl:if test="$leave-breadcrumbs = true()">
            <xsl:attribute name="q" select="1"/>
         </xsl:if>

         <xsl:apply-templates mode="#current">
            <xsl:with-param name="base-uri" select="$this-base-uri" tunnel="yes"/>
            <xsl:with-param name="leave-breadcrumbs" select="$leave-breadcrumbs" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="node()" mode="first-stamp">
      <xsl:param name="base-uri" as="xs:anyURI?" tunnel="yes"/>
      <xsl:param name="leave-breadcrumbs" as="xs:boolean" tunnel="yes"/>
      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$leave-breadcrumbs = true()">
            <xsl:attribute name="q"
               select="count(preceding-sibling::*[name() = $this-element-name]) + 1"/>
         </xsl:if>
         <xsl:if test="@href">
            <xsl:variable name="new-href" select="resolve-uri(@href, $base-uri)"/>
            <xsl:attribute name="href" select="$new-href"/>
            <xsl:if test="not($new-href = @href)">
               <xsl:attribute name="orig-href" select="@href"/>
            </xsl:if>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:strip-duplicates" as="document-node()*">
      <!-- Input: any documents, sequence of strings of element names -->
      <!-- Output: the same documents after removing duplicate elements whose names match the second parameter. -->
      <xsl:param name="tan-docs" as="document-node()*"/>
      <xsl:param name="element-names-to-check" as="xs:string*"/>
      <xsl:for-each select="$tan-docs">
         <xsl:copy>
            <xsl:apply-templates mode="strip-duplicates">
               <xsl:with-param name="element-names-to-check" select="$element-names-to-check"
                  tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="tan:* | tei:*" mode="strip-duplicates">
      <xsl:param name="element-names-to-check" as="xs:string*" tunnel="yes"/>
      <xsl:choose>
         <xsl:when test="name(.) = $element-names-to-check">
            <xsl:if
               test="
                  every $i in preceding-sibling::*
                     satisfies not(deep-equal(., $i))">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:apply-templates mode="#current"/>
               </xsl:copy>
            </xsl:if>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="tan:name" mode="prep-tan-key">
      <xsl:variable name="this-name" select="text()"/>
      <xsl:variable name="this-name-common" select="tan:normalize-text($this-name, true())"/>
      <xsl:copy-of select="."/>
      <xsl:if test="not($this-name = $this-name-common)">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <!-- we add @common, to distinguish it from the master, for error checking -->
            <xsl:attribute name="common"/>
            <xsl:copy-of select="*"/>
            <xsl:value-of select="$this-name-common"/>
         </xsl:copy>
      </xsl:if>
   </xsl:template>

   <xsl:template match="*[@include]" mode="resolve-attr-include">
      <xsl:param name="tan-doc-ids-checked-so-far" as="xs:string*" tunnel="yes"/>
      <xsl:param name="docs-whence-inclusion-resolved" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-element-name" select="name($this-element)"/>
      <xsl:variable name="these-inclusion-idrefs"
         select="tokenize(tan:normalize-text(@include), ' ')"/>
      <xsl:variable name="relevant-docs"
         select="$docs-whence-inclusion-resolved[*/@inclusion = $these-inclusion-idrefs]"
         as="document-node()*"/>
      <xsl:variable name="relevant-doc-ids" select="$relevant-docs/*/@id"/>
      <xsl:variable name="relevant-elements-to-include"
         select="$relevant-docs//*[name() = $this-element-name][not(ancestor::*[name() = $this-element-name])]"/>
      <xsl:variable name="relevant-elements-to-include-prepended"
         select="
            for $i in $relevant-elements-to-include
            return
               tan:prepend-id-or-idrefs($i, root($i)/*/@inclusion)"/>
      <xsl:variable name="attr-in-this-element-to-suppress" select="'include'"/>
      <xsl:variable name="attr-in-included-element-to-suppress"
         select="('ed-when', 'ed-who', 'which')"/>
      <xsl:choose>
         <xsl:when test="not(exists($relevant-docs))">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="tan:error('tan05')"/>
            </xsl:copy>
         </xsl:when>
         <xsl:when test="exists($relevant-docs/(tan:error, tan:fatal))">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$relevant-docs/*"/>
            </xsl:copy>
         </xsl:when>
         <xsl:when test="$tan-doc-ids-checked-so-far = $relevant-doc-ids">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="tan:error('inc03')"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:for-each select="$relevant-elements-to-include">
               <xsl:copy>
                  <xsl:copy-of
                     select="$this-element/@*[not(name() = $attr-in-this-element-to-suppress)]"/>
                  <xsl:for-each
                     select="$this-element/@*[name() = $attr-in-this-element-to-suppress]">
                     <xsl:attribute name="orig-{name()}" select="."/>
                  </xsl:for-each>
                  <!-- We bring from the inclusion document only those attributes that have any meaning in the new document (e.g., @ed-when and @ed-who are skipped), and those attributes that are ambiguous outside their host context are normalized (@n and @ref are converted to Arabic numerals) -->
                  <xsl:copy-of select="@*[not(name() = $attr-in-included-element-to-suppress)]"/>
                  <xsl:for-each select="@*[name() = $attr-in-included-element-to-suppress]">
                     <xsl:attribute name="orig-{name()}" select="."/>
                  </xsl:for-each>
                  <xsl:copy-of select="node()"/>
                  <!-- We do not apply templates again, because every */@include is (or should be) empty -->
               </xsl:copy>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:function name="tan:prepend-id-or-idrefs" as="element()*">
      <!-- Input: any elements with @xml:id or an attribute that points to an element with an @xml:id value; some string that should be prepended to every value of every attribute found-->
      <!-- Output: the same elements, but with each value prepended with the string and a double hyphen -->
      <!-- This function is critical for disambiguating during the inclusion process. -->
      <xsl:param name="elements-with-id-or-id-refs" as="element()"/>
      <xsl:param name="string-to-prepend" as="xs:string?"/>
      <xsl:apply-templates select="$elements-with-id-or-id-refs" mode="prepend-id-or-idrefs">
         <xsl:with-param name="string-to-prepend" select="$string-to-prepend" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   <xsl:template match="*" mode="prepend-id-or-idrefs">
      <xsl:param name="string-to-prepend" as="xs:string" tunnel="yes"/>
      <xsl:copy>
         <xsl:for-each select="@*">
            <xsl:variable name="this-name" select="name(.)"/>
            <xsl:choose>
               <xsl:when test="$this-name = ($id-idrefs//@attribute, 'xml:id')">
                  <xsl:variable name="vals" as="xs:string*">
                     <xsl:analyze-string select="." regex="\s+">
                        <xsl:non-matching-substring>
                           <xsl:value-of select="concat($string-to-prepend, '--', .)"/>
                        </xsl:non-matching-substring>
                     </xsl:analyze-string>
                  </xsl:variable>
                  <xsl:attribute name="{$this-name}" select="string-join($vals, ' ')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:analyze-elements-with-numeral-attributes" as="element()*">
      <!-- Input: any sequence of elements that contain (either in themselves or their descendants) @n, @old, or @ref; an optional string indicating an attribute whose tokenized value should be used as a basis for grouping the results; two booleans indicating whether only ambiguous types should be checked and whether the analysis should be performed only shallowly (i.e., not on any descendants of the input elements) -->
      <!-- Output: zero or more <ns>s (one per group, and with @type-i, @type-a, and type-i-or-a if only ambiguous types are intended), each with one or more <n>s (one per atomic value in @n or @ref of the group picked), each with one or more <val type="[i, 1, 1a, a, a1, or $, depending on the type]">[VALUE]</val>, where VALUE is what the item is when converted. If the item is @ref then any non-word strings that are used to separate refs or @n values (hyphen, comma, etc.) are retained in <sep>s. -->
      <!-- This function is used to help other functions determine whether there is an error, or how ambiguous numerals should be interpreted -->
      <xsl:param name="elements" as="node()*"/>
      <xsl:param name="group-by-what-attr-value" as="xs:string?"/>
      <xsl:param name="analyze-only-ambiguous-types" as="xs:boolean"/>
      <xsl:param name="shallow-analysis" as="xs:boolean"/>
      <xsl:variable name="elements-to-analyze"
         select="
            (if ($shallow-analysis = true()) then
               $elements
            else
               $elements/descendant-or-self::*)[@ref or @n or @old]"/>
      <xsl:for-each-group select="$elements-to-analyze"
         group-by="
            if (string-length($group-by-what-attr-value) gt 0) then
               tokenize(tan:normalize-text(@*[name() = $group-by-what-attr-value]), '\W+')
            else
               true()">
         <xsl:variable name="analysis" as="element()*">
            <xsl:for-each select="current-group()/(@ref, @n, @old)">
               <xsl:analyze-string select="." regex="[^\w\?]+">
                  <xsl:matching-substring>
                     <sep>
                        <xsl:value-of select="."/>
                     </sep>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <xsl:variable name="this-n-norm" select="tan:normalize-text(.)"/>
                     <xsl:variable name="help-flag"
                        select="
                           if (matches(., $help-trigger-regex)) then
                              $help-trigger
                           else
                              ()"/>
                     <n>
                        <xsl:choose>
                           <xsl:when test="$analyze-only-ambiguous-types = false()">
                              <xsl:choose>
                                 <xsl:when test="matches($this-n-norm, $n-type-pattern[2], 'i')">
                                    <val type="{$n-type[2]}">
                                       <xsl:value-of select="."/>
                                    </val>
                                 </xsl:when>
                                 <xsl:otherwise>
                                    <xsl:if test="matches($this-n-norm, $n-type-pattern[1], 'i')">
                                       <val type="{$n-type[1]}">
                                          <xsl:value-of
                                             select="concat(tan:rom-to-int($this-n-norm), $help-flag)"
                                          />
                                       </val>
                                    </xsl:if>
                                    <xsl:if test="matches($this-n-norm, $n-type-pattern[3], 'i')">
                                       <val type="{$n-type[3]}">
                                          <xsl:value-of
                                             select="concat(replace($this-n-norm, '\D+', ''), $separator-hierarchy-minor, tan:aaa-to-int(replace($this-n-norm, '\d+', '')), $help-flag)"
                                          />
                                       </val>
                                    </xsl:if>
                                    <xsl:if test="matches($this-n-norm, $n-type-pattern[4], 'i')">
                                       <val type="{$n-type[4]}">
                                          <xsl:value-of
                                             select="concat(tan:aaa-to-int($this-n-norm), $help-flag)"
                                          />
                                       </val>
                                    </xsl:if>
                                    <xsl:if test="matches($this-n-norm, $n-type-pattern[5], 'i')">
                                       <val type="{$n-type[5]}">
                                          <xsl:value-of
                                             select="concat(tan:aaa-to-int(replace($this-n-norm, '\d+', '')), $separator-hierarchy-minor, replace($this-n-norm, '\D+', ''), $help-flag)"
                                          />
                                       </val>
                                    </xsl:if>
                                    <val type="$">
                                       <xsl:value-of select="lower-case(.)"/>
                                    </val>
                                 </xsl:otherwise>
                              </xsl:choose>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:if test="matches($this-n-norm, $n-type-pattern[1], 'i')">
                                 <val type="{$n-type[1]}">
                                    <xsl:value-of
                                       select="concat(tan:rom-to-int($this-n-norm), $help-flag)"/>
                                 </val>
                              </xsl:if>
                              <xsl:if test="matches($this-n-norm, $n-type-pattern[4], 'i')">
                                 <val type="{$n-type[4]}">
                                    <xsl:value-of
                                       select="concat(tan:aaa-to-int($this-n-norm), $help-flag)"/>
                                 </val>
                              </xsl:if>
                              <val type="$">
                                 <xsl:value-of select="."/>
                              </val>
                           </xsl:otherwise>
                        </xsl:choose>
                     </n>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:for-each>
         </xsl:variable>
         <xsl:if test="exists($analysis)">
            <ns>
               <xsl:if test="string-length($group-by-what-attr-value) gt 0">
                  <xsl:attribute name="{$group-by-what-attr-value}" select="current-grouping-key()"
                  />
               </xsl:if>
               <xsl:if test="$analyze-only-ambiguous-types = true()">
                  <xsl:variable name="ambiguous-analyses"
                     select="$analysis[tan:val/@type = $n-type[1] and tan:val/@type = $n-type[4]]"/>
                  <xsl:variable name="ambiguous-analyses-count" select="count($ambiguous-analyses)"/>
                  <xsl:variable name="this-i-count"
                     select="count($analysis[tan:val/@type = $n-type[1]]) - $ambiguous-analyses-count"/>
                  <xsl:variable name="this-a-count"
                     select="count($analysis[tan:val/@type = $n-type[4]]) - $ambiguous-analyses-count"/>
                  <xsl:attribute name="type-i" select="$this-i-count"/>
                  <xsl:attribute name="type-a" select="$this-a-count"/>
                  <xsl:attribute name="type-i-or-a" select="$ambiguous-analyses-count"/>
                  <xsl:attribute name="type-i-or-a-is-probably">
                     <xsl:choose>
                        <xsl:when test="$this-i-count lt 1 and $this-a-count gt 0">a</xsl:when>
                        <xsl:when test="$this-a-count lt 1 and $this-i-count gt 0">i</xsl:when>
                        <xsl:otherwise>
                           <xsl:choose>
                              <xsl:when
                                 test="
                                    every $i in $ambiguous-analyses/tan:val[@type = '$']
                                       satisfies string-length($i) le 1"
                                 >a</xsl:when>
                              <xsl:otherwise>i</xsl:otherwise>
                           </xsl:choose>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:attribute>
               </xsl:if>
               <xsl:copy-of select="$analysis"/>
            </ns>
         </xsl:if>
      </xsl:for-each-group>
   </xsl:function>

   <xsl:template match="tei:*[@which] | tan:*[@which]" mode="resolve-keyword">
      <xsl:param name="extra-keys" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="element-name" select="name(.)"/>
      <xsl:variable name="this-which" select="tan:normalize-text(@which, true())"/>
      <xsl:variable name="help-requested" select="matches(@which, $help-trigger-regex)"/>
      <xsl:variable name="attr-in-key-element-to-suppress" select="('group')" as="xs:string*"/>
      <xsl:variable name="valid-definitions"
         select="tan:get-attr-which-definition(., $extra-keys, ())"/>
      <xsl:variable name="definition-matches" as="element()*"
         select="$valid-definitions[tan:name[normalize-space(.) = $this-which]]"/>
      <xsl:variable name="close-matches"
         select="$valid-definitions[tan:name[matches(., $this-which)]]"/>
      <xsl:variable name="best-matches"
         select="
            if (exists($close-matches))
            then
               $close-matches
            else
               $valid-definitions"/>
      <xsl:variable name="definition-groups"
         select="normalize-space(string-join(($definition-matches/@group, $definition-matches/ancestor::tan:group/@type), ' '))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$definition-matches/tan:token-definition/@regex"/>
         <xsl:copy-of
            select="$definition-matches/@*[not(name() = $attr-in-key-element-to-suppress)]"/>
         <xsl:for-each select="$definition-matches/@*[name() = $attr-in-key-element-to-suppress]">
            <xsl:attribute name="orig-{name()}" select="."/>
         </xsl:for-each>
         <xsl:if test="exists($definition-groups)">
            <!-- although strictly not necessary for validation, the <group> of a keyword is enormously helpful in later processing, so the name of each group is included here -->
            <xsl:attribute name="orig-group" select="$definition-groups"/>
         </xsl:if>
         <xsl:if test="not(exists($definition-matches))">
            <xsl:variable name="this-message" as="xs:string*">
               <xsl:for-each select="$best-matches">
                  <xsl:value-of select="tan:name[1]"/>
                  <xsl:if test="tan:name[2]">
                     <xsl:value-of
                        select="concat(' (', string-join(tan:name[position() gt 1], '; '), ')')"/>
                  </xsl:if>
               </xsl:for-each>
            </xsl:variable>
            <xsl:copy-of
               select="tan:error('whi01', concat('Try: ', string-join($this-message, '; ')), $best-matches)"
            />
         </xsl:if>
         <xsl:if test="count($definition-matches) gt 1">
            <xsl:copy-of select="tan:error('whi02')"/>
         </xsl:if>
         <xsl:if test="not(exists($valid-definitions))">
            <xsl:copy-of select="tan:error('whi03')"/>
         </xsl:if>
         <xsl:if test="($help-requested = true()) and exists($definition-matches)">
            <xsl:variable name="this-message" as="xs:string*">
               <xsl:text>Help: </xsl:text>
               <xsl:for-each select="$definition-matches">
                  <xsl:text>ITEM </xsl:text>
                  <xsl:value-of select="tan:name[1]"/>
                  <xsl:text> </xsl:text>
                  <xsl:if test="tan:name[2]">
                     <xsl:value-of
                        select="concat('(', string-join(tan:name[position() gt 1], '; '), ') ')"/>
                  </xsl:if>
                  <xsl:text>description: </xsl:text>
                  <xsl:value-of select="tan:desc"/>
               </xsl:for-each>
            </xsl:variable>
            <xsl:copy-of select="tan:help($this-message, $valid-definitions)"/>
         </xsl:if>
         <xsl:copy-of select="$definition-matches/*[not(self::tan:token-definition)]"/>
      </xsl:copy>
   </xsl:template>
   <xsl:function name="tan:resolve-keyword" as="item()*">
      <!-- Input: any items; any extra keys -->
      <!-- Output: the same items, but with elements with @which expanded into their full form, using the predefined TAN vocabulary and the extra keys supplied -->
      <xsl:param name="items" as="item()*"/>
      <xsl:param name="extra-keys" as="document-node()*"/>
      <xsl:apply-templates select="$items" mode="resolve-keyword">
         <xsl:with-param name="extra-keys" select="$extra-keys" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>


   <xsl:template match="*[@href]" mode="resolve-href">
      <xsl:param name="special-base-uri" as="xs:string?" tunnel="yes"/>
      <xsl:variable name="this-base-uri"
         select="
            if (exists($special-base-uri)) then
               $special-base-uri
            else
               tan:base-uri(.)"/>
      <xsl:variable name="resolved-href" select="resolve-uri(@href, $this-base-uri)"/>
      <xsl:copy>
         <xsl:copy-of select="@* except @href"/>
         <xsl:attribute name="href">
            <xsl:value-of select="$resolved-href"/>
         </xsl:attribute>
         <xsl:if test="not(@href = $resolved-href)">
            <xsl:attribute name="orig-href" select="@href"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="comment() | processing-instruction()"
      mode="strip-all-attributes-except strip-specific-attributes strip-text copy-of-except stamp-element-id">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="*" mode="strip-all-attributes-except">
      <xsl:param name="attributes-to-keep" as="xs:string+" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*[name(.) = $attributes-to-keep]"/>
         <xsl:apply-templates mode="strip-all-attributes-except"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*" mode="strip-specific-attributes">
      <xsl:param name="attributes-to-strip" as="xs:string+" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*[not(name(.) = $attributes-to-strip)]"/>
         <xsl:apply-templates mode="strip-specific-attributes"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*" mode="strip-text">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="* | comment() | processing-instruction()" mode="strip-text"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:copy-of" as="item()*">
      <!-- Input: any document fragment, and an optional integer specifying the depth of copy requested -->
      <!-- Output: a copy of the fragment to the depth specified -->
      <!-- This function depends upon the full version of tan:copy-of-except(); it is particularly useful for diagnostics, e.g., retrieving a long document's root element and its children, without descendants -->
      <xsl:param name="doc-fragment" as="item()*"/>
      <xsl:param name="exclude-elements-beyond-what-depth" as="xs:integer?"/>
      <xsl:copy-of
         select="tan:copy-of-except($doc-fragment, (), (), (), $exclude-elements-beyond-what-depth, ())"
      />
   </xsl:function>
   <xsl:function name="tan:copy-of-except" as="item()*">
      <!-- short version of the full function, below -->
      <xsl:param name="doc-fragment" as="item()*"/>
      <xsl:param name="exclude-elements-named" as="xs:string*"/>
      <xsl:param name="exclude-attributes-named" as="xs:string*"/>
      <xsl:param name="exclude-elements-with-attributes-named" as="xs:string*"/>
      <xsl:copy-of
         select="tan:copy-of-except($doc-fragment, $exclude-elements-named, $exclude-attributes-named, $exclude-elements-with-attributes-named, (), ())"
      />
   </xsl:function>
   <xsl:function name="tan:copy-of-except" as="item()*">
      <!-- Input: any document fragment; sequences of strings specifying names of elements to exclude, names of attributes to exclude, and names of attributes whose parent elements should be excluded; an integer beyond which depth copies should not be made -->
      <!-- Output: the same fragment, filtered -->
      <!-- This function was written primarily to service the merge of TAN-A-div sources, where realigned divs could be extracted from their source documents -->
      <xsl:param name="doc-fragment" as="item()*"/>
      <xsl:param name="exclude-elements-named" as="xs:string*"/>
      <xsl:param name="exclude-attributes-named" as="xs:string*"/>
      <xsl:param name="exclude-elements-with-attributes-named" as="xs:string*"/>
      <xsl:param name="exclude-elements-beyond-what-depth" as="xs:integer?"/>
      <xsl:param name="shallow-skip-elements-named" as="xs:string*"/>
      <xsl:apply-templates select="$doc-fragment" mode="copy-of-except">
         <xsl:with-param name="exclude-elements-named" as="xs:string*"
            select="$exclude-elements-named" tunnel="yes"/>
         <xsl:with-param name="exclude-attributes-named" as="xs:string*"
            select="$exclude-attributes-named" tunnel="yes"/>
         <xsl:with-param name="exclude-elements-with-attributes-named" as="xs:string*"
            select="$exclude-elements-with-attributes-named" tunnel="yes"/>
         <xsl:with-param name="exclude-elements-beyond-what-depth"
            select="$exclude-elements-beyond-what-depth" tunnel="yes"/>
         <xsl:with-param name="current-depth" select="0"/>
         <xsl:with-param name="shallow-skip-elements-named" select="$shallow-skip-elements-named"
            tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   <xsl:template match="*" mode="copy-of-except">
      <xsl:param name="exclude-elements-named" as="xs:string*" tunnel="yes"/>
      <xsl:param name="exclude-attributes-named" as="xs:string*" tunnel="yes"/>
      <xsl:param name="exclude-elements-with-attributes-named" as="xs:string*" tunnel="yes"/>
      <xsl:param name="exclude-elements-beyond-what-depth" as="xs:integer?" tunnel="yes"/>
      <xsl:param name="shallow-skip-elements-named" as="xs:string*" tunnel="yes"/>
      <xsl:param name="current-depth" as="xs:integer?"/>
      <xsl:choose>
         <xsl:when test="name() = $exclude-elements-named"/>
         <xsl:when test="name() = $shallow-skip-elements-named">
            <xsl:apply-templates mode="#current">
               <xsl:with-param name="current-depth"
                  select="
                     if (exists($current-depth)) then
                        $current-depth + 1
                     else
                        ()"
               />
            </xsl:apply-templates>
         </xsl:when>
         <xsl:when
            test="
               not(some $i in @*
                  satisfies name($i) = $exclude-elements-with-attributes-named)
               and not($current-depth ge $exclude-elements-beyond-what-depth)">
            <xsl:copy>
               <xsl:copy-of select="@*[not(name() = $exclude-attributes-named)]"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="current-depth"
                     select="
                        if (exists($current-depth)) then
                           $current-depth + 1
                        else
                           ()"
                  />
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <xsl:function name="tan:pluck" as="item()*">
      <!-- Input: any document fragment or element; a number indicating a level in the hierarchy of the fragment; a boolean indicating whether leaf elements that fall short of the previous parameter should be included -->
      <!-- Output: the fragment of the tree that is beyond the point indicated, and perhaps (depending upon the third parameter) with other leafs that are not quite at that level -->
      <!-- This function was written primarily to serve tan:convert-ref-to-div-fragment(), to get a slice of divs that correspond to a range, without the ancestry of those divs -->
      <xsl:param name="fragment" as="item()*"/>
      <xsl:param name="pluck-beyond-level" as="xs:integer"/>
      <xsl:param name="keep-short-branch-leaves" as="xs:boolean"/>
      <xsl:apply-templates select="$fragment" mode="pluck">
         <xsl:with-param name="prune-above-level" select="$pluck-beyond-level" tunnel="yes"/>
         <xsl:with-param name="keep-short-branch-leaves" select="$keep-short-branch-leaves"
            tunnel="yes"/>
         <xsl:with-param name="currently-at" select="1"/>
      </xsl:apply-templates>
   </xsl:function>
   <xsl:template match="*" mode="pluck">
      <xsl:param name="currently-at" as="xs:integer"/>
      <xsl:param name="prune-above-level" as="xs:integer" tunnel="yes"/>
      <xsl:param name="keep-short-branch-leaves" as="xs:boolean" tunnel="yes"/>
      <xsl:choose>
         <xsl:when test="$prune-above-level = $currently-at">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:when test="not(exists(*))">
            <xsl:if test="$keep-short-branch-leaves = true()">
               <xsl:copy-of select="."/>
            </xsl:if>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates mode="#current">
               <xsl:with-param name="currently-at" select="$currently-at + 1"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="text()" mode="pluck">
      <xsl:if test="matches(., '\S')">
         <xsl:value-of select="."/>
      </xsl:if>
   </xsl:template>
   <xsl:template match="comment() | processing-instruction()" mode="pluck"/>

   <xsl:function name="tan:shallow-copy" as="element()*">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="elements" as="element()*"/>
      <xsl:copy-of select="tan:shallow-copy($elements, true())"/>
   </xsl:function>
   <xsl:function name="tan:shallow-copy" as="element()*">
      <!-- Input: any document fragment; boolean indicating whether attributes should be kept -->
      <!-- Output: a shallow copy of the fragment, perhaps with attributes -->
      <xsl:param name="elements" as="element()*"/>
      <xsl:param name="keep-attributes" as="xs:boolean"/>
      <xsl:for-each select="$elements">
         <xsl:copy>
            <xsl:if test="$keep-attributes = true()">
               <xsl:copy-of select="@*"/>
            </xsl:if>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:value-of" as="xs:string?">
      <!-- Input: any sequence of items -->
      <!-- Output: the value of each item -->
      <!-- Puts <xsl:value-of/> into a concise function -->
      <xsl:param name="items" as="item()*"/>
      <xsl:value-of select="$items"/>
   </xsl:function>

   <xsl:function name="tan:stamp-id" as="item()*">
      <!-- 2-parameter form of the fuller version, below -->
      <xsl:param name="nodes" as="item()*"/>
      <xsl:param name="names-of-elements-to-imprint-with-gloss-id" as="xs:string*"/>
      <xsl:copy-of select="tan:stamp-id($nodes, $names-of-elements-to-imprint-with-gloss-id, 'id')"
      />
   </xsl:function>
   <xsl:function name="tan:stamp-id" as="item()*">
      <!-- Input: any element or document fragment, one or more strings of the names of elements that should be imprinted with @id -->
      <!-- Output: the same, with any elements whose names match the input with @id added, consisting of the name of the element appended with the number of its position relative to all preceding elements of the same name. -->
      <xsl:param name="nodes" as="item()*"/>
      <xsl:param name="names-of-elements-to-imprint-with-gloss-id" as="xs:string*"/>
      <xsl:param name="name-of-attribute-to-hold-id" as="xs:string?"/>
      <xsl:apply-templates select="$nodes" mode="stamp-element-id">
         <xsl:with-param name="names-of-elements-to-imprint-with-id"
            select="$names-of-elements-to-imprint-with-gloss-id" tunnel="yes"/>
         <xsl:with-param name="name-of-attribute-to-hold-id" select="$name-of-attribute-to-hold-id"
            tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   <xsl:template match="*" mode="stamp-element-id">
      <xsl:param name="names-of-elements-to-imprint-with-id" tunnel="yes" as="xs:string*"/>
      <xsl:param name="name-of-attribute-to-hold-id" tunnel="yes" as="xs:string"/>
      <xsl:variable name="this-name" select="name(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$this-name = $names-of-elements-to-imprint-with-id">
            <xsl:variable name="prev-qty"
               select="count(preceding::*[name(.) = $names-of-elements-to-imprint-with-id]) + 1"/>
            <xsl:attribute name="{$name-of-attribute-to-hold-id}"
               select="concat('gloss', string($prev-qty))"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>

   </xsl:template>

</xsl:stylesheet>
