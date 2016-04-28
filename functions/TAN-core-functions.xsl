<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan fn tei functx" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>April 28, 2016</xd:p>
         <xd:p>Variables, functions, and templates for all TAN files. Written primarily for
            Schematron validation, but suitable for general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="regex/regex-ext-tan-functions.xsl"/>

   <!-- Core TAN constants expressed as global variables -->

   <xsl:variable name="regex-escaping-characters" as="xs:string"
      select="'[\.\[\]\\\|\-\^\$\?\*\+\{\}\(\)]'"/>
   <xsl:variable name="quot" select="'&quot;'"/>
   <xsl:variable name="apos" select='"&apos;"'/>
   <xsl:variable name="empty-doc" as="document-node()">
      <xsl:document/>
   </xsl:variable>

   <xsl:variable name="TAN-namespace" select="'tag:textalign.net,2015'"/>
   <xsl:variable name="id-idrefs" select="doc('TAN-idrefs.xml')"/>
   <xsl:variable name="errors" select="doc('TAN-errors.xml')"/>
   <xsl:variable name="tokenization-errors"
      select="$errors//tan:group[tokenize(@affects-element, '\s+') = 'token-definition']//tan:error"
      as="xs:string*"/>
   <xsl:variable name="inclusion-errors"
      select="$errors//tan:group[@affects-attribute = 'include']/tan:error" as="xs:string*"/>

   <xsl:param name="help-trigger" select="'???'"/>
   <xsl:variable name="help-trigger-regex" select="tan:escape($help-trigger)"/>
   <xsl:function name="tan:help-requested" as="xs:boolean">
      <xsl:param name="node" as="node()"/>
      <xsl:value-of
         select="
            if ((some $i in ($node, $node/@*)
               satisfies matches($i, $help-trigger-regex)) or $node/@help) then
               true()
            else
               false()"
      />
   </xsl:function>
   <xsl:param name="separator-hierarchy" select="' '" as="xs:string"/>
   <xsl:variable name="separator-hierarchy-regex" select="' '" as="xs:string"/>

   <xsl:param name="schema-version-major" select="1"/>
   <xsl:param name="schema-version-minor" select="'dev'"/>

   <xsl:key name="item-via-affects-element" match="tan:item"
      use="tokenize((ancestor-or-self::*[@affects-element])[1]/@affects-element, '\s+')"/>
   <xsl:variable name="TAN-keywords" as="element()*">
      <xsl:variable name="TAN-keyword-files" as="document-node()+"
         select="
            doc('../TAN-key/div-types.TAN-key.xml'), doc('../TAN-key/key-types.TAN-key.xml'), doc('../TAN-key/relationships.TAN-key.xml'),
            doc('../TAN-key/normalizations.TAN-key.xml'), doc('../TAN-key/token-definitions.TAN-key.xml'),
            doc('../TAN-key/rights.TAN-key.xml'), doc('../TAN-key/features.TAN-key.xml'), doc('../TAN-key/modals.TAN-key.xml')"/>
      <xsl:apply-templates mode="resolve-href" select="$TAN-keyword-files/tan:TAN-key/tan:body"/>
   </xsl:variable>
   <xsl:variable name="relationship-keywords-for-tan-versions"
      select="tan:get-keywords('relationship', 'TAN version')"/>
   <xsl:variable name="relationship-keywords-for-tan-editions"
      select="tan:get-keywords('relationship', 'TAN edition')"/>
   <xsl:variable name="relationship-keywords-for-tan-class-1-editions"
      select="tan:get-keywords('relationship', 'TAN class 1')"/>
   <xsl:variable name="relationship-keywords-for-tan-files"
      select="tan:get-keywords('relationship', 'TAN files')"/>
   <xsl:variable name="relationship-keywords-all" select="tan:get-keywords('relationship')"/>
   <xsl:variable name="private-keywords" select="$keys-1st-da/tan:TAN-key/tan:body"/>
   <xsl:variable name="all-keywords" select="$TAN-keywords, $private-keywords"/>

   <xsl:variable name="root" select="/"/>
   <xsl:variable name="self-resolved" select="tan:resolve-doc($root)" as="document-node()"/>
   <xsl:variable name="head" select="$self-resolved/*/tan:head"/>
   <xsl:variable name="body" select="$self-resolved/*/(tan:body, tei:text/tei:body)"/>

   <xsl:variable name="inclusions-1st-da" select="tan:get-inclusions-1st-da(/)"/>
   <xsl:variable name="keys-1st-la"
      select="
         for $i in (/*/tan:head/tan:key, $inclusions-1st-da/*/tan:head/tan:key)
         return
            tan:first-loc-available($i, base-uri($i))"/>
   <xsl:variable name="keys-1st-da" select="tan:get-doc($keys-1st-la)"/>
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

   <xsl:variable name="class-1-root-names" select="('TAN-T', 'TEI')"/>
   <xsl:variable name="class-2-root-names" select="('TAN-A-div', 'TAN-A-tok', 'TAN-LM')"/>
   <xsl:variable name="class-3-root-names" select="('TAN-R-mor', 'TAN-key', 'TAN-rdf')"/>
   <xsl:variable name="all-root-names"
      select="$class-1-root-names, $class-2-root-names, $class-3-root-names"/>

   <xsl:variable name="elements-that-must-always-refer-to-tan-files"
      select="
         ('morphology',
         'inclusion',
         'key')"/>
   <xsl:variable name="tag-urn-regex-pattern"
      select="'tag:([\-a-zA-Z0-9._%+]+@)?[\-a-zA-Z0-9.]+\.[A-Za-z]{2,4},\d{4}(-(0\d|1[0-2]))?(-([0-2]\d|3[01]))?:\S+'"/>

   <xsl:variable name="token-definitions-reserved" select="$TAN-keywords//tan:token-definition"/>

   <!-- If one wishes to see if the an entire string matches the following patterns defined by these 
        variables, they must appear between the regular expression anchors ^ and $. -->
   <xsl:variable name="roman-numeral-pattern"
      select="'m{0,4}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})'"/>
   <xsl:variable name="letter-numeral-pattern"
      select="'a+|b+|c+|d+|e+|f+|g+|h+|i+|j+|k+|l+|m+|n+|o+|p+|q+|r+|s+|t+|u+|v+|w+|x+|y+|z+'"/>

   <xsl:variable name="context-1st-da-locations" as="xs:string*"
      select="tan:first-loc-available($head/tan:see-also[tan:relationship/@which = 'context'])"/>
   <xsl:variable name="context-1st-da" select="tan:get-doc($context-1st-da-locations)"/>

   <!-- CONTEXT INDEPENDENT FUNCTIONS -->
   <xsl:function name="tan:get-doc" as="document-node()*">
      <xsl:param name="uris" as="xs:string*"/>
      <xsl:copy-of
         select="
            for $i in $uris
            return
               if ($i = '') then
                  $empty-doc
               else
                  tan:resolve-doc(document($i))"
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

   <xsl:function name="tan:analyze-string" as="element()?">
      <!-- Input: single string and a <tan:token-definition>. 
         Output: <tan:result> containing a sequence of elements, <tan:tok> and <tan:non-tok>,
        corresponding to fn:match and fn:non-match for fn:analyze-string() -->
      <xsl:param name="text" as="xs:string?"/>
      <xsl:param name="token-definition" as="element()?"/>
      <xsl:variable name="regex"
         select="($token-definition/@regex, $token-definitions-reserved[1]/@regex)[1]"/>
      <xsl:variable name="flags" select="$token-definition/@flags"/>
      <xsl:variable name="results">
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
      <xsl:apply-templates select="$results" mode="count-tokens"/>
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

   <xsl:function name="tan:doc-version">
      <xsl:param name="tan-doc" as="document-node()*"/>
      <xsl:copy-of
         select="
            for $i in $tan-doc
            return
               tan:most-recent-dateTime($i//(@when | @ed-when | @when-accessed))"
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
      <xsl:copy-of
         select="
            for $i in $strings
            return
               normalize-space(replace($i, '([\(\),\|])', ' $1 '))"
      />
   </xsl:function>
   <xsl:function name="tan:normalize-text" as="xs:string*">
      <!-- Used to normalize a string before being checked. Removes any help requested and normalizes space -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:copy-of
         select="
            for $i in $text
            return
               normalize-space(replace($i, $help-trigger-regex, ''))"
      />
   </xsl:function>

   <!-- Functions that take regular expressions, to support TAN extensions -->
   <xsl:function name="tan:sequence-expand" as="xs:integer*">
      <!-- input: one string of concise TAN selectors (used by @poss, @chars, @segs), 
            and one integer defining the value of 'last'
            output: a sequence of numbers representing the positions selected, unsorted, and retaining
            duplicate values.
            E.g., ("2 - 4, last-5 - last, 36", 50) -> (2, 3, 4, 45, 46, 47, 48, 49, 50, 36)
            Errors will not be flagged; they must be processed by functions that invoke this one by
            checking for values less than zero or greater than the max. The one exception are ranges
            that ask for negative steps such as '4 - 2' or '1 - last-5' (where $max = 3), in which case 
            each item will be simply -1.
        -->
      <xsl:param name="selector" as="xs:string?"/>
      <xsl:param name="max" as="xs:integer?"/>
      <!-- first normalize syntax -->
      <xsl:variable name="pass-1"
         select="replace($selector, '(\d)\s*-\s*(last|all|max|\d)', '$1 - $2')"/>
      <xsl:variable name="pass-2" select="replace($pass-1, '(\d)\s+(\d)', '$1, $2')"/>
      <!-- replace 'last' with max value as string -->
      <xsl:variable name="selector-norm" select="replace($pass-2, 'last|all|max', string($max))"/>
      <xsl:variable name="seq-a" select="tokenize(normalize-space($selector-norm), '\s*,\s+')"/>
      <xsl:copy-of
         select="
            for $i in $seq-a
            return
               if (matches($i, ' - '))
               then
                  for $j in tan:string-subtract(tokenize($i, ' - ')[1]),
                     $k in tan:string-subtract(tokenize($i, ' - ')[2])
                  return
                     if ($j gt $k) then
                        for $l in ($k to $j)
                        return
                           -1
                     else
                        ($j to $k)
               else
                  tan:string-subtract($i)"/>

   </xsl:function>
   <xsl:function name="tan:string-subtract" as="xs:integer">
      <!-- input: string of pattern \d+(-\d+)?
        output: number giving the sum
        E.g., "50-5" -> 45 -->
      <xsl:param name="input" as="xs:string"/>
      <xsl:copy-of
         select="
            xs:integer(if (matches($input, '\d+-\d+'))
            then
               number(tokenize($input, '-')[1]) - (number(tokenize($input, '-')[2]))
            else
               number($input))"
      />
   </xsl:function>


   <xsl:function name="tan:escape" as="xs:string*">
      <!-- Input: any sequence of strings; Output: each string prepared for regular expression searches,
        i.e., with reserved characters escaped out. -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:copy-of
         select="
            for $i in $strings
            return
               replace($i, concat('(', $regex-escaping-characters, ')'), '\\$1')"
      />
   </xsl:function>

   <xsl:function name="tan:duplicate-values" as="item()*">
      <xsl:param name="sequence" as="item()*"/>
      <xsl:copy-of select="$sequence[index-of($sequence, .)[2]]"/>
   </xsl:function>

   <xsl:function name="tan:get-keywords" as="xs:string*">
      <xsl:param name="element-that-takes-attribute-which" as="item()"/>
      <xsl:variable name="element-name"
         select="
            if ($element-that-takes-attribute-which instance of xs:string) then
               $element-that-takes-attribute-which
            else
               name($element-that-takes-attribute-which)"/>
      <xsl:copy-of
         select="
            $private-keywords//tan:name[tokenize(ancestor::*[@affects-element][1]/@affects-element, '\s+') = $element-name],
            $TAN-keywords[tokenize(@affects-element, '\s+') = $element-name]//tan:item/tan:name"
      />
   </xsl:function>
   <xsl:function name="tan:get-keywords" as="xs:string*">
      <xsl:param name="element-that-takes-attribute-which" as="item()"/>
      <xsl:param name="group-name-filter" as="xs:string?"/>
      <xsl:variable name="element-name"
         select="
            if ($element-that-takes-attribute-which instance of xs:string) then
               $element-that-takes-attribute-which
            else
               name($element-that-takes-attribute-which)"/>
      <xsl:copy-of
         select="
            $private-keywords//tan:name[tokenize(ancestor::*[@affects-element][1]/@affects-element, '\s+') = $element-name][ancestor::tan:group/tan:name = $group-name-filter],
            $TAN-keywords[tokenize(@affects-element, '\s+') = $element-name]//tan:item/tan:name[ancestor::tan:group/tan:name = $group-name-filter]"
      />
   </xsl:function>

   <!-- CONTEXT DEPENDENT FUNCTIONS -->
   <xsl:function name="tan:first-loc-available" as="xs:string*">
      <!-- One-parameter version of the function below, using the default, $doc-uri
        -->
      <xsl:param name="elements-that-are-parents-of-locations" as="element()*"/>
      <xsl:copy-of
         select="tan:first-loc-available($elements-that-are-parents-of-locations, $doc-uri)"/>
   </xsl:function>
   <xsl:function name="tan:first-loc-available" as="xs:string*">
      <!-- Input: An element that contains one or more tan:location elements
            Output: the value of the first tan:location/@href to point to a document available, resolved
        -->
      <xsl:param name="elements-that-are-parents-of-locations" as="element()*"/>
      <xsl:param name="base-uri" as="xs:anyURI?"/>
      <xsl:variable name="norm-uri"
         select="
            if (not(exists($base-uri))) then
               $doc-uri
            else
               $base-uri"
         as="xs:anyURI"/>
      <xsl:for-each select="$elements-that-are-parents-of-locations">
         <xsl:copy-of
            select="
               (for $i in tan:location/@href,
                  $j in resolve-uri($i, $norm-uri)
               return
                  if (doc-available($j)) then
                     $j
                  else
                     ())[1]"
         />
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:get-inclusions-1st-da" as="document-node()*">
      <!-- one-parameter version of the function, the one to be most commonly used, feeds 
            into the multi-parameter version, below -->
      <xsl:param name="TAN-document" as="document-node()"/>
      <xsl:sequence
         select="tan:get-inclusions-1st-da($TAN-document, (), (), (), (), $doc-uri)[position() gt 1]"
      />
   </xsl:function>
   <xsl:function name="tan:get-inclusions-1st-da" as="document-node()*">
      <xsl:param name="TAN-document-currently-being-checked" as="document-node()"/>
      <xsl:param name="TAN-documents-yet-to-be-checked" as="document-node()*"/>
      <xsl:param name="TAN-included-documents-found-so-far" as="document-node()*"/>
      <xsl:param name="resolved-URLs-so-far" as="xs:string*"/>
      <xsl:param name="inclusion-IRIs-so-far" as="xs:string*"/>
      <xsl:param name="uri-of-document-currently-being-checked" as="xs:anyURI"/>
      <xsl:variable name="these-inclusions-1st-la"
         select="
            for $i in $TAN-document-currently-being-checked/*/tan:head/tan:inclusion[not(tan:IRI = $inclusion-IRIs-so-far)]
            return
               tan:first-loc-available($i, $uri-of-document-currently-being-checked)"/>
      <xsl:variable name="these-inclusions-1st-la-resolved"
         select="
            for $i in $these-inclusions-1st-la
            return
               resolve-uri($i, $uri-of-document-currently-being-checked)"/>
      <xsl:variable name="new-inclusions-1st-la"
         select="$these-inclusions-1st-la-resolved[not(. = $resolved-URLs-so-far)]"/>
      <xsl:variable name="new-inclusions-1st-da"
         select="
            for $i in $new-inclusions-1st-la
            return
               doc($i)"/>
      <xsl:variable name="which-docs-are-new"
         select="
            for $i in (1 to count($new-inclusions-1st-da))
            return
               if ($new-inclusions-1st-da[$i]/*/@id = $inclusion-IRIs-so-far) then
                  ()
               else
                  $i"/>
      <xsl:variable name="new-set-of-docs-to-be-checked"
         select="$TAN-documents-yet-to-be-checked, $new-inclusions-1st-da[position() = $which-docs-are-new]"/>
      <xsl:choose>
         <xsl:when test="empty($new-set-of-docs-to-be-checked)">
            <xsl:sequence select="$TAN-included-documents-found-so-far"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence
               select="
                  tan:get-inclusions-1st-da(
                  $new-set-of-docs-to-be-checked[1],
                  $new-set-of-docs-to-be-checked[position() gt 1],
                  ($TAN-included-documents-found-so-far, $TAN-document-currently-being-checked),
                  ($resolved-URLs-so-far, $new-inclusions-1st-la[position() = $which-docs-are-new]),
                  ($inclusion-IRIs-so-far, $new-inclusions-1st-da/*/@id),
                  base-uri($new-set-of-docs-to-be-checked[1]/*))"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:must-refer-to-external-tan-file" as="xs:boolean">
      <!-- Input: node in a TAN document. Output: boolean value indicating whether the node or its 
         parent names or refers to a TAN file. -->
      <xsl:param name="node" as="node()"/>
      <xsl:variable name="class-2-elements-that-must-always-refer-to-tan-files" select="('source')"/>
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

   <xsl:function name="tan:flatref" as="xs:string?">
      <!-- Input: div node in a TAN-T(EI) document. 
            Output: string value concatenating the reference values 
         from the topmost div ancestor to the node. -->
      <xsl:param name="node" as="element()?"/>
      <xsl:value-of
         select="
            string-join(for $i in $node/ancestor-or-self::*/@n
            return
               replace($i, '\W+', $separator-hierarchy), $separator-hierarchy)"
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
      <xsl:copy-of select="tan:resolve-doc($TAN-documents, (), false())"/>
   </xsl:function>
   <xsl:function name="tan:resolve-doc" as="document-node()*">
      <xsl:param name="TAN-documents" as="document-node()*"/>
      <xsl:param name="src-ids" as="xs:string*"/>
      <xsl:param name="leave-breadcrumbs" as="xs:boolean"/>
      <xsl:variable name="docs-breadcrumbed" as="document-node()*">
         <xsl:for-each select="$TAN-documents">
            <xsl:copy>
               <xsl:apply-templates mode="first-stamp">
                  <xsl:with-param name="leave-breadcrumbs" select="$leave-breadcrumbs"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$docs-breadcrumbed">
         <xsl:variable name="pos" select="position()"/>
         <xsl:variable name="included-elements" select=".//*[@include]"/>
         <xsl:variable name="names-of-included-elements"
            select="
               for $i in $included-elements
               return
                  name($i)"
            as="xs:string*"/>

         <xsl:choose>
            <xsl:when test="exists($included-elements)">
               <xsl:copy>
                  <!--<xsl:copy-of select="$doc-uri"/>-->
                  <!--<xsl:copy-of select="tan:include(.)"/>-->
                  <xsl:copy-of
                     select="tan:strip-duplicates(tan:resolve-doc-keywords(tan:resolve-doc-inclusions(.), $src-ids[$pos]), $names-of-included-elements)"
                  />
               </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy>
                  <xsl:copy-of select="tan:resolve-doc-keywords(., $src-ids[$pos])"/>
               </xsl:copy>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <!-- items slated for deletion March 2016 -->
   <!--<xsl:function name="tan:resolve-element" as="element()*">
        <xsl:param name="TAN-elements" as="element()*"/>
        <xsl:variable name="included-elements"
            select="$TAN-elements/descendant-or-self::*[@include]"/>
        <xsl:variable name="names-of-included-elements"
            select="
                for $i in $included-elements
                return
                    name($i)"
            as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$TAN-elements//@include">
                <xsl:copy-of
                    select="tan:strip-duplicates(tan:resolve-keyword(tan:include($TAN-elements)), $names-of-included-elements)"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="tan:resolve-keyword($TAN-elements)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>-->
   <!--<xsl:function name="tan:resolve-doc" as="document-node()*">
        <xsl:param name="TAN-documents" as="document-node()*"/>
        <xsl:variable name="pass-1" as="document-node()*">
            <xsl:for-each select="$TAN-documents">
                <xsl:copy>
                    <xsl:apply-templates mode="include"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="pass-2" as="document-node()*">
            <xsl:for-each select="$pass-1">
                <xsl:copy>
                    <xsl:apply-templates mode="resolve-keyword"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="$pass-2">
            <xsl:copy>
                <xsl:apply-templates mode="strip-duplicates"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:function>
    <xsl:function name="tan:resolve-element" as="element()*">
        <xsl:param name="tan-element" as="element()*"/>
        <xsl:variable name="pass-1" as="element()*">
            <xsl:for-each select="$tan-element">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="include"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="pass-2" as="element()*">
            <xsl:for-each select="$pass-1">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="resolve-keyword"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="$pass-2">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="strip-duplicates"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:function>-->

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
            <xsl:variable name="incl-refs" select="tokenize(tan:normalize-text(@include), ' ')"/>
            <xsl:if test="@include">
               <xsl:value-of
                  select="root()/*/tan:head/tan:inclusion[@xml:id = $incl-refs]/tan:location/@href"
               />
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="new-sequence" as="node()*">
         <xsl:for-each select="$elements-to-be-checked-for-inclusion">
            <xsl:variable name="this-base-uri" select="(root()/*/@base-uri, base-uri(.))[1]"
               as="xs:anyURI"/>
            <xsl:variable name="this-root" select="root(.)"/>
            <xsl:variable name="this-element" select="."/>
            <xsl:choose>
               <xsl:when test="@include">
                  <xsl:variable name="incl-refs"
                     select="tokenize(tan:normalize-text(@include), ' ')"/>
                  <xsl:variable name="these-inclusions"
                     select="doc($this-base-uri)/*/tan:head/tan:inclusion[@xml:id = $incl-refs]"/>
                  <xsl:variable name="these-inclusion-1st-las"
                     select="
                        for $i in $these-inclusions
                        return
                           tan:first-loc-available($i, $this-base-uri)"/>
                  <xsl:variable name="this-name" select="name()"/>
                  <xsl:variable name="these-replacement-elements"
                     select="
                        for $i in $these-inclusion-1st-las
                        return
                           doc(resolve-uri($i, $this-base-uri))//*[name(.) = $this-name][not(parent::tan:div)]"/>
                  <xsl:variable name="these-errors" as="xs:integer?">
                     <xsl:choose>
                        <xsl:when test="not(exists($these-replacement-elements))">
                           <xsl:copy-of select="2"/>
                        </xsl:when>
                        <xsl:when test="$these-inclusions/tan:location/@href = $urls-so-far">
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
                        <xsl:for-each select="$these-replacement-elements">
                           <xsl:copy>
                              <xsl:copy-of select="@*, $this-element/@q"/>
                              <xsl:copy-of select="*"/>
                           </xsl:copy>
                        </xsl:for-each>
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

   <!-- TRANSFORMATIVE TEMPLATES -->
   <!-- Default templates -->

   <xsl:template match="node()" mode="resolve-href include">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="node()" mode="resolve-keyword">
      <xsl:param name="src-id" as="xs:string?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($src-id) and not(parent::*)">
            <xsl:attribute name="src" select="$src-id"/>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="src-id" select="$src-id"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="node()" mode="strip-duplicates">
      <xsl:param name="element-names-to-check" as="xs:string*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="element-names-to-check" select="$element-names-to-check"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>

   <!-- Mode-specific templates -->
   <xsl:template match="/*" mode="first-stamp">
      <xsl:param name="leave-breadcrumbs" as="xs:boolean?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="base-uri" select="(@base-uri, base-uri(current()))[1]"/>
         <xsl:choose>
            <xsl:when test="$leave-breadcrumbs = true()">
               <xsl:apply-templates mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="node()"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="node()" mode="first-stamp">
      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="q"
            select="count(preceding-sibling::*[name() = $this-element-name]) + 1"/>
         <xsl:if test="not(parent::*)">
            <xsl:attribute name="uri" select="base-uri(.)"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:resolve-doc-inclusions" as="document-node()*">
      <xsl:param name="tan-docs" as="document-node()*"/>
      <xsl:for-each select="$tan-docs">
         <xsl:copy>
            <xsl:apply-templates mode="include"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="*[@include]" mode="include">
      <xsl:sequence select="tan:resolve-include(.)"/>
   </xsl:template>

   <xsl:function name="tan:strip-duplicates" as="document-node()*">
      <xsl:param name="tan-docs" as="document-node()*"/>
      <xsl:param name="element-names-to-check" as="xs:string*"/>
      <xsl:for-each select="$tan-docs">
         <xsl:copy>
            <xsl:apply-templates mode="strip-duplicates">
               <xsl:with-param name="element-names-to-check" select="$element-names-to-check"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="tan:* | tei:*" mode="strip-duplicates">
      <xsl:param name="element-names-to-check" as="xs:string*"/>
      <xsl:choose>
         <xsl:when test="name(.) = $element-names-to-check">
            <xsl:if
               test="
                  every $i in preceding-sibling::*
                     satisfies not(deep-equal(., $i))">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:apply-templates mode="#current">
                     <xsl:with-param name="element-names-to-check" select="$element-names-to-check"
                     />
                  </xsl:apply-templates>
               </xsl:copy>
            </xsl:if>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="element-names-to-check" select="$element-names-to-check"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:function name="tan:resolve-doc-keywords" as="document-node()*">
      <xsl:param name="tan-docs" as="document-node()*"/>
      <xsl:param name="src-ids" as="xs:string*"/>
      <xsl:for-each select="$tan-docs">
         <xsl:copy>
            <xsl:variable name="pos" select="position()"/>
            <xsl:apply-templates mode="resolve-keyword">
               <xsl:with-param name="src-id" select="$src-ids[$pos]"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:resolve-keyword" as="element()*">
      <!-- one-parameter version of the next -->
      <xsl:param name="tan-element" as="element()*"/>
      <xsl:copy-of select="tan:resolve-keyword($tan-element, ())"/>
   </xsl:function>
   <xsl:function name="tan:resolve-keyword" as="node()*">
      <xsl:param name="tan-node" as="node()*"/>
      <xsl:param name="src-ids" as="xs:string*"/>
      <xsl:for-each select="$tan-node">
         <xsl:variable name="pos" select="position()"/>
         <xsl:apply-templates select="." mode="resolve-keyword">
            <xsl:with-param name="src-id" select="$src-ids[$pos]"/>
         </xsl:apply-templates>
      </xsl:for-each>
   </xsl:function>

   <xsl:template match="tei:*[@which] | tan:*[@which]" mode="resolve-keyword">
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="element-name" select="name(.)"/>
      <xsl:variable name="this-which" select="tan:normalize-text(@which)"/>
      <xsl:variable name="first-matched-keyword-item"
         select="
            ($private-keywords//tan:item[tokenize(ancestor::*[@affects-element][1]/@affects-element, '\s+') = $element-name][tan:name = $this-which],
            $TAN-keywords[tokenize(@affects-element, '\s+') = $element-name]//tan:item[tan:name = $this-which])[1]"/>
      <xsl:variable name="resolve-keyword" as="element()?">
         <xsl:element name="{$element-name}">
            <xsl:copy-of select="$this-element/@*[not(name() = 'which')]"/>
            <xsl:copy-of select="$first-matched-keyword-item/*"/>
         </xsl:element>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="$element-name = 'token-definition'">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of
                  select="$all-keywords//tan:item[tan:name = $this-which]/tan:token-definition/@*"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$all-keywords//tan:item[tan:name = $this-which]/node()"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="*[@href]" mode="resolve-href">
      <xsl:variable name="this-doc-uri" select="document-uri(/)"/>
      <xsl:copy>
         <xsl:copy-of select="@* except @href"/>
         <xsl:attribute name="href">
            <xsl:value-of select="resolve-uri(@href, $this-doc-uri)"/>
         </xsl:attribute>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:is-flat-class-1" as="xs:boolean">
      <xsl:param name="doc-or-element" as="item()"/>
      <xsl:value-of
         select="
            if (root($doc-or-element)/(tei:TEI/tei:text/tei:body/tei:div/tei:div, tan:TAN-T/tan:body/tan:div/tan:div))
            then
               false()
            else
               true()"
      />
   </xsl:function>

   <xsl:function name="tan:flatten-class-1-doc" as="document-node()*">
      <xsl:param name="class-1-doc-resolved" as="document-node()*"/>
      <xsl:for-each select="$class-1-doc-resolved">
         <xsl:choose>
            <xsl:when test="tan:is-flat-class-1(.)">
               <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy>
                  <xsl:for-each select="node()">
                     <xsl:text>&#xA;</xsl:text>
                     <xsl:apply-templates select="." mode="flatten-class-1"/>
                  </xsl:for-each>
               </xsl:copy>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="/" mode="flatten-class-1">
      <xsl:copy>
         <xsl:apply-templates mode="flatten-class-1"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="comment() | processing-instruction() | text()" mode="flatten-class-1">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="*" mode="flatten-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div | tei:div" mode="flatten-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="n" select="string-join((ancestor-or-self::*/@n), ' ')"/>
         <xsl:attribute name="type" select="string-join(ancestor-or-self::*/@type, ' ')"/>
         <xsl:if test="(ancestor-or-self::tan:div, ancestor-or-self::tei:div)/@xml:lang">
            <xsl:attribute name="xml:lang"
               select="((ancestor-or-self::tan:div, ancestor-or-self::tei:div)/@xml:lang)[1]"/>
         </xsl:if>
         <xsl:if test="not(tan:div | tei:div)">
            <xsl:copy-of select="node()"/>
         </xsl:if>
      </xsl:copy>
      <xsl:apply-templates mode="#current"
         select="tan:div | tei:div | text()[not(matches(., '\S'))] | comment()"/>
   </xsl:template>

</xsl:stylesheet>
