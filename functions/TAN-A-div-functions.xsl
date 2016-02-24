<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Revised</xd:b>Aug 28, 2015</xd:p>
         <xd:p>Core functions for TAN-A-div files. Written principally for Schematron validation,
            but suitable for general use in other contexts</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="TAN-class-2-functions.xsl"/>
   <xsl:variable name="srcs-whose-tokens-are-defined" select="tan:src-ids-to-nos($head/tan:declarations/tan:token-definition/@src)"/>
   <xsl:variable name="src-1st-da-data-segmented"
      select="tan:segment-tokenized-prepped-class-1-data(tan:tokenize-prepped-class-1-data($src-1st-da-data))"/>
   <xsl:variable name="equate-works" as="xs:integer+">
      <!-- this variable retains a list of integers, one per source, indicating groups of works -->
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="this-src-work-iris"
            select="$src-1st-da-heads[$this-src]/tan:declarations/tan:work/tan:IRI"/>
         <xsl:variable name="these-eq-works"
            select="$body/tan:equate-works[$this-src = tan:src-ids-to-nos(@src)]/@src"/>
         <xsl:value-of
            select="
               if ($this-src gt 1 and exists($these-eq-works)) then
                  min(tan:src-ids-to-nos($these-eq-works))
               else
                  min(($this-src,
                  (for $i in (1 to $this-src - 1)
                  return
                     if ($src-1st-da-heads[$i]//tan:work/tan:IRI = $this-src-work-iris) then
                        $i
                     else
                        ())))"
         />
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="work-iris" as="element()*">
      <tan:work-iris>
         <xsl:for-each-group select="$src-count" group-by="$equate-works[current()]">
            <xsl:variable name="these-iris" as="element()*">
               <xsl:for-each select="current-group()">
                  <xsl:variable name="this-src" select="."/>
                  <xsl:sequence
                     select="$src-1st-da-heads[$this-src]/tan:declarations/tan:work/tan:IRI"/>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="distinct-iris" select="distinct-values($these-iris)"/>
            <tan:work n="{current-grouping-key()}">
               <xsl:for-each select="$distinct-iris">
                  <tan:IRI>
                     <xsl:value-of select="."/>
                  </tan:IRI>
               </xsl:for-each>
            </tan:work>
         </xsl:for-each-group>
      </tan:work-iris>
   </xsl:variable>
   <xsl:variable name="equate-div-types-sorted" as="element()*">
      <xsl:for-each select="$body/tan:equate-div-types">
         <xsl:variable name="this-edt" select="."/>
         <tan:equate-div-types>
            <xsl:for-each select="tan:div-type-ref">
               <xsl:variable name="this-div-type" select="."/>
               <xsl:for-each select="tan:src-ids-to-nos(@src)">
                  <xsl:variable name="this-src" select="."/>
                  <xsl:for-each select="tokenize($this-div-type/@div-type-ref, '\W+')">
                     <xsl:variable name="this-id" select="."/>
                     <xsl:variable name="this-id-orig"
                        select="$rename-div-types/tan:source[$this-src]/tan:rename[@new = $this-id]/@old"/>
                     <tan:div-type-ref src-no="{$this-src}" div-type-ref="{$this-id}"
                        eq-id="{($src-1st-da-all-div-types/tan:source[$this-src]/tan:div-type[@xml:id = ($this-id,$this-id-orig)]/@eq-id)[1]}"
                     />
                  </xsl:for-each>
               </xsl:for-each>
            </xsl:for-each>
         </tan:equate-div-types>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="src-1st-da-div-types-equiv-replace" as="node()+">
      <!-- Sequence of one element per source, then one element per div-type, correlating @xml:id or its renamed 
         value with an integer for the position of the first div-type within all div-types that share 
         an IRI value -->
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xml:source>
            <xsl:for-each select="$src-1st-da-all-div-types/tan:source[$this-src]/tan:div-type">
               <xsl:variable name="this-div-type" select="."/>
               <xsl:variable name="this-div-type-orig" select="@xml:id"/>
               <xsl:variable name="this-div-type-alias"
                  select="$rename-div-types/tan:source[$this-src]/tan:rename[@old = $this-div-type-orig]/@new"/>
               <xsl:variable name="this-div-type-id"
                  select="
                     ($this-div-type-alias,
                     $this-div-type-orig)[1]"/>
               <xsl:variable name="edts"
                  select="$equate-div-types-sorted[tan:div-type-ref[@src-no = $this-src][@div-type-ref = $this-div-type-id]]/tan:div-type-ref/@eq-id"
                  as="xs:integer*"/>
               <xsl:variable name="this-div-eq-id"
                  select="
                     if (exists($edts)) then
                        string(min(for $i in $edts
                        return
                           number($i)))
                     else
                        $this-div-type/@eq-id"/>
               <tan:replace>
                  <tan:pattern>
                     <xsl:value-of
                        select="concat('^', $this-div-type-id, '\.|:', $this-div-type-id, '\.')"/>
                  </tan:pattern>
                  <tan:replacement>
                     <xsl:value-of select="concat(':', $this-div-eq-id, '.')"/>
                  </tan:replacement>
               </tan:replace>
            </xsl:for-each>
            <tan:replace>
               <!-- Used to strip out leading punctuation -->
               <tan:pattern>^:</tan:pattern>
               <tan:replacement/>
            </tan:replace>
         </xml:source>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="leaf-div-splits-raw" as="element()*">
      <!-- one element per <tok> that is a child of <split-leaf-divs-at>. Used to check for
      duplicates and to prepare texts for leaf div segmentation. -->
      <xsl:for-each select="$body/tan:split-leaf-div-at/tan:tok">
         <xsl:copy>
            <xsl:copy-of
               select="
                  if (tan:help-requested(.)) then
                     ()
                  else
                     tan:pick-tokenized-prepped-class-1-data(.)"
            />
         </xsl:copy>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="leaf-div-splits-grouped" as="element()*">
      <xsl:for-each-group select="$leaf-div-splits-raw/tan:source/tan:div/tan:tok"
         group-by="../../@id">
         <xsl:sort select="index-of($src-ids, current-grouping-key())"/>
         <tan:source id="{current-grouping-key()}">
            <xsl:for-each-group select="current-group()" group-by="../@ref">
               <tan:div>
                  <xsl:copy-of select="current-group()/../@*"/>
                  <xsl:for-each select="current-group()">
                     <xsl:sort select="number(@n)"/>
                     <xsl:copy-of select="."/>
                  </xsl:for-each>
               </tan:div>
            </xsl:for-each-group>
         </tan:source>
      </xsl:for-each-group>
   </xsl:variable>
   <xsl:variable name="realigns-normalized"
      select="
         for $i in $body/tan:realign
         return
            tan:normalize-realign($i)"/>


   <!-- CONTEXT INDEPENDENT FUNCTIONS -->
   
   <xsl:function name="tan:replace-sequence" as="xs:string?">
      <!-- Input: single string and a sequence of tan:replace elements.
         Output: string that results from each tan:replace being sequentially applied to the input string.
         Used to calculate series of changes to be made to a single flatref. -->
      <xsl:param name="text" as="xs:string?"/>
      <xsl:param name="replace" as="element()+"/>
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
   
   <!-- CONTEXT DEPENDENT FUNCTIONS -->

   <xsl:function name="tan:segment-tokenized-prepped-class-1-data" as="element()+">
      <!-- Input: element()+ resulting from tan:tokenize-prepped-class-1-data()
      Output: elements, one per source, deep copy of input, but inserting <tan:seg> between 
      <tan:div> and <tan:tok>, reflecting all <split-leaf-div-at>s-->
      <xsl:param name="this-tokd-prepped-c1-data" as="element()+"/>
      <xsl:for-each select="$this-tokd-prepped-c1-data">
         <xsl:variable name="this-src-id" select="@id"/>
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="tan:div">
               <xsl:choose>
                  <xsl:when test="@lang and tan:tok">
                     <xsl:variable name="this-div" select="."/>
                     <xsl:variable name="this-div-splits"
                        select="
                           for $i in $leaf-div-splits-grouped[@id = $this-src-id]/tan:div[@ref = $this-div/@ref]/tan:tok[not(@error)]/@n
                           return
                              xs:integer($i)"/>
                     <xsl:variable name="this-div-seg-starts"
                        select="
                           (1,
                           $this-div-splits)"/>
                     <xsl:variable name="this-div-seg-ends"
                        select="
                           ((for $i in $this-div-splits
                           return
                              $i - 1),
                           count($this-div/tan:tok))"/>
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:for-each select="(1 to count($this-div-splits) + 1)">
                           <xsl:variable name="pos" select="."/>
                           <xsl:variable name="start" select="$this-div-seg-starts[$pos]"/>
                           <xsl:variable name="end" select="$this-div-seg-ends[$pos]"/>
                           <seg n="{position()}">
                              <xsl:copy-of
                                 select="$this-div/tan:tok[$start]/(self::*, following-sibling::*) 
                                 except $this-div/tan:tok[$end]/following-sibling::tan:tok[1]/(self::*, following-sibling::*)"
                              />
                           </seg>
                        </xsl:for-each>
                        <xsl:sequence select="tei:*"/>
                     </xsl:copy>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="."/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:expand-div-ref" as="element()*">
      <!-- takes one <div-ref> or <anchor-div-ref> and returns one <div-ref> per source per
      ref per segment, replacing @src with numerical value, @ref with normalized single reference, and 
      @seg (if present) with a single number. If the second parameter is true() a @work attribute is
      added with the integer value of the work. A copy of the original reference is retained, in case
      the original formula is needed.
      E.g., (<div-ref src="A B" ref="1 - 2" seg="1, last"/>, true()) - > (<div-ref work="1" src="1" ref="line.1" seg="1" orig-ref="1 - 2"/>, 
      <div-ref work="1" src="1" ref="line.1" seg="7" orig-ref="1 - 2"/>, <div-ref work="1" src="1" ref="line.2" seg="1" orig-ref="1 - 2"/>,
      <div-ref work="1" src="1" ref="line.1" seg="3" orig-ref="1 - 2"/>, <div-ref work="1" src="2" ref="line.1" seg="1" orig-ref="1 - 2"/>, ...) -->
      <xsl:param name="div-ref-element" as="element()?"/>
      <xsl:param name="include-work" as="xs:boolean"/>
      <xsl:variable name="these-srcs" select="tan:src-ids-to-nos($div-ref-element/@src)"/>
      <xsl:for-each select="$these-srcs">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="this-ref-norm"
            select="
               if ($this-src = $src-impl-div-types) then
                  tan:normalize-impl-refs($div-ref-element/@ref, $this-src)
               else
                  tan:normalize-refs($div-ref-element/@ref)"/>
         <xsl:variable name="this-ref-expand"
            select="
               if ($div-ref-element/@seg) then
                  tan:itemize-leaf-refs($this-ref-norm, $this-src)
               else
                  tan:itemize-bare-refs($this-ref-norm, $this-src)"/>
         <xsl:for-each select="$this-ref-expand">
            <xsl:variable name="this-ref" select="."/>
            <xsl:variable name="these-segs" as="xs:integer+">
               <xsl:choose>
                  <xsl:when test="$div-ref-element/@seg">
                     <xsl:variable name="seg-count"
                        select="count($src-1st-da-data-segmented[$this-src]/tan:div[@ref = $this-ref]/tan:seg)"/>
                     <xsl:copy-of select="tan:sequence-expand($div-ref-element/@seg, $seg-count)"/>
                  </xsl:when>
                  <xsl:otherwise>-1</xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:for-each select="$these-segs">
               <xsl:element name="tan:div-ref">
                  <xsl:copy-of
                     select="
                        $div-ref-element/(@ed-when,
                        @ed-who,
                        @strength)"/>
                  <xsl:if test="$include-work = true()">
                     <xsl:attribute name="work" select="$equate-works[$this-src]"/>
                  </xsl:if>
                  <xsl:attribute name="src" select="$this-src"/>
                  <xsl:attribute name="ref" select="$this-ref"/>
                  <xsl:if test=". gt 0">
                     <xsl:attribute name="seg" select="."/>
                  </xsl:if>
                  <xsl:attribute name="orig-ref" select="$div-ref-element/@ref"/>
               </xsl:element>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:for-each>

   </xsl:function>
   <xsl:function name="tan:normalize-realign" as="item()*">
      <!-- Takes one tan:realign element and returns a normalized version, taking into account rules for
         distribution and <anchor-div-ref>. The result follows this pattern:
      <tan:realign [+ANY ATTRIBUTES]> [ONE PER REALIGNMENT, IF DISTRIBUTED]
         <tan:div-ref src="[SOURCE NUMBER]" ref="[SINGLE REF]" seg="[SINGLE SEGMENT NUMBER; IF NO SEGMENTATION, 
         THIS ATTRIBUTE IS MISSING]"> [SORTED BY SOURCE NUMBER THEN @ref, @seg]
      NB, <tan:realign error="true"> collects div-refs that cannot be allocated in required one-to-one matches.
      -->
      <xsl:param name="realign-element" as="element()?"/>
      <xsl:variable name="anchor"
         select="tan:expand-div-ref($realign-element/tan:anchor-div-ref, false())"/>
      <xsl:variable name="expanded-div-refs" as="element()*"
         select="
            for $i in $realign-element/tan:div-ref
            return
               tan:expand-div-ref($i, false())"/>
      <xsl:variable name="has-anchor"
         select="
            if ($realign-element/tan:anchor-div-ref) then
               true()
            else
               false()"/>
      <xsl:variable name="these-srcs" select="distinct-values($expanded-div-refs/@src)"/>
      <xsl:variable name="count-per-src"
         select="
            for $i in $these-srcs
            return
               count($expanded-div-refs[@src = $i])"/>
      <xsl:variable name="realign-count"
         select="
            if ($has-anchor) then
               min(($count-per-src,
               count($anchor)))
            else
               min($count-per-src)"/>
      <xsl:variable name="distributions-max"
         select="
            if ($has-anchor) then
               max(($count-per-src,
               count($anchor)))
            else
               max($count-per-src)"/>
      <xsl:variable name="distribution-required"
         select="
            if (((count($count-per-src) = 1) and (not($has-anchor)))
            or (count($anchor) = 1)) then
               false()
            else
               true()"/>
      <xsl:for-each select="1 to $realign-count">
         <xsl:variable name="this-key" select="."/>
         <tan:realign>
            <xsl:copy-of select="$realign-element/@*"/>
            <xsl:if test="$has-anchor">
               <tan:anchor-div-ref>
                  <xsl:copy-of select="$anchor[$this-key]/@*"/>
               </tan:anchor-div-ref>
            </xsl:if>
            <xsl:choose>
               <xsl:when test="$distribution-required">
                  <xsl:for-each select="$these-srcs">
                     <xsl:variable name="this-src" select="."/>
                     <xsl:copy-of select="$expanded-div-refs[@src = $this-src][$this-key]"/>
                  </xsl:for-each>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="$expanded-div-refs"/>
               </xsl:otherwise>
            </xsl:choose>
         </tan:realign>
      </xsl:for-each>
      <xsl:if test="$distribution-required and ($distributions-max gt $realign-count)">
         <tan:realign error="{true()}">
            <xsl:copy-of
               select="
                  for $i in (($realign-count + 1) to $distributions-max),
                     $j in $these-srcs
                  return
                     $expanded-div-refs[@src = $j][$i]"
            />
         </tan:realign>
      </xsl:if>
   </xsl:function>
   <xsl:function name="tan:normalize-align" as="element()*">
      <!-- Takes one or more tan:align elements and returns a normalized version, taking into account @distribute and
      @exclusive claims. The result of each resolved tan:align follows this pattern:
      <tan:align [+ANY ATTRIBUTES]> [IF DISTRIBUTED, ONE tan:align PER ATOMIC REF PER tan:div-ref; IF A DISTRIBUTION DOES NOT
      MATCH EVERYTHING ONE-TO-ONE, THEN ATTRIBUTE @error="true" IS PROVIDED]
         <tan:group [IF (@exclusive) THEN] src="[SOURCE NUMBER]" [ELSE] work="[WORK NUMBER]"
         orig-ref="[THE ORIGINAL REFERENCES FOR THIS WORK OR SOURCE, STRING-JOINED BY COMMAS]">
            <tan:div-ref work="[WORK NUMBER]" src="[SOURCE NUMBER]" ref="[SINGLE REF]" seg="[SINGLE SEGMENT NUMBER; IF NO SEGMENTATION, 
            THIS ATTRIBUTE IS MISSING] orig-ref="[THE ORIGINAL REFERENCES FOR THIS WORK OR SOURCE, STRING-JOINED BY COMMAS]
            eq-ref="[CONVERSION OF REFERENCE TO A NORMALIZED REFERENCE SYSTEM, TO BE USED TO COMPARE AND MATCH OTHER DIVS]">
      tan:div-refs will be sorted by document order 
      NB, <tan:align error="true"> collects div-refs that cannot be allocated in one-to-one matches demanded by
      the presence of @distribute
      -->
      <xsl:param name="align-element" as="element()*"/>
      <xsl:variable name="is-exclusive"
         select="
            if ($align-element/@exclusive) then
               true()
            else
               false()"/>
      <xsl:variable name="group-div-refs-pass-1" as="element()*">
         <xsl:for-each select="$align-element">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:for-each-group select="tan:div-ref"
                  group-by="count(preceding-sibling::*[not(@cont)])">
                  <xsl:variable name="these-srcs"
                     select="
                        distinct-values(for $i in current-group()/@src,
                           $j in tokenize($i, '\s+')
                        return
                           index-of($src-ids, $j))"
                  />
                  <xsl:variable name="expanded-div-refs" as="element()*"
                     select="
                        for $i in current-group()
                        return
                           tan:expand-div-ref($i, not($is-exclusive))"/>
                  <tan:group>
                     <xsl:copy-of select="(current-group()//@strength)[1]"/>
                     <xsl:choose>
                        <xsl:when test="$is-exclusive">
                           <xsl:attribute name="src" select="$these-srcs"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:attribute name="work"
                              select="
                                 distinct-values(for $i in $these-srcs
                                 return
                                    $equate-works[$i])"
                           />
                        </xsl:otherwise>
                     </xsl:choose>
                     <xsl:attribute name="orig-ref">
                        <xsl:value-of
                           select="string-join(distinct-values($expanded-div-refs//@orig-ref), ', ')"
                        />
                     </xsl:attribute>
                     <xsl:for-each select="$expanded-div-refs">
                        <xsl:sort
                           select="number($src-1st-da-data-segmented[number(current()/@src)]/tan:div[@ref = current()/@ref]/@pos)"/>
                        <xsl:copy>
                           <xsl:copy-of select="@*"/>
                           <xsl:attribute name="eq-ref" select="tan:equate-ref(@src, @ref, @seg)[1]"
                           />
                        </xsl:copy>
                     </xsl:for-each>
                  </tan:group>
               </xsl:for-each-group>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="group-div-refs-pass-2" as="element()*">
         <xsl:for-each select="$group-div-refs-pass-1">
            <xsl:variable name="this-align" select="."/>
            <xsl:variable name="is-distributed"
               select="
                  if (@distribute) then
                     true()
                  else
                     false()"/>
            <xsl:choose>
               <xsl:when test="$is-distributed">
                  <xsl:variable name="items-per-group"
                     select="
                        for $i in tan:group
                        return
                           count($i/*)"/>
                  <xsl:variable name="min-items-per-group" select="min($items-per-group)"/>
                  <xsl:for-each select="1 to max($items-per-group)">
                     <xsl:variable name="this-align-no" select="."/>
                     <tan:align>
                        <xsl:copy-of select="$this-align/@*"/>
                        <xsl:if test="$this-align-no gt $min-items-per-group">
                           <xsl:attribute name="error" select="true()"/>
                        </xsl:if>
                        <xsl:for-each select="$this-align/tan:group[tan:div-ref[$this-align-no]]">
                           <xsl:copy>
                              <xsl:copy-of select="@*"/>
                              <xsl:copy-of select="tan:div-ref[$this-align-no]"/>
                           </xsl:copy>
                        </xsl:for-each>
                     </tan:align>
                  </xsl:for-each>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy-of select="$group-div-refs-pass-2"/>
   </xsl:function>

   <xsl:function name="tan:convert-ns-to-numerals" as="xs:string">
      <!-- converts a flattened ref's @n values to numerals according to their use in a given source
            Input: single flatref as a string, source number as integer
            Output: revised flatref, substituting @n values for numerals where appropriate
            E.g., ('bk.xxiv:ch.2b', 1) - > 'bk.24:ch.2#2'
        -->
      <xsl:param name="norm-flatref" as="xs:string"/>
      <xsl:param name="src-no" as="xs:integer"/>
      <xsl:variable name="type-n-pairs" select="tokenize($norm-flatref, $separator-hierarchy-regex)"/>
      <xsl:variable name="type-n-pairs-converted"
         select="
            for $i in $type-n-pairs
            return
               concat(tokenize($i, $separator-type-and-n-regex)[1], $separator-type-and-n,
               tan:replace-ns(tokenize($i, $separator-type-and-n-regex)[1], tokenize($i, $separator-type-and-n-regex)[2], $src-no))"/>
      <xsl:value-of select="string-join($type-n-pairs-converted, $separator-hierarchy)"/>
   </xsl:function>
   <xsl:function name="tan:replace-ns" as="xs:string">
      <!-- Input: single value of @type and @n, source number
      Output: single string replacing (or not) the value of @n with its Arabic numerical equivalent as appropriate 
      and as a string.
      E.g., ('bk', 'xxiv', 1) - > '24' -->
      <xsl:param name="param-div-type" as="xs:string?"/>
      <xsl:param name="param-div-n" as="xs:string?"/>
      <xsl:param name="param-src-no" as="xs:integer"/>
      <xsl:variable name="this-n-type"
         select="$div-type-ord-check/tan:source[$param-src-no]/tan:div-type[@id = $param-div-type]/@type"/>
      <xsl:choose>
         <xsl:when test="$this-n-type = $n-type[1]">
            <xsl:value-of
               select="
                  if (matches($param-div-n, $n-type-pattern[1], 'i'))
                  then
                     tan:rom-to-int($param-div-n)
                  else
                     $param-div-n"
            />
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[2]">
            <!-- digits don't need conversion -->
            <xsl:value-of select="$param-div-n"/>
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[3]">
            <xsl:choose>
               <xsl:when test="matches($param-div-n, $n-type-pattern[3], 'i')">
                  <xsl:variable name="this-n-split"
                     select="tokenize(replace($param-div-n, $n-type-pattern[3], '$1 $2'), ' ')"/>
                  <xsl:value-of
                     select="concat($this-n-split[1], '#', tan:aaa-to-int($this-n-split[2]))"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$param-div-n"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[4]">
            <xsl:value-of
               select="
                  if (matches($param-div-n, $n-type-pattern[4], 'i'))
                  then
                     tan:aaa-to-int($param-div-n)
                  else
                     $param-div-n"
            />
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[5]">
            <xsl:choose>
               <xsl:when test="matches($param-div-n, $n-type-pattern[5], 'i')">
                  <xsl:variable name="this-n-split"
                     select="tokenize(replace($param-div-n, $n-type-pattern[5], '$1 $2'), ' ')"/>
                  <xsl:value-of
                     select="concat(tan:aaa-to-int($this-n-split[1]), '#', $this-n-split[2])"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$param-div-n"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <!-- strings don't need conversion -->
            <xsl:value-of select="$param-div-n"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tan:equate-ref" as="item()*">
      <!-- Input: any source number, any single normalized ref, and any single segment number
      Output: reference that converts @ns to numerals when possible, @type to a div type number, and takes into account
      any exemptions made in a <realign>, segment number (altered if required by <realign>) 
      E.g., (1,'bk.1:ch.4',1) - > ('1.1:2.4',1)
      -->
      <xsl:param name="src-no" as="xs:integer?"/>
      <xsl:param name="norm-ref" as="xs:string?"/>
      <xsl:param name="seg-no" as="xs:integer?"/>
      <xsl:variable name="first-realignment"
         select="($realigns-normalized[not(@error)]/tan:div-ref[@src = $src-no][@ref = $norm-ref][not(@seg) or @seg = $seg-no])[1]"/>
      <xsl:variable name="realignment-anchor"
         select="$first-realignment/preceding-sibling::tan:anchor-div-ref"/>
      <xsl:variable name="realigned-eq-ref-and-seg" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($realignment-anchor)">
               <!-- If there's an anchor in the realignment, get its @eq-ref and @seg values -->
               <xsl:copy-of
                  select="tan:equate-ref($realignment-anchor/@src, $realignment-anchor/@ref, $realignment-anchor/@seg)"
               />
            </xsl:when>
            <xsl:when
               test="not(exists($realignment-anchor)) and $first-realignment/preceding-sibling::tan:div-ref[@src ne $first-realignment/@src]">
               <!-- If there's no anchor, but there's another source before it, get the @eq-ref and @seg values of the first div-ref -->
               <xsl:copy-of
                  select="tan:equate-ref($first-realignment/../tan:div-ref[1]/@src, $first-realignment/../tan:div-ref[1]/@ref, $first-realignment/../tan:div-ref[1]/@seg)"
               />
            </xsl:when>
            <xsl:otherwise>
               <!-- Otherwise assume that it just is exempt from any realignment, and prepend a value to norm-ref that exempts it from auto-alignment -->
               <xsl:copy-of select="(concat('s', $src-no, '_', $norm-ref), $seg-no)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="exists($first-realignment)">
            <xsl:sequence select="$realigned-eq-ref-and-seg"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence
               select="tan:replace-sequence(tan:convert-ns-to-numerals($norm-ref, $src-no), $src-1st-da-div-types-equiv-replace[$src-no]/tan:replace)"/>
            <xsl:copy-of select="$seg-no"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

</xsl:stylesheet>
