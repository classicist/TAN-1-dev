<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>July 28, 2015</xd:p>
         <xd:p>Core variables and functions for class 2 TAN files (i.e., applicable to multiple
            class 2 TAN file types). Used by Schematron validation, but suitable for general use in
            other contexts </xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="TAN-core-functions.xsl"/>

   <!-- GENERAL -->
   <xsl:variable name="reference-errors"
      select="
         ('@ref must refer to leaf div',
         'reference cannot be found in source')"/>

   <!-- SOURCES -->
   <xsl:variable name="sources" select="$head/tan:source"/>
   <xsl:variable name="src-count" select="1 to count($sources)" as="xs:integer+"/>
   <xsl:variable name="source-lacks-id"
      select="
         if (name(/*) = 'TAN-LM') then
            true()
         else
            false()"/>
   <xsl:variable name="src-ids"
      select="
         if ($source-lacks-id) then
            '1'
         else
            $sources/@xml:id"/>
   <xsl:variable name="src-1st-da-locations"
      select="
         for $i in $sources/tan:location[doc-available(tan:resolve-url(.))][1]
         return
            tan:resolve-url($i)"/>
   <xsl:variable name="src-1st-da-heads"
      select="
         for $i in $src-1st-da-locations
         return
            document($i)/*/tan:head"/>
   <xsl:variable name="src-1st-da-data" select="tan:prep-class-1-data($src-1st-da-locations)"/>
   <xsl:variable name="src-1st-da-all-div-types" as="element()">
      <tan:all-div-types>
         <xsl:for-each select="$src-1st-da-heads">
            <tan:source>
               <xsl:copy-of select=".//tan:div-type"/>
            </tan:source>
         </xsl:for-each>
      </tan:all-div-types>
   </xsl:variable>

   <!-- DECLARATIONS -->

   <!-- DECLARATIONS: tokenization -->
   <xsl:variable name="tokenizations" select="$head/tan:declarations/tan:tokenization"/>
   <xsl:variable name="tokenizations-per-source" as="element()+">
      <!-- Sequence of one node/tree per source listing possible tokenizations, their first
         document-available location, and the languages covered:
         <tokenization>
            <location>[URL]</location>
            <for-lang>[LANG1 or *]<lang>
            <for-lang>[LANG2]<lang>
            ...
         </tokenization>-->
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xsl:element name="tan:source">
            <xsl:for-each
               select="
                  if ($source-lacks-id) then
                     $tokenizations
                  else
                     $tokenizations[$this-src = tan:src-ids-to-nos(@src)]">
               <xsl:variable name="this-tokz" select="."/>
               <xsl:variable name="this-tokz-1st-da-location">
                  <xsl:value-of
                     select="
                        (: ...if there's a location in the class 2 file, then... :)
                        if ($this-tokz/tan:location)
                        then
                           (: ...if one of them can be resolved, use that, otherwise... :)
                           if ($this-tokz/tan:location[doc-available(tan:resolve-url(.))])
                           then
                              $this-tokz/tan:location[doc-available(tan:resolve-url(.))][1]
                              (: ...Oops, there's no document available; but... :)
                           else
                              $tokenization-errors[5]
                        else
                           (: ...if there's no location, then look for @which; if present... :)
                           if ($this-tokz/@which)
                           (: ...go into the source tree and look for that value of @which in an @xml:id in a recommended-tokenization; if found... :)
                           then
                              if ($src-1st-da-heads[$this-src]/tan:declarations/tan:recommended-tokenization[@xml:id = $this-tokz/@which])
                              (: ...get the URL of the first doc available; if not found... :)
                              then
                                 $src-1st-da-heads[$this-src]/tan:declarations/tan:recommended-tokenization[@xml:id = $this-tokz/@which][1]/tan:location[doc-available(tan:resolve-url(.))][1]
                                 (: ...look for @which in the reserved keywords; if found... :)
                              else
                                 if (index-of($tokenization-which-reserved, $this-tokz/@which) gt 0)
                                 (: ...get the URL of the first document available; if URL is empty... :)
                                 then
                                    if ($tokenization-which-reserved-doc-available[index-of($tokenization-which-reserved, $this-tokz/@which)] = '')
                                    (: ...oops, core TAN-R-tok invoked, but no document available; if URL is not empty... :)
                                    then
                                       $tokenization-errors[3]
                                       (: ...then return the URL for the core TAN-R-tok file. :)
                                    else
                                       $tokenization-which-reserved-url[index-of($tokenization-which-reserved, $this-tokz/@which)]
                                       (: Oops, @which is neither in the source nor is it a reserved keyword :)
                                 else
                                    $tokenization-errors[2]
                                    (: Oops, there's no @which :)
                           else
                              $tokenization-errors[1]"
                  />
               </xsl:variable>
               <xsl:element name="tan:tokenization">
                  <xsl:element name="tan:location">
                     <xsl:value-of select="$this-tokz-1st-da-location"/>
                  </xsl:element>
                  <xsl:if test="doc-available($this-tokz-1st-da-location)">
                     <xsl:choose>
                        <xsl:when
                           test="document($this-tokz-1st-da-location)/tan:TAN-R-tok/tan:head/tan:declarations/tan:for-lang">
                           <xsl:copy-of
                              select="document($this-tokz-1st-da-location)/tan:TAN-R-tok/tan:head/tan:declarations/tan:for-lang"
                           />
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:element name="tan:for-lang">
                              <xsl:text>*</xsl:text>
                           </xsl:element>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:if>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="distinct-tokenizations" as="element()+">
      <!-- Sequence of one node/tree per tokenization used:
         <location>[URL]</location>
         <replace>[REPLACE NODE 1]</replace>
         <replace>[REPLACE NODE 2]</replace>
         ...
         <tokenize>[tokenize]</replace>-->
      <xsl:for-each select="distinct-values($tokenizations-per-source//tan:location)">
         <xsl:variable name="this-tokenization-location" select="."/>
         <xsl:element name="tan:tokenization">
            <xsl:element name="tan:location">
               <xsl:value-of select="$this-tokenization-location"/>
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
   <xsl:variable name="suppress-div-types" select="$head/tan:declarations/tan:suppress-div-types"/>
   <!-- Source div types to suppress ("book section ...","part folio ...", "", ...) -->
   <xsl:variable name="src-div-types-to-suppress"
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
   <xsl:variable name="src-div-types-to-suppress-reg-ex"
      select="
         for $i in $src-div-types-to-suppress
         return
            if ($i = '') then
               ''
            else
               concat('((', replace($i, '\s+', '|'), '))', $separator-type-and-n-regex, '\w*', $separator-hierarchy-regex, '?')"/>

   <!-- DECLARATIONS: implicit-div-type-refs -->
   <xsl:variable name="src-impl-div-types"
      select="
         if ($head/tan:declarations/tan:implicit-div-type-refs)
         then
            tan:src-ids-to-nos($head/tan:declarations/tan:implicit-div-type-refs/@src)
         else
            ()"/>

   <!-- DECLARATIONS: rename-div-types -->
   <xsl:variable name="rename-div-types" as="element()">
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
   <xsl:variable name="rename-div-ns" as="element()">
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
   <!-- Patterns to detect those @n types -->
   <xsl:variable name="n-type-pattern"
      select="
         (concat('^(', $roman-numeral-pattern, ')$'),
         '^(\d+)$',
         concat('^(\d+)(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')(\d+)$'),
         '(.)')"/>
   <!-- Calculated types of @n values per div type per source -->
   <xsl:variable name="div-type-ord-check" as="element()">
      <tan:div-types-ord-check>
         <xsl:for-each select="$src-1st-da-all-div-types/tan:source">
            <xsl:variable name="this-src" select="count(preceding-sibling::tan:source) + 1"/>
            <tan:source>
               <xsl:for-each select="tan:div-type">
                  <xsl:variable name="this-div-type" select="@xml:id"/>
                  <xsl:variable name="this-ns"
                     select="
                        doc($src-1st-da-locations[$this-src])//(tan:div,
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
   <xsl:function name="tan:counts-to-lasts" as="xs:integer*">
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
   <xsl:function name="tan:counts-to-firsts" as="xs:integer*">
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
   <xsl:function name="tan:normalize-refs" as="xs:string?">
      <!-- Input: string value of @ref that explicitly uses div types
         Output: punctuation- and space-normalized reference string
         E.g., "bk/Gen ch.1 epigraph.   , bk^Gen ch,5   - bk,Gen ch?7" -> "bk.Gen:ch.1:epigraph. , bk.Gen:ch.5 - bk.Gen:ch.7" 
      -->
      <xsl:param name="arg" as="xs:string?"/>
      <xsl:value-of
         select="
            string-join(for $i in tokenize($arg, '\s*,\s+')
            return
               string-join(for $j in tokenize($i, '\s+-\s+')
               return
                  tan:normalize-ref-punctuation($j), ' - '), ' , ')"
      />
   </xsl:function>
   <xsl:function name="tan:normalize-ref-punctuation" as="xs:string">
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
   <xsl:function name="tan:normalize-impl-refs" as="xs:string?">
      <!-- Input: (1) string value of @ref where div types are implicit; (2) source number
         Output: type-, punctuation-, and space-normalized reference string
         E.g., "Gen 4 1   , Gen:2:5   - Gen 2?7" -> "bk.Gen:ch.1:v.1 , bk.Gen:ch.2:v.5 - bk.Gen:ch.2:v.7" 
      -->
      <xsl:param name="arg1" as="xs:string?"/>
      <xsl:param name="arg2" as="xs:integer?"/>
      <xsl:value-of
         select="
            string-join(for $i in tokenize($arg1, '\s*,\s+')
            return
               string-join(for $j in tokenize($i, '\s+-\s+')
               return
                  ($src-1st-da-data[$arg2]//tan:div[@impl-ref = replace($j, '\W', $separator-hierarchy)]/@ref,
                  replace($j, '\W', $separator-hierarchy),
                  $j)[1], ' - '), ' , ')"
      />
   </xsl:function>
   <xsl:function name="tan:ref-range-check" as="xs:boolean*">
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
   <xsl:function name="tan:ordinal" as="xs:string+">
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
   <xsl:function name="tan:sequence-expand" as="xs:integer*">
      <!-- input: one string of concise TAN selectors (used by @ords, @chars, @segs), 
            and one integer defining the value of 'last'
            output: a sequence of numbers representing the positions selected, unsorted, and retaining
            duplicate values.
            E.g., ("2 - 4, last-5 - last, 36", 50) -> (2, 3, 4, 45, 46, 47, 48, 49, 50, 36)
        -->
      <xsl:param name="selector" as="xs:string?"/>
      <xsl:param name="max" as="xs:integer?"/>
      <xsl:variable name="selector-norm" select="replace($selector, 'last', string($max))"/>
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
   <xsl:function name="tan:max-integer" as="xs:integer?">
      <!-- input: string of TAN @ord or @chars selectors 
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
   <xsl:function name="tan:min-last" as="xs:integer">
      <!-- input: @ord or @chars selectors, number defining "last" 
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

   <!-- CONTEXT DEPENDENT FUNCTIONS -->
   <xsl:function name="tan:src-ids-to-nos" as="xs:integer*">
      <!-- Input: values of @src (@xml:id values of sources)
      Output: sequence of integers for all sources 
      If input is an empty string, or the format lacks ids for sources, output = 1
      E.g., ('src-a src-d', 'src-b src-d') - > (1, 4, 2, 4)
      () - > 1
      -->
      <xsl:param name="att-src" as="xs:string*"/>
      <xsl:choose>
         <xsl:when test="exists($att-src) and not($source-lacks-id)">
            <xsl:for-each select="$att-src">
               <xsl:variable name="this-src-string" select="."/>
               <xsl:copy-of
                  select="
                     for $i in tokenize($this-src-string, '\s+')
                     return
                        index-of($src-ids, $i)"
               />
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="1"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tan:prep-class-1-data" as="element()*">
      <!-- Input: sequence of URLs for class 1 TAN sources
         Output: sequence of one node/tree per source flattening the data into this form:
         <div @old-ref="[NORMALIZED, FLATTENED REF]" @ref="[NORMALIZED, FLATTENED 
         REF WITH TYPE AND N SUBSTITUTIONS AND SUPPRESSIONS]" @impl-ref="[AS @ref BUT 
         ONLY @n VALUES, NOT @type]" @lang="[LANG]">[TEXT, IF ANY][2ND COPY WITH ORIGINAL 
         TEI MARKUP, IF ANY]</div>
         No @lang if not a leaf div
      -->
      <xsl:param name="urls" as="xs:string*"/>
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xsl:element name="tan:source">
            <xsl:attribute name="id" select="$src-ids[$this-src]"/>
            <xsl:for-each select="document($urls[$this-src])//(tei:div | tan:div)">
               <xsl:variable name="this-div" select="."/>
               <xsl:variable name="is-leaf-div"
                  select="
                     if (child::tan:div | child::tei:div) then
                        false()
                     else
                        true()"/>
               <xsl:variable name="this-flatref" select="tan:flatref($this-div)"/>
               <xsl:variable name="this-flatref-converted"
                  select="
                     if ($src-div-types-to-suppress-reg-ex[$this-src] = '') then
                        tan:ref-rename($this-flatref, $this-src)
                     else
                        replace(tan:ref-rename($this-flatref, $this-src), $src-div-types-to-suppress-reg-ex[$this-src], '')"/>
               <xsl:variable name="this-flatref-converted-without-div-types"
                  select="replace($this-flatref-converted, concat('\w+', $separator-type-and-n-regex), '')"/>
               <xsl:element name="tan:div">
                  <xsl:attribute name="old-ref" select="$this-flatref"/>
                  <xsl:attribute name="ref" select="$this-flatref-converted"/>
                  <xsl:attribute name="impl-ref" select="$this-flatref-converted-without-div-types"/>
                  <xsl:if test="$is-leaf-div">
                     <xsl:attribute name="lang"
                        select="$this-div/ancestor-or-self::*[attribute::xml:lang][1]/@xml:lang"/>
                  </xsl:if>
                  <!-- raw text -->
                  <xsl:copy-of
                     select="
                        if ($is-leaf-div)
                        then
                           normalize-space(string($this-div))
                        else
                           ()"/>
                  <!-- second copy with TEI markup, if any -->
                  <xsl:copy-of
                     select="
                        if ($is-leaf-div and $this-div/descendant-or-self::tei:*) then
                           $this-div//*
                        else
                           ()"
                  />
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:pick-prepped-class-1-data" as="element()*">
      <!-- Used to create a subset of $src-1st-da-data (the result of tan:prep-class-1-data()) 
         Input: integer* (source numbers), string* (normalized reference sequences [atoms joined by 
         hyphens or commas], one per source)
         Output: nodes, 1 per source, proper subset of tan:prep-class-1-data()
      -->
      <xsl:param name="this-src-list" as="xs:integer*"/>
      <xsl:param name="this-refs-norm" as="xs:string*"/>
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xsl:element name="tan:source">
            <xsl:attribute name="id" select="$src-ids[$this-src]"/>
            <xsl:if test="$this-src = $this-src-list">
               <xsl:for-each
                  select="tokenize($this-refs-norm[index-of($this-src-list, $this-src)], ' , ')">
                  <xsl:variable name="this-ref" select="."/>
                  <xsl:choose>
                     <xsl:when
                        test="
                           exists(for $i in tokenize($this-ref, ' - ')
                           return
                              $src-1st-da-data[$this-src]/tan:div[@ref = $i])">
                        <xsl:choose>
                           <xsl:when test="matches($this-ref, ' - ')">
                              <xsl:copy-of
                                 select="
                                    $src-1st-da-data[$this-src]/((tan:div[@ref = tokenize($this-ref, ' - ')[1]]/(self::node(),
                                    following-sibling::tan:div))
                                    except (tan:div[@ref = tokenize($this-ref, ' - ')[2]]/following-sibling::tan:div))"
                              />
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:copy-of
                                 select="$src-1st-da-data[$this-src]/tan:div[@ref = $this-ref]"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:element name="tan:div">
                           <xsl:attribute name="ref" select="$this-ref"/>
                           <xsl:attribute name="error" select="true()"/>
                           <xsl:value-of select="$reference-errors[2]"/>
                        </xsl:element>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
            </xsl:if>
         </xsl:element>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:tokenize-prepped-class-1-data" as="element()+">
      <!-- Input: element()+ resulting from tan:pick-prepped-class-1-data() 
         or tan:prep-class-1-data()
         Output: elements, 1 per source, deep copy of input, but dropping 
         tan:div/@lang and tokenizing all tan:div content into tokens, delimited 
         by tan:div/tan:tok. If no tokenization pattern exists for a language, 
         the node is copied with the @error="true" and an error message replacing 
         the text of the leaf div.-->
      <xsl:param name="this-prepped-c1-data" as="element()+"/>
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xsl:element name="tan:source">
            <xsl:attribute name="id" select="$src-ids[$this-src]"/>
            <xsl:for-each select="$this-prepped-c1-data[$this-src]/tan:div">
               <xsl:variable name="this-div" select="."/>
               <xsl:element name="tan:div">
                  <xsl:copy-of select="@*"/>
                  <xsl:if test="@lang">
                     <xsl:variable name="this-lang" select="@lang"/>
                     <xsl:choose>
                        <xsl:when
                           test="
                              $tokenizations-per-source[$this-src]/tan:tokenization[tan:for-lang = ('*',
                              $this-lang)]">
                           <xsl:variable name="this-tokz"
                              select="
                                 $tokenizations-per-source[$this-src]/tan:tokenization[tan:for-lang = ('*',
                                 $this-lang)][1]/tan:location"/>
                           <xsl:variable name="this-replaces"
                              select="$distinct-tokenizations[tan:location = $this-tokz]/tan:replace"/>
                           <xsl:variable name="this-tokenize"
                              select="$distinct-tokenizations[tan:location = $this-tokz]/tan:tokenize"/>
                           <xsl:for-each
                              select="tan:tokenize(tan:replace-sequence($this-div/text(), $this-replaces), $this-tokenize)">
                              <xsl:element name="tan:tok">
                                 <xsl:value-of select="."/>
                              </xsl:element>
                           </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:attribute name="lang" select="$this-lang"/>
                           <xsl:attribute name="error" select="true()"/>
                           <xsl:value-of select="$tokenization-errors[4]"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:if>
                  <xsl:copy-of select="descendant-or-self::tei:*"/>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:pick-tokenized-prepped-class-1-data" as="element()*">
      <!-- Input: tan:tok, complete with @src, @ref, @ord|@val 
         Output: elements, 1 per source, deep copy of appropriate tree generated 
         by tan:tokenize-prepped-class-1-data(), except that <tok> now takes
         @n (digit specifying original token number in the leaf div) -->
      <xsl:param name="tok-element" as="element()"/>
      <xsl:variable name="this-src-list" select="tan:src-ids-to-nos($tok-element/@src)"/>
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
            if ($tok-element/@ord) then
               normalize-space(replace($tok-element/@ord, '\?', ''))
            else
               ()"/>
      <xsl:variable name="this-val"
         select="
            if ($tok-element/@val) then
               normalize-space($tok-element/@val)
            else
               ()"/>
      <xsl:variable name="src-ref-subset"
         select="tan:pick-prepped-class-1-data($this-src-list, $this-refs-norm)"/>
      <xsl:variable name="src-ref-subset-tokenized"
         select="tan:tokenize-prepped-class-1-data($src-ref-subset)"/>
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xsl:element name="tan:source">
            <xsl:attribute name="id" select="$src-ids[$this-src]"/>
            <xsl:for-each select="$src-ref-subset-tokenized[$this-src]/tan:div">
               <xsl:variable name="this-div" select="."/>
               <xsl:element name="tan:div">
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="max-toks" select="count($this-div/tan:tok)"/>
                  <xsl:variable name="this-last"
                     select="
                        if (exists($this-val))
                        then
                           count(tan:tok[. = $this-val])
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
                     <xsl:choose>
                        <xsl:when test="exists($this-val)">
                           <xsl:variable name="this-tok"
                              select="$this-div/tan:tok[. = $this-val][$this-ord-item]"/>
                           <xsl:element name="tan:tok">
                              <xsl:attribute name="n"
                                 select="count($this-tok/preceding-sibling::tan:tok) + 1"/>
                              <xsl:if test="not(exists($this-tok))">
                                 <xsl:attribute name="error"
                                    select="concat($this-val, ' ', $this-ord-item)"/>
                              </xsl:if>
                              <xsl:value-of select="$this-tok"/>
                           </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:variable name="this-tok" select="$this-div/tan:tok[$this-ord-item]"/>
                           <xsl:element name="tan:tok">
                              <xsl:attribute name="n" select="$this-ord-item"/>
                              <xsl:if test="not(exists($this-tok))">
                                 <xsl:attribute name="error" select="$this-ord-item"/>
                              </xsl:if>
                              <xsl:value-of select="$this-tok"/>
                           </xsl:element>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:itemize-refs" as="xs:string*">
      <!-- Turns a compound ref string into a sequence of atomized refs according to the source provided
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

   <xsl:function name="tan:ref-rename" as="xs:string?">
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
                     $this-n-rename
                  else
                     $this-n)"
            />
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($ref-seq-repl, $separator-hierarchy)"/>
   </xsl:function>

</xsl:stylesheet>
