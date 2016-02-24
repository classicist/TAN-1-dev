<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>Aug 19, 2015</xd:p>
         <xd:p>Core variables and functions for class 2 TAN files (i.e., applicable to multiple
            class 2 TAN file types). Written principally for Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="TAN-core-functions.xsl"/>

   <xsl:param name="searches-ignore-accents" xml:id="p-searches-ignore-accents" select="true()"
      as="xs:boolean"/>
   <xsl:param name="searches-are-case-sensitive" xml:id="p-searches-are-case-sensitive"
      select="false()" as="xs:boolean"/>
   <xsl:variable name="match-flags" xml:id="v-match-flags"
      select="
         if ($searches-are-case-sensitive = true()) then
            ()
         else
            'i'"
      as="xs:string?"/>
   <xsl:param name="searches-suppress-what-text" xml:id="p-searches-suppress-what-text"
      as="xs:string?" select="'[\p{M}]'"/>

   <!-- GENERAL -->
   <xsl:variable name="reference-errors"
      select="
         ('@ref must refer to leaf div',
         'reference cannot be found in source')"/>
   <!-- SOURCES -->
   <xsl:variable name="sources" xml:id="v-sources" select="$head/tan:source"/>
   <xsl:variable name="src-count" xml:id="v-src-count" select="1 to count($sources)"
      as="xs:integer+"/>
   <xsl:variable name="source-lacks-id" xml:id="v-source-lacks-id"
      select="
         if (name(/*) = 'TAN-LM') then
            true()
         else
            false()"/>
   <xsl:variable name="src-ids" xml:id="v-src-ids"
      select="
         if ($source-lacks-id) then
            '1'
         else
            $sources/@xml:id"/>
   <xsl:variable name="src-1st-da-locations" xml:id="v-src-1st-da-locations"
      select="tan:get-1st-da-locations($sources)"/>
   <xsl:variable name="src-1st-da" xml:id="v-src-1st-da"
      select="
         for $i in $src-1st-da-locations
         return
            if ($i = '') then
               $empty-doc
            else
               document($i)"/>
   <xsl:variable name="src-1st-da-base-uri" xml:id="v-src-1st-da-base-uri"
      select="
         for $i in $src-1st-da
         return
            base-uri($i)"/>
   <xsl:variable name="src-1st-da-version" xml:id="v-src-1st-da-version"
      select="
         for $i in $src-1st-da
         return
            tan:most-recent-dateTime($i//(@when | @ed-when | @when-accessed))"/>
   <xsl:variable name="src-1st-da-resolved" xml:id="v-src-1st-da-resolved"
      select="tan:resolve-doc($src-1st-da)"/>
   <xsl:variable name="src-1st-da-heads" xml:id="v-src-1st-da-heads"
      select="$src-1st-da-resolved/*/tan:head"/>
   <xsl:variable name="src-1st-da-data" xml:id="v-src-1st-da-data"
      select="tan:prep-class-1-data($src-1st-da-resolved)"/>
   <xsl:variable name="src-1st-da-all-div-types" xml:id="v-src-1st-da-all-div-types" as="element()">
      <xsl:variable name="all" select="$src-1st-da-heads/tan:declarations/tan:div-type"/>
      <xsl:variable name="div-seq" as="element()*">
         <xsl:for-each select="$all">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="this-div-type" select="."/>
            <xsl:variable name="these-IRIs" select="tan:IRI"/>
            <xsl:copy>
               <xsl:attribute name="src" select="index-of($src-1st-da-heads, $this-div-type/../..)"/>
               <xsl:attribute name="eq-id" select="tan:div-type-eq($pos)"/>
               <xsl:copy-of select="@* | *"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <tan:all-div-types>
         <xsl:for-each-group select="$div-seq" group-by="@src">
            <tan:source>
               <xsl:sequence select="current-group()"/>
            </tan:source>
         </xsl:for-each-group>
      </tan:all-div-types>
   </xsl:variable>

   <!-- DECLARATIONS -->

   <!-- DECLARATIONS: token-definition -->
   <xsl:variable name="token-definitions-per-source" xml:id="v-tokenizations-per-source"
      as="element()*">
      <!-- Sequence of one <token-definition> per source, chosen by whichever comes first:
         1. <token-definition> in the originating class-2 file;
         2. <token-definition> in the source file;
         3. The pre-set general <token-definition> (letters only)
      -->
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="this-src-id" select="$src-ids[$this-src]"/>
         <xsl:variable name="first-token-definition"
            select="
               $head/tan:declarations/tan:token-definition[if (@src) then
                  (tokenize(@src, '\s+') = $this-src-id)
               else
                  true()][1]"/>
         <xsl:variable name="src-first-token-definition"
            select="$src-1st-da-heads[$this-src]/tan:declarations/tan:token-definition[1]"/>
         <source id="{$this-src-id}">
            <xsl:copy-of
               select="($first-token-definition, $src-first-token-definition, $token-definitions-reserved)"
            />
         </source>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="distinct-tokenizations" xml:id="v-distinct-tokenizations" as="element()*">
      <!-- Sequence of one node/tree per tokenization used:
         <location href="[URL]"/>
         <replace>[REPLACE NODE 1]</replace>
         <replace>[REPLACE NODE 2]</replace>
         ...
         <tokenize>[tokenize]</replace>-->
      <xsl:for-each select="distinct-values($token-definitions-per-source//tan:location/@href)">
         <xsl:variable name="this-tokenization-location" select="."/>
         <xsl:element name="tan:tokenization">
            <xsl:element name="tan:location">
               <xsl:attribute name="href">
                  <xsl:value-of select="$this-tokenization-location"/>
               </xsl:attribute>
            </xsl:element>
            <xsl:if test="doc-available($this-tokenization-location)">
               <xsl:copy-of
                  select="document($this-tokenization-location)/tan:TAN-R-tok/tan:body/tan:replace"/>
               <xsl:copy-of
                  select="document($this-tokenization-location)/tan:TAN-R-tok/tan:body/tan:tokenize"
               />
            </xsl:if>
         </xsl:element>
      </xsl:for-each>
   </xsl:variable>

   <!-- DECLARATIONS: suppress-div-types -->
   <xsl:variable name="suppress-div-types" xml:id="v-suppress-div-types"
      select="$head/tan:declarations/tan:suppress-div-types"/>
   <!-- Source div types to suppress ("book section ...","part folio ...", "", ...) -->
   <xsl:variable name="src-div-types-to-suppress" xml:id="v-src-div-types-to-suppress"
      select="
         if ($source-lacks-id and $suppress-div-types/@div-type-ref)
         then
            $suppress-div-types/@div-type-ref
         else
            for $i in $src-ids
            return
               if ($suppress-div-types[tokenize(@src, '\s+') = $i]/@div-type-ref)
               then
                  string-join($suppress-div-types[tokenize(@src, '\s+') = $i]/@div-type-ref, ' ')
               else
                  ''"/>
   <!-- Derivative regex patterns, to find the div types to be suppressed in any flattened 
      ref in any source  ("((book)|(section))\.\w*:?", "((part)|(folio))\.\w*:?", "", ...) -->
   <xsl:variable name="src-div-types-to-suppress-reg-ex" xml:id="v-src-div-types-to-suppress-reg-ex"
      select="
         for $i in $src-div-types-to-suppress
         return
            if ($i = '') then
               ''
            else
               concat('((', replace($i, '\s+', '|'), '))', $separator-type-and-n-regex, '\w*', $separator-hierarchy-regex, '?')"/>

   <!-- DECLARATIONS: implicit-div-type-refs -->
   <xsl:variable name="src-impl-div-types" xml:id="v-src-impl-div-types"
      select="
         if ($head/tan:declarations/tan:implicit-div-type-refs)
         then
            tan:src-ids-to-nos($head/tan:declarations/tan:implicit-div-type-refs/@src)
         else
            ()"/>
   <!-- next variables used to check to see if implicit syntax is ok in a class 1 file that doesn't make a 
      recommendation one way or another -->
   <xsl:variable name="src-impl-div-types-not-already-recommended"
      xml:id="v-src-impl-div-types-not-already-recommended"
      select="
         for $i in $src-impl-div-types
         return
            if ($src-1st-da-heads[$i]/tan:declarations/tan:recommended-div-type-refs) then
               ()
            else
               $i"/>
   <xsl:variable name="duplicate-implicit-refs" xml:id="v-duplicate-implicit-refs" as="xs:string*">
      <xsl:for-each select="$src-impl-div-types-not-already-recommended">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="these-impl-refs"
            select="$src-1st-da-data[$this-src]/tan:div[@lang]/@impl-ref" as="xs:string*"/>
         <xsl:variable name="these-duplicates"
            select="$these-impl-refs[index-of($these-impl-refs, .)[2]]"/>
         <xsl:copy-of
            select="
               if (exists($these-duplicates)) then
                  $these-duplicates
               else
                  ()"
         />
      </xsl:for-each>
   </xsl:variable>

   <!-- DECLARATIONS: rename-div-types -->
   <xsl:variable name="rename-div-types" xml:id="v-rename-div-types" as="element()">
      <tan:rename-div-types>
         <xsl:for-each select="$src-count">
            <xsl:variable name="this-src" select="."/>
            <tan:source>
               <xsl:copy-of
                  select="
                     if ($source-lacks-id) then
                        $head/tan:declarations/tan:rename-div-types
                     else
                        $head/tan:declarations/tan:rename-div-types[$this-src = tan:src-ids-to-nos(@src)]/tan:rename"
               />
            </tan:source>
         </xsl:for-each>
      </tan:rename-div-types>
   </xsl:variable>

   <!-- DECLARATIONS: rename-div-ns -->
   <xsl:variable name="rename-div-ns" xml:id="v-rename-div-ns" as="element()">
      <tan:rename-div-ns>
         <xsl:for-each select="$src-count">
            <xsl:variable name="this-src" select="."/>
            <tan:source>
               <xsl:for-each
                  select="
                     distinct-values(tokenize(if ($source-lacks-id) then
                        string-join($head/tan:declarations/tan:rename-div-ns/@div-type-ref, ' ')
                     else
                        string-join($head/tan:declarations/tan:rename-div-ns[$this-src = tan:src-ids-to-nos(@src)]/@div-type-ref, ' '), '\s+'))">
                  <xsl:variable name="this-div-type" select="."/>
                  <tan:div-type div-type="{$this-div-type}">
                     <xsl:copy-of
                        select="
                           if ($source-lacks-id) then
                              $head/tan:declarations/tan:rename-div-ns[tokenize(@div-type-ref, '\s+') = $this-div-type]/tan:rename
                           else
                              $head/tan:declarations/tan:rename-div-ns[$this-src = tan:src-ids-to-nos(@src)][tokenize(@div-type-ref, '\s+') = $this-div-type]/tan:rename"
                     />
                  </tan:div-type>
               </xsl:for-each>
            </tan:source>
         </xsl:for-each>
      </tan:rename-div-ns>
   </xsl:variable>
   <xsl:variable name="n-type" xml:id="v-n-type"
      select="
         ('i',
         '1',
         '1a',
         'a',
         'a1',
         '$')"/>
   <xsl:variable name="n-type-label" xml:id="v-n-type-label"
      select="
         ('Roman numerals',
         'Arabic numerals',
         'Arabic numerals + alphabet numeral',
         'alphabet numeral',
         'alphabet numeral + Arabic numeral',
         'string')"/>
   <!-- Patterns to detect those @n types -->
   <xsl:variable name="n-type-pattern" xml:id="v-n-type-pattern"
      select="
         (concat('^(', $roman-numeral-pattern, ')$'),
         '^(\d+)$',
         concat('^(\d+)(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')(\d+)$'),
         '(.)')"/>
   <!-- Calculated types of @n values per div type per source -->
   <xsl:variable name="div-type-ord-check" xml:id="v-div-type-ord-check" as="element()">
      <tan:div-types-ord-check>
         <xsl:for-each select="$src-1st-da-all-div-types/tan:source">
            <xsl:variable name="this-src" select="count(preceding-sibling::tan:source) + 1"/>
            <tan:source>
               <xsl:for-each select="tan:div-type">
                  <xsl:variable name="this-div-type" select="@xml:id"/>
                  <xsl:variable name="this-ns"
                     select="
                        $src-1st-da[$this-src]//(tan:div,
                        tei:div)[@type = $this-div-type]/@n"/>
                  <xsl:variable name="this-ns-types"
                     select="
                        if (@ns-are-numerals = 'false') then
                           for $i in $this-ns
                           return
                              '$'
                        else
                           for $i in $this-ns
                           return
                              if (matches($i, $n-type-pattern[1], 'i')) then
                                 $n-type[1]
                              else
                                 if (matches($i, $n-type-pattern[2], 'i')) then
                                    $n-type[2]
                                 else
                                    if (matches($i, $n-type-pattern[3], 'i')) then
                                       $n-type[3]
                                    else
                                       if (matches($i, $n-type-pattern[4], 'i')) then
                                          $n-type[4]
                                       else
                                          if (matches($i, $n-type-pattern[5], 'i')) then
                                             $n-type[5]
                                          else
                                             $n-type[6]"/>
                  <xsl:variable name="this-n-types-count"
                     select="
                        for $i in $n-type
                        return
                           count(index-of($this-ns-types, $i))"/>
                  <xsl:variable name="this-dominant-n-type"
                     select="$n-type[index-of($this-n-types-count, max($this-n-types-count))[1]]"/>
                  <xsl:element name="tan:div-type">
                     <xsl:attribute name="id" select="$this-div-type"/>
                     <xsl:attribute name="type" select="$this-dominant-n-type"/>
                     <xsl:attribute name="ns-type-i" select="$this-n-types-count[1]"/>
                     <xsl:attribute name="ns-type-1" select="$this-n-types-count[2]"/>
                     <xsl:attribute name="ns-type-1a" select="$this-n-types-count[3]"/>
                     <xsl:attribute name="ns-type-a" select="$this-n-types-count[4]"/>
                     <xsl:attribute name="ns-type-a1" select="$this-n-types-count[5]"/>
                     <xsl:attribute name="ns-type-str" select="$this-n-types-count[6]"/>
                  </xsl:element>
               </xsl:for-each>
            </tan:source>
         </xsl:for-each>
      </tan:div-types-ord-check>
   </xsl:variable>


   <!-- CONTEXT INDEPENDENT FUNCTIONS -->
   <xsl:function name="tan:counts-to-lasts" xml:id="f-counts-to-lasts" as="xs:integer*">
      <!-- Input: sequence of numbers representing counts of items. 
         Output: sequence of numbers representing the last position of each item within the total count.
      E.g., (4, 12, 0, 7) - > (4, 16, 16, 23)-->
      <xsl:param name="seq" as="xs:integer*"/>
      <xsl:copy-of
         select="
            for $i in (1 to count($seq))
            return
               sum(for $j in (1 to $i)
               return
                  $seq[$j])"
      />
   </xsl:function>
   <xsl:function name="tan:counts-to-firsts" xml:id="f-counts-to-firsts" as="xs:integer*">
      <!-- Input: sequence of numbers representing counts of items. 
         Output: sequence of numbers representing the first position of each item within the total count.
      E.g., (4, 12, 0, 7) - > (1, 5, 17, 17)-->
      <xsl:param name="seq" as="xs:integer*"/>
      <xsl:copy-of
         select="
            for $i in (1 to count($seq))
            return
               sum(for $j in (1 to $i)
               return
                  $seq[$j]) - $seq[$i] + 1"
      />
   </xsl:function>
   <xsl:function name="tan:normalize-refs" xml:id="f-normalize-refs" as="xs:string?">
      <!-- Input: string value of @ref that explicitly uses div types
         Output: punctuation- and space-normalized reference string
         E.g., "bk/Gen ch.1 epigraph.   , bk^Gen ch,5   - bk,Gen ch?7" -> "bk.Gen:ch.1:epigraph. , bk.Gen:ch.5 - bk.Gen:ch.7" 
      -->
      <xsl:param name="raw-ref" as="xs:string?"/>
      <xsl:variable name="norm-ref" select="normalize-space(replace($raw-ref, '\?', ''))"/>
      <xsl:value-of
         select="
            string-join(for $i in tokenize($norm-ref, '\s*,\s+')
            return
               string-join(for $j in tokenize($i, '\s+-\s+')
               return
                  tan:normalize-ref-punctuation($j), ' - '), ' , ')"
      />
   </xsl:function>
   <xsl:function name="tan:normalize-ref-punctuation" xml:id="f-normalize-ref-punctuation"
      as="xs:string">
      <!-- Input: reference where pattern = "\w+\W\w*(\W\w+\W\w*)*" (i.e., div types are explicit)
        Output: first \W (type + n separator) - > . and second \W (hierarchy separator) - > :
        E.g., bk/Gen 2.1 epigraph.  ->  bk.Gen:2.1:epigraph. 
        -->
      <xsl:param name="in" as="xs:string"/>
      <xsl:variable name="seq" select="tokenize($in, '\W')"/>
      <xsl:copy-of
         select="
            string-join(for $i in (1 to (count($seq) idiv 2))
            return
               concat($seq[($i * 2) - 1], '.', $seq[($i * 2)]), ':')"
      />
   </xsl:function>
   <!-- The next function is context-dependent, but is here to be close to its context-indepedent peer -->
   <xsl:function name="tan:normalize-impl-refs" xml:id="f-normalize-impl-refs" as="xs:string?">
      <!-- Input: (1) string value of @ref where div types are implicit; (2) source number
         Output: type-, punctuation-, and space-normalized reference string
         E.g., "Gen 4 1   , Gen:2:5   - Gen 2$7" -> "bk.Gen:ch.1:v.1 , bk.Gen:ch.2:v.5 - bk.Gen:ch.2:v.7" 
      -->
      <xsl:param name="raw-ref" as="xs:string?"/>
      <xsl:param name="src-no" as="xs:integer?"/>
      <xsl:variable name="norm-ref" select="normalize-space(replace($raw-ref, '\?', ''))"/>
      <xsl:value-of
         select="
            string-join(for $i in tokenize($norm-ref, '\s*,\s+')
            return
               string-join(for $j in tokenize($i, '\s+-\s+')
               return
                  ($src-1st-da-data[$src-no]//tan:div[@impl-ref = replace($j, '\W', $separator-hierarchy)]/@ref,
                  replace($j, '\W', $separator-hierarchy),
                  $j)[1], ' - '), ' , ')"
      />
   </xsl:function>
   <xsl:function name="tan:ref-range-check" xml:id="f-ref-range-check" as="xs:boolean*">
      <xsl:param name="attr-ref" as="xs:string?"/>
      <xsl:variable name="this-ref" select="normalize-space($attr-ref)"/>
      <xsl:variable name="these-ranges"
         select="
            for $i in tokenize($this-ref, ' ?, ')
            return
               if (matches($i, ' - ')) then
                  $i
               else
                  ()"/>
      <xsl:variable name="ranges-analyzed" as="element()*">
         <xsl:for-each select="$these-ranges">
            <xsl:variable name="this-pair" select="tokenize(., ' - ')"/>
            <xsl:element name="range">
               <xsl:attribute name="a" select="string-length(replace($this-pair[1], '\w+', ''))"/>
               <xsl:attribute name="b" select="string-length(replace($this-pair[2], '\w+', ''))"/>
            </xsl:element>
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy-of
         select="
            for $i in $ranges-analyzed
            return
               ($i/@a = $i/@b)"
      />
   </xsl:function>
   <xsl:function name="tan:ordinal" xml:id="f-ordinal" as="xs:string+">
      <!-- Input: one or more numerals
        Output: one or more strings with the English form of the ordinal form of the input number
        E.g., (1, 4, 17)  ->  ('first','fourth','17th'). 
        -->
      <xsl:param name="in" as="xs:integer+"/>
      <xsl:variable name="ordinals"
         select="
            ('first',
            'second',
            'third',
            'fourth',
            'fifth',
            'sixth',
            'seventh',
            'eighth',
            'ninth',
            'tenth')"/>
      <xsl:variable name="ordinal-suffixes"
         select="
            ('th',
            'st',
            'nd',
            'rd',
            'th',
            'th',
            'th',
            'th',
            'th',
            'th')"/>
      <xsl:copy-of
         select="
            for $i in $in
            return
               if (exists($ordinals[$i]))
               then
                  $ordinals[$i]
               else
                  concat(xs:string($i), $ordinal-suffixes[($i mod 10) + 1])"
      />
   </xsl:function>
   <xsl:function name="tan:sequence-expand" xml:id="f-sequence-expand" as="xs:integer*">
      <!-- input: one string of concise TAN selectors (used by @poss, @chars, @segs), 
            and one integer defining the value of 'last'
            output: a sequence of numbers representing the positions selected, unsorted, and retaining
            duplicate values.
            E.g., ("2 - 4, last-5 - last, 36", 50) -> (2, 3, 4, 45, 46, 47, 48, 49, 50, 36)
        -->
      <xsl:param name="selector" as="xs:string?"/>
      <xsl:param name="max" as="xs:integer?"/>
      <xsl:variable name="pass-1" select="replace($selector, '(\d)\s*-\s*(last|\d)', '$1 - $2')"/>
      <xsl:variable name="pass-2" select="replace($pass-1, '(\d)\s+(\d)', '$1, $2')"/>
      <xsl:variable name="selector-norm" select="replace($pass-2, 'last', string($max))"/>
      <xsl:variable name="seq-a" select="tokenize(normalize-space($selector-norm), '\s*,\s+')"/>
      <xsl:copy-of
         select="
            for $i in $seq-a
            return
               if (matches($i, ' - '))
               then
                  (tan:string-subtract(tokenize($i, ' - ')[1])) to (tan:string-subtract(tokenize($i, ' - ')[2]))
               else
                  tan:string-subtract($i)"/>

   </xsl:function>
   <xsl:function name="tan:string-subtract" xml:id="f-string-subtract" as="xs:integer">
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
   <xsl:function name="tan:max-integer" xml:id="f-max-integer" as="xs:integer?">
      <!-- input: string of TAN @pos or @chars selectors 
        output: largest integer, ignoring value of 'last'
        E.g., "5 - 15, last-20" -> 15 -->
      <xsl:param name="input" as="xs:string"/>
      <xsl:variable name="output"
         select="
            xs:integer(max(for $i in tokenize($input, '\s*[-,]\s+')
            return
               if (matches($i, '^\d+$'))
               then
                  number($i)
               else
                  ()))"/>
      <xsl:value-of
         select="
            if (exists($output)) then
               $output
            else
               1"
      />
   </xsl:function>
   <xsl:function name="tan:min-last" xml:id="f-min-last" as="xs:integer">
      <!-- input: @pos or @chars selectors, number defining "last" 
        output: smallest reference related to "last"
        E.g., "5 - 15, last-20", 34 -> 14 -->
      <xsl:param name="input" as="xs:string"/>
      <xsl:param name="last" as="xs:integer"/>
      <xsl:variable name="input-2" as="xs:string+" select="tokenize($input, '\s*[-,]\s+')"/>
      <xsl:variable name="input-3"
         select="
            for $i in $input-2
            return
               if (matches($i, 'last-\d+'))
               then
                  xs:integer(number(replace($i, '\D+', '')))
               else
                  0"
         as="xs:integer+"/>
      <xsl:value-of select="$last - max($input-3)"/>
   </xsl:function>
   <xsl:function name="tan:help-requested" xml:id="f-help-requested" as="xs:boolean">
      <xsl:param name="element" as="element()"/>
      <xsl:value-of
         select="
            if (some $i in $element/@*
               satisfies matches($i, $help-trigger-regex)) then
               true()
            else
               false()"
      />
   </xsl:function>

   <!-- CONTEXT DEPENDENT FUNCTIONS -->
   <xsl:function name="tan:src-ids-to-nos" xml:id="f-src-ids-to-nos" as="xs:integer*">
      <!-- Input: values of @src (@xml:id values of sources)
      Output: sequence of integers for all sources 
      If input is an empty string, or the format lacks ids for sources, output = 1
      E.g., ('src-a src-d', 'src-b src-d') - > (1, 4, 2, 4)
      () - > 1
      -->
      <xsl:param name="att-src" as="xs:string*"/>
      <xsl:variable name="att-src-checked-for-help"
         select="
            for $i in $att-src
            return
               normalize-space(replace($i, $help-trigger-regex, ''))"/>
      <xsl:choose>
         <xsl:when test="exists($att-src-checked-for-help) and not($source-lacks-id)">
            <xsl:for-each select="$att-src-checked-for-help">
               <xsl:variable name="this-src-string" select="."/>
               <xsl:choose>
                  <xsl:when test="$this-src-string = '*'">
                     <xsl:copy-of select="$src-count"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of
                        select="
                           for $i in tokenize($this-src-string, '\s+')
                           return
                              index-of($src-ids, $i)"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="1"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tan:div-type-eq" xml:id="f-div-type-eq" as="xs:integer*">
      <!-- Input: digit representing the position of the div-type to be checked within the sequence of all div-types of all sources
      Output: digit representing the smallest position of the div-type that is equivalent, within the same sequence
      E.g., 22 - > 3 -->
      <xsl:param name="div-type-nos" as="xs:integer*"/>
      <xsl:variable name="all" select="$src-1st-da-heads/tan:declarations/tan:div-type"/>
      <xsl:variable name="these-div-type-iris"
         select="
            for $i in $div-type-nos
            return
               $all[$i]/tan:IRI"/>
      <xsl:variable name="matches" as="xs:integer*">
         <xsl:for-each select="$all">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="this-div-type" select="."/>
            <xsl:if test="$this-div-type[tan:IRI = $these-div-type-iris]">
               <xsl:copy-of select="$pos"/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy-of
         select="
            if (count($matches) gt count($div-type-nos)) then
               tan:div-type-eq($matches)
            else
               min($div-type-nos)"
      />
   </xsl:function>

   <xsl:function name="tan:prep-class-1-data" xml:id="f-prep-class-1-data-1" as="element()*">
      <!-- Input: sequence of resolved class 1 TAN documents (the result of tan:resolve-doc())
         Output: sequence of one node/tree per source flattening the data into this form:
         <tan:div @pos="[POSITION, TO AVOID LENGTHY RECALCULATIONS DOWNSTREAM]" 
         @old-ref="[NORMALIZED, FLATTENED REF]" @ref="[NORMALIZED, FLATTENED 
         REF WITH TYPE AND N SUBSTITUTIONS AND SUPPRESSIONS]" @impl-ref="[AS @ref BUT 
         ONLY @n VALUES, NOT @type]" @lang="[LANG]">[TEXT, IF ANY][2ND COPY WITH ORIGINAL 
         TEI MARKUP, IF ANY]</div>
         No @lang if not a leaf div. Text remains untokenized.
      -->
      <xsl:param name="class-1-documents" as="document-node()*"/>
      <xsl:for-each select="$class-1-documents">
         <xsl:variable name="this-src" select="position()"/>
         <source
            id="{if (count($src-ids) = count($class-1-documents)) then $src-ids[$this-src] else ''}">
            <xsl:for-each select=".//(tan:div, tei:div)">
               <xsl:apply-templates select="." mode="prep-class-1-data">
                  <xsl:with-param name="this-src" select="$this-src"/>
                  <xsl:with-param name="this-pos" select="position()"/>
               </xsl:apply-templates>
            </xsl:for-each>
         </source>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="tan:div | tei:div" mode="prep-class-1-data">
      <xsl:param name="this-pos" as="xs:integer"/>
      <xsl:param name="this-src" as="xs:integer"/>
      <xsl:variable name="this-flatref" select="tan:flatref(.)"/>
      <xsl:variable name="this-flatref-converted"
         select="
            if ($src-div-types-to-suppress-reg-ex[$this-src] = '') then
               tan:ref-rename($this-flatref, $this-src)
            else
               replace(tan:ref-rename($this-flatref, $this-src), $src-div-types-to-suppress-reg-ex[$this-src], '')"/>
      <xsl:variable name="this-flatref-converted-without-div-types"
         select="replace($this-flatref-converted, concat('\w+', $separator-type-and-n-regex), '')"/>
      <div pos="{$this-pos}" old-ref="{$this-flatref}" ref="{$this-flatref-converted}"
         impl-ref="{$this-flatref-converted-without-div-types}">
         <xsl:if test="not(tan:div | tei:div)">
            <xsl:attribute name="lang" select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
            <xsl:value-of select="normalize-space(string(.))"/>
            <xsl:copy-of select="tei:*"/>
         </xsl:if>
      </div>
   </xsl:template>
   <xsl:function name="tan:pick-prepped-class-1-data" xml:id="f-pick-prepped-class-1-data"
      as="element()*">
      <!-- Used to create a subset of $src-1st-da-data (the result of tan:prep-class-1-data()) 
         Input: integer* (a filter consisting of source numbers), string* (a filter consisting of 
         normalized reference sequences [atoms joined by 
         hyphens or commas], one per source chosen)
         Output: nodes, 1 per source, proper subset of tan:prep-class-1-data()
      -->
      <xsl:param name="src-list" as="xs:integer*"/>
      <xsl:param name="refs-norm" as="xs:string*"/>
      <xsl:for-each select="$src-1st-da-data">
         <xsl:variable name="this-src" select="position()"/>
         <xsl:variable name="this-data" select="."/>
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="$this-src = $src-list">
               <xsl:for-each select="tokenize($refs-norm[index-of($src-list, $this-src)], ' , ')">
                  <xsl:variable name="this-ref-atoms" select="tokenize(.,' - ')"/>
                  <xsl:variable name="this-ref-atoms-regex" select="tan:escape($this-ref-atoms)"/>
                  <xsl:choose>
                     <xsl:when
                        test="
                           every $i in $this-ref-atoms
                              satisfies $this-data/tan:div[@ref = $i]">
                        <xsl:choose>
                           <xsl:when test="count($this-ref-atoms) gt 1">
                              <xsl:copy-of
                                 select="
                                    $this-data/((tan:div[matches(@ref,
                                    concat('^', $this-ref-atoms-regex[1], '$|^', $this-ref-atoms-regex[1], '\W'))][1]/(self::node(),
                                    following-sibling::tan:div))
                                    except (tan:div[matches(@ref, concat('^', $this-ref-atoms-regex[2], '$|^', $this-ref-atoms-regex[2], '\W'))][last()]/following-sibling::tan:div))"
                              />
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:copy-of
                                 select="$this-data/tan:div[matches(@ref, concat('^', $this-ref-atoms-regex, '$|^', $this-ref-atoms-regex, '\W'))]"
                              />
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:element name="tan:div">
                           <xsl:attribute name="ref" select="$this-ref-atoms"/>
                           <xsl:attribute name="error" select="2"/>
                           <xsl:value-of select="$reference-errors[2]"/>
                        </xsl:element>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
            </xsl:if>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:tokenize-prepped-class-1-data" xml:id="f-tokenize-prepped-class-1-data"
      as="element()*">
      <!-- Input: element()+ resulting from tan:pick-prepped-class-1-data() 
         or tan:prep-class-1-data()
         Output: Copy of input, but analyzing tan:div content into <tan:tok> and 
         <tan:non-tok>.-->
      <xsl:param name="this-prepped-c1-data" as="element()*"/>
      <xsl:apply-templates select="$this-prepped-c1-data" mode="tokenize-prepped-class-1-data"/>
   </xsl:function>
   <xsl:template match="tan:source" mode="tokenize-prepped-class-1-data">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="this-src" select="index-of($src-ids, @id)"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tei:*" mode="tokenize-prepped-class-1-data">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tan:div" mode="tokenize-prepped-class-1-data">
      <xsl:param name="this-src" as="xs:integer"/>
      <xsl:variable name="this-tok-def" select="$token-definitions-per-source[$this-src]/tan:token-definition[1]"/>
      <xsl:variable name="this-text" select="normalize-space(string-join(text(), ''))"/>
      <xsl:variable name="this-analyzed" select="tan:analyze-string($this-text, $this-tok-def)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$this-analyzed/@max-toks"/>
         <!--<xsl:copy-of select="$this-analyzed/@*"/>-->
         <xsl:copy-of select="$this-analyzed/*"/>
         <xsl:apply-templates select="*" mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:pick-tokenized-prepped-class-1-data"
      xml:id="f-pick-tokenized-prepped-class-1-data" as="element()*">
      <!-- Input: tan:tok, complete with @src, @ref, @pos|@val 
         Output: elements, 1 per source, deep copy of appropriate tree generated 
         by tan:tokenize-prepped-class-1-data() -->
      <xsl:param name="tok-element" as="element()"/>
      <xsl:variable name="this-src-list" select="tan:src-ids-to-nos($tok-element/@src)"/>
      <xsl:variable name="help-requested" select="tan:help-requested($tok-element)"/>
      <xsl:variable name="this-refs-norm"
         select="
            for $i in $this-src-list
            return
               if ($i = $src-impl-div-types) then
                  tan:normalize-impl-refs($tok-element/@ref, $i)
               else
                  tan:normalize-refs($tok-element/@ref)"/>
      <xsl:variable name="this-ord"
         select="
            if ($help-requested) then
               '1 - last'
            else
               if ($tok-element/@pos) then
                  normalize-space(replace($tok-element/@pos, '\?', ''))
               else
                  ()"/>
      <xsl:variable name="this-val"
         select="
            if ($help-requested) then
               if (matches($tok-element/@val, '^\s+\?$|^\?\s+$')) then
                  ()
               else
                  normalize-space(replace($tok-element/@val, '\s+\?|\?\s+', ''))
            else
               if (exists($tok-element/@val)) then
                  normalize-space($tok-element/@val)
               else
                  ()"/>
      <xsl:variable name="src-ref-subset"
         select="tan:pick-prepped-class-1-data($this-src-list, $this-refs-norm)"/>
      <xsl:variable name="src-ref-subset-tokenized"
         select="tan:tokenize-prepped-class-1-data($src-ref-subset)"/>
      <xsl:for-each select="$src-ref-subset-tokenized">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="tan:div">
               <xsl:variable name="this-div" select="."/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:variable name="this-last"
                     select="
                        if (exists($this-val))
                        then
                           count(tan:tok[matches(., $this-val)])
                        else
                           count(tan:tok)"/>
                  <xsl:variable name="this-ord-seq"
                     select="tan:sequence-expand($this-ord, $this-last)"/>
                  <xsl:for-each
                     select="
                        if (exists($this-ord-seq)) then
                           $this-ord-seq
                        else
                           1">
                     <xsl:variable name="this-ord-item" select="."/>
                     <xsl:variable name="this-tok"
                        select="
                           if (exists($this-val)) then
                              $this-div/tan:tok[matches(., $this-val)][$this-ord-item]
                           else
                              $this-div/tan:tok[$this-ord-item]"/>
                     <xsl:choose>
                        <xsl:when test="exists($this-tok)">
                           <xsl:copy-of select="$this-tok"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <tok error="{string-join(($this-val, string($this-ord-item)),' ')}"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each>
               </xsl:copy>
            </xsl:for-each>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:itemize-leaf-refs" xml:id="f-itemize-leaf-refs" as="xs:string*">
      <!-- Turns a compound ref string into a sequence of atomized refs to leaf divs only in the source provided
         Input: normalized ref sequence (value of @ref), source number
         Output: sequence of values of @ref for leaf divs from $src-1st-da-data
      -->
      <xsl:param name="ref-range-norm" as="xs:string"/>
      <xsl:param name="src" as="xs:integer"/>
      <xsl:variable name="ref-range-seq-1" select="tokenize($ref-range-norm, ' , ')"/>
      <xsl:for-each select="$ref-range-seq-1">
         <xsl:variable name="start" select="tokenize(., ' - ')[1]"/>
         <xsl:variable name="end" select="tokenize(., ' - ')[2]"/>
         <xsl:choose>
            <xsl:when test="exists($end)">
               <xsl:variable name="nodes"
                  select="
                     $src-1st-da-data[$src]/tan:div[matches(@ref, concat('^', $end))][text()]/(self::tan:div,
                     preceding-sibling::tan:div[text()]) except $src-1st-da-data[$src]/tan:div[@ref = $start]/preceding-sibling::tan:div"/>
               <xsl:copy-of select="$nodes/@ref"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of
                  select="$src-1st-da-data[$src]/tan:div[matches(@ref, concat('^', $start))][text()]/@ref"
               />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:itemize-bare-refs" xml:id="f-itemize-bare-refs" as="xs:string*">
      <!-- Turns a compound ref string into a sequence of atomized refs to divs in the source provided,
         calculated conservatively in the case of ranges. Only peers on the hierarchy will be returned. 
         Input: normalized ref sequence (value of @ref), source number
         Output: sequence of values of @ref for leaf divs from $src-1st-da-data
         E.g., 'book.1:ch.2 , book.2 - book.4' - > ('book.1:ch.2', 'book.2', 'book.3', 'book.4')
         'book.1:ch.2 , book.2 - book.4:ch.2' - > ('book.1:ch.2', 'book.2', 'book.3', 'book.4:ch.1', 'book.4:ch.2')
         'book.1:ch.2 , book.2:ch.7 - book.4' - > ('book.1:ch.2', 'book.2:ch.7', 'book.2:ch.8', 'book.3', 'book.4')
      -->
      <xsl:param name="ref-range-norm" as="xs:string"/>
      <xsl:param name="src" as="xs:integer"/>
      <xsl:variable name="ref-range-seq-1" select="tokenize($ref-range-norm, ' , ')"/>
      <xsl:for-each select="$ref-range-seq-1">
         <xsl:variable name="start" select="tokenize(., ' - ')[1]"/>
         <xsl:variable name="end" select="tokenize(., ' - ')[2]"/>
         <xsl:variable name="start-hier-pos" select="string-length(replace($start, '\w+', ''))"/>
         <xsl:variable name="end-hier-pos" select="string-length(replace($end, '\w+', ''))"/>
         <xsl:variable name="top-hier-pos"
            select="
               min(($start-hier-pos,
               $end-hier-pos))"/>
         <xsl:choose>
            <xsl:when test="exists($end)">
               <xsl:variable name="nodes"
                  select="
                     $src-1st-da-data[$src]/tan:div[matches(@ref, concat('^', $end))]/(self::tan:div,
                     preceding-sibling::tan:div) except $src-1st-da-data[$src]/tan:div[@ref = $start]/preceding-sibling::tan:div"/>
               <xsl:variable name="all-refs" select="$nodes/@ref"/>
               <xsl:variable name="min-refs"
                  select="$all-refs[string-length(replace(., '\w+', '')) = $top-hier-pos]"/>
               <xsl:choose>
                  <xsl:when test="$start-hier-pos gt $end-hier-pos">
                     <!-- If the beginning of a range is deeper in the hierarchy than the end, you need to add extra refs that
                     are peers of the beginning -->
                     <xsl:copy-of
                        select="
                           $all-refs[matches(., concat('^', replace($start, concat($separator-hierarchy-regex, '\w+', $separator-type-and-n-regex, '\w+', '$'), '')))][string-length(replace(., '\w+', '')) = $start-hier-pos],
                           $min-refs"
                     />
                  </xsl:when>
                  <xsl:when test="$end-hier-pos gt $start-hier-pos">
                     <!-- If the end of a range is deeper in the hierarchy than the beginning, you need to replace the
                     last item with refs that are peers of the end -->
                     <xsl:copy-of
                        select="
                           remove($min-refs, count($min-refs)),
                           $all-refs[matches(., concat('^', $min-refs[count($min-refs)]))][string-length(replace(., '\w+', '')) = $end-hier-pos]"
                     />
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="$min-refs"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:ref-rename" xml:id="f-ref-rename" as="xs:string?">
      <!-- Input: any normalized flatref as a string and a source, identified by number
         Output: that same reference transformed, changing old @type and @n values to new ones declared
         in the host declarations <rename> elements.
         E.g., "lib.Gn", 4 - > "bk.Gen"
      -->
      <xsl:param name="ref" as="xs:string?"/>
      <xsl:param name="src-no" as="xs:integer?"/>
      <xsl:variable name="ref-seq" select="tokenize($ref, $separator-hierarchy-regex)"/>
      <xsl:variable name="ref-seq-repl" as="xs:string*">
         <xsl:for-each select="$ref-seq">
            <xsl:variable name="this-ref" select="."/>
            <xsl:variable name="this-type"
               select="tokenize($this-ref, $separator-type-and-n-regex)[1]"/>
            <xsl:variable name="this-n" select="tokenize($this-ref, $separator-type-and-n-regex)[2]"/>
            <xsl:variable name="this-type-rename"
               select="$rename-div-types/tan:source[$src-no]/tan:rename[@old = $this-type]/@new"/>
            <xsl:variable name="this-n-rename-prep"
               select="
                  $rename-div-ns/tan:source[$src-no]/tan:div-type[@div-type = ($this-type-rename,
                  $this-type)[1]]"/>
            <xsl:variable name="this-n-rename"
               select="
                  if ($this-n-rename-prep/tan:rename[@old = $this-n]) then
                     $this-n-rename-prep/tan:rename[@old = $this-n]/@new
                  else
                     if ($this-n-rename-prep/tan:rename[@old = '#a'] and matches($this-n, $n-type-pattern[4])) then
                        (tan:aaa-to-int($this-n))
                     else
                        if ($this-n-rename-prep/tan:rename[@old = '#i'] and matches($this-n, $n-type-pattern[1])) then
                           (tan:rom-to-int($this-n))
                        else
                           ()"/>
            <xsl:value-of
               select="
                  concat(if (exists($this-type-rename)) then
                     $this-type-rename
                  else
                     $this-type, $separator-type-and-n, if (exists($this-n-rename)) then
                     $this-n-rename[1]
                  else
                     $this-n)"
            />
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($ref-seq-repl, $separator-hierarchy)"/>
   </xsl:function>

   <xsl:variable name="ucd-decomp" xml:id="v-ucd-decomp" select="doc('string-base-translate.xml')"/>
   <xsl:function name="tan:string-base" xml:id="f-string-base" as="xs:string?">
      <!-- This function takes any string and replaces every character with its base Unicode character.
      E.g., ἀνθρὠρους - > ανθρωρουσ
      This is useful for preparing text to be searched without respect to accents
      -->
      <xsl:param name="arg" as="xs:string?"/>
      <xsl:value-of
         select="translate($arg, $ucd-decomp/tan:translate/tan:mapString, $ucd-decomp/tan:translate/tan:transString)"
      />
   </xsl:function>

   <xsl:function name="tan:expand-search" xml:id="f-expand-search" as="xs:string?">
      <!-- This function takes a string representation of a regular expression pattern and replaces every unescaped
      character with a character class that lists all Unicode characters that would recursively decompose to that base
      character.
      E.g., 'word' - > '[wŵʷẁẃẅẇẉẘⓦｗ𝐰𝑤𝒘𝓌𝔀𝔴𝕨𝖜𝗐𝘄𝘸𝙬𝚠][oºòóôõöōŏőơǒǫǭȍȏȫȭȯȱᵒṍṏṑṓọỏốồổỗộớờởỡợₒℴⓞ㍵ｏ𝐨𝑜𝒐𝓸𝔬𝕠𝖔𝗈𝗼𝘰𝙤𝚘][rŕŗřȑȓʳᵣṙṛṝṟⓡ㎭㎮㎯ｒ𝐫𝑟𝒓𝓇𝓻𝔯𝕣𝖗𝗋𝗿𝘳𝙧𝚛][dďǆǳᵈḋḍḏḑḓⅆⅾⓓ㍲㍷㍸㍹㎗㏈ｄ𝐝𝑑𝒅𝒹𝓭𝔡𝕕𝖉𝖽𝗱𝘥𝙙𝚍]' 
      This function is useful for cases where it is more efficient to change the search term rather than to transform
      the text to be searched into base characters.
      -->
      <xsl:param name="regex" as="xs:string?"/>
      <xsl:variable name="output" as="xs:string*">
         <xsl:for-each select="1 to string-length($regex)">
            <xsl:variable name="pos" select="."/>
            <xsl:variable name="char" select="substring($regex, $pos, 1)"/>
            <xsl:variable name="prev-char" select="substring($regex, $pos - 1, 1)"/>
            <xsl:variable name="reverse-translate-match"
               select="$ucd-decomp/tan:translate/tan:reverse/tan:transString[text() = $char]"/>
            <xsl:choose>
               <xsl:when
                  test="$prev-char = '\' or ($prev-char != '\' and matches($char, $regex-escaping-characters))">
                  <xsl:value-of select="$char"/>
               </xsl:when>
               <xsl:when test="$reverse-translate-match">
                  <xsl:value-of
                     select="concat('[', $char, string-join($reverse-translate-match/tan:mapString, ''), ']')"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$char"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($output, '')"/>
   </xsl:function>

</xsl:stylesheet>
