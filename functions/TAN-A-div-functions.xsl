<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd tan fn tei"
   version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Revised</xd:b>Aug 28, 2015</xd:p>
         <xd:p>Core functions for TAN-A-div files. Written principally for Schematron validation,
            but suitable for general use in other contexts</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="TAN-class-2-functions.xsl"/>
   <xsl:variable name="srcs-whose-tokens-are-defined"
      select="tan:src-ids-to-nos($head/tan:declarations/tan:token-definition/@src)"/>
   <xsl:variable name="src-1st-da-data-segmented"
      select="tan:segment-tokenized-prepped-class-1-data(tan:tokenize-prepped-class-1-doc($src-1st-da-prepped))"
      as="document-node()*"/>
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
                     <tan:div-type-ref src-no="{$this-src}" div-type-ref="{$this-id}"
                        eq-id="{($src-1st-da-all-div-types/tan:source[$this-src]/tan:div-type[@xml:id = $this-id]/@eq-id)[1]}"
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
               <xsl:variable name="this-div-type-id" select="@xml:id"/>
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
            tan:expand-realign($i)"/>


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
                  select="replace($text, $replace[1]/tan:pattern, $replace[1]/tan:replacement)"/>
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

   <xsl:function name="tan:segment-tokenized-prepped-class-1-data" as="document-node()*">
      <!-- Input: document()* resulting from tan:tokenize-prepped-class-1-data()
      Output: elements, one per source, deep copy of input, but inserting <tan:seg> between 
      <tan:div> and <tan:tok>, reflecting all <split-leaf-div-at>s-->
      <xsl:param name="these-tokd-prepped-c1-doc" as="document-node()*"/>
      <xsl:for-each select="$these-tokd-prepped-c1-doc">
         <xsl:copy>
            <xsl:apply-templates mode="segment-tokd-prepped-class-1"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="segment-tokd-prepped-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[tan:tok]" mode="segment-tokd-prepped-class-1">
      <xsl:variable name="this-div" select="."/>
      <xsl:variable name="this-src-id" select="root()/*/@src"/>
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
                  select="
                     $this-div/tan:tok[$start]/(self::*, following-sibling::*)
                     except $this-div/tan:tok[$end]/following-sibling::tan:tok[1]/(self::*, following-sibling::*)"
               />
            </seg>
         </xsl:for-each>
         <xsl:sequence select="tei:*"/>
      </xsl:copy>

   </xsl:template>

   <xsl:function name="tan:expand-div-ref" as="element()*">
      <!-- takes one <div-ref> or <anchor-div-ref> and returns one <div-ref> per source per
      ref per segment, replacing @src with numerical value, @ref with normalized single reference, and 
      @seg (if present) with a single number. If the second parameter is true() a @work attribute is
      added with the integer value of the work. A copy of the original reference is retained, in case
      the original formula is needed.
      E.g., (<div-ref src="A B" ref="1 - 2" seg="1, last"/>, true()) - > (<div-ref work="1" src="1" ref="line.1" seg="1" orig-ref="1 - 2"/>, 
      <div-ref work="1" src="1" ref="line.1" seg="7" orig-ref="1 - 2"/>, <div-ref work="1" src="1" ref="line.2" seg="1" orig-ref="1 - 2"/>,
      <div-ref work="1" src="1" ref="line.1" seg="3" orig-ref="1 - 2"/>, <div-ref work="1" src="2" ref="line.1" seg="1" orig-ref="1 - 2"/>, ...)
      The parameter $shallow-picks specifies whether ranges should be resolved shallowly or deeply. See tan:itemize-refs().
      -->
      <xsl:param name="div-ref-element" as="element()?"/>
      <xsl:param name="include-work" as="xs:boolean"/>
      <xsl:param name="shallow-picks" as="xs:boolean"/>
      <xsl:variable name="these-srcs" select="tan:src-ids-to-nos($div-ref-element/@src)"/>
      <xsl:for-each select="$these-srcs">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="this-ref-norm" select="tan:normalize-refs($div-ref-element/@ref)"/>
         <xsl:variable name="this-ref-expand"
            select="
               if ($div-ref-element/@seg) then
                  tan:itemize-leaf-refs($this-ref-norm, $this-src)
               else
                  tan:itemize-refs($this-ref-norm, $this-src, $shallow-picks)"/>
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

   <xsl:function name="tan:expand-align" as="element()*">
      <!-- See tan:expand-align-or-realign() -->
      <xsl:param name="align-element" as="element()*"/>
      <xsl:sequence select="tan:expand-align-or-realign($align-element)"/>
   </xsl:function>
   <xsl:function name="tan:expand-realign" as="element()*">
      <!-- See tan:expand-align-or-realign() -->
      <xsl:param name="realign-element" as="element()*"/>
      <xsl:sequence select="tan:expand-align-or-realign($realign-element)"/>
   </xsl:function>
   <xsl:function name="tan:expand-align-or-realign" as="item()*">
      <!-- Takes one or more <align> or <realign> and returns a normalized, expanded version, taking into 
         account rules for distribution and <anchor-div-ref>. The result follows this pattern:
      <tan:realign [+ANY ATTRIBUTES]>
        <tan:group>[ONE, IF NOT DISTRIBUTED, OTHERWISE ONE PER DISTRIBUTION] [@error FOR UNMATCHED 
        DISTRIBUTIONS] [IF FED FROM tan:expand-align() THEN IF (@exclusive) THEN] src="[SOURCE NUMBER]" 
        [ELSE] work="[WORK NUMBER]"
         <tan:(anchor-)div-ref> [COPY OF, DISTRIBUTED, IF APPROPRIATE]
      -->
      <xsl:param name="element-to-expand" as="element()*"/>
      <xsl:for-each select="$element-to-expand">
         <xsl:variable name="this-element" select="." as="element()?"/>
         <xsl:variable name="resolve-ranges-shallowly"
            select="
               if ($this-element/@distribute = true()) then
                  true()
               else
                  false()
               "/>
         <xsl:variable name="element-to-expand-is-align"
            select="
               if (name($this-element) = 'align') then
                  true()
               else
                  false()"/>
         <xsl:variable name="is-exclusive"
            select="
               if ($this-element/@exclusive) then
                  true()
               else
                  false()"/>
         <xsl:variable name="to-be-distributed" select="$resolve-ranges-shallowly"/>
         <xsl:variable name="anchor-div-refs-itemized" as="element()?">
            <xsl:if test="$this-element/tan:anchor-div-ref">
               <group>
                  <xsl:copy-of
                     select="tan:distribute-src-and-ref($this-element/tan:anchor-div-ref, $resolve-ranges-shallowly)"
                  />
               </group>
            </xsl:if>
         </xsl:variable>
         <xsl:variable name="div-refs-itemized" as="element()*">
            <xsl:for-each-group select="$this-element/tan:div-ref"
               group-by="count(preceding-sibling::*[not(@cont)])">
               <xsl:variable name="pass-1" as="element()*"
                  select="tan:distribute-src-and-ref(current-group(), $resolve-ranges-shallowly)"/>
               <xsl:for-each-group select="$pass-1" group-by="@src">
                  <group>
                     <xsl:copy-of select="current-group()"/>
                  </group>
               </xsl:for-each-group>
            </xsl:for-each-group>
         </xsl:variable>
         <xsl:variable name="div-refs-regrouped" as="element()*">
            <xsl:choose>
               <xsl:when test="$to-be-distributed = true()">
                  <xsl:copy-of
                     select="tan:distribute-elements-of-elements(($anchor-div-refs-itemized, $div-refs-itemized))"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="$anchor-div-refs-itemized, $div-refs-itemized"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="$div-refs-regrouped">
               <xsl:copy>
                  <xsl:choose>
                     <xsl:when
                        test="$element-to-expand-is-align = true() and $is-exclusive = true()">
                        <xsl:attribute name="src" select="tan:div-ref[1]/@src"/>
                     </xsl:when>
                     <xsl:when
                        test="$element-to-expand-is-align = true() and $is-exclusive = false()">
                        <xsl:attribute name="work"
                           select="$equate-works[number(current()/tan:div-ref[1]/@src)]"/>
                     </xsl:when>
                  </xsl:choose>
                  <xsl:copy-of select="@*, *"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:distribute-elements-of-elements" as="element()*">
      <!-- Input: a sequence of elements with child elements to be distributed and regrouped. 
         Output: a sequence of elements where the nth item of each top-level input element is grouped 
         together. Items that cannot be distributed will be lumped together in a final group with the 
         attribute @error='true'.
         E.g., <group><a>one</a><a>two</a></group>, <group><b>three</b></group>
         - > 
         <group><a>one</a><b>three</b></group>, <group error="true"><a>two</a></group>
      -->
      <xsl:param name="input-elements" as="element()*"/>
      <xsl:variable name="count-per-element"
         select="
            for $i in $input-elements
            return
               count($i/*)"/>
      <xsl:variable name="element-name" select="name($input-elements[1])"/>
      <xsl:for-each select="1 to min($count-per-element)">
         <xsl:element name="{$element-name}">
            <xsl:copy-of select="$input-elements/*[current()]"/>
         </xsl:element>
      </xsl:for-each>
      <xsl:if test="min($count-per-element) lt max($count-per-element)">
         <xsl:element name="{$element-name}">
            <xsl:attribute name="error" select="true()"/>
            <xsl:copy-of select="$input-elements/*[position() gt min($count-per-element)]"/>
         </xsl:element>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:convert-ns-to-numerals" as="xs:string">
      <!-- converts a flattened ref's @n values to numerals according to their use in a given source
            Input: single flatref as a string, source number as integer
            Output: revised flatref, substituting @n values for numerals where appropriate
            E.g., ('bk ch', 'xxiv 2b', 1) - > '24 2#2'
        -->
      <xsl:param name="norm-types" as="xs:string"/>
      <xsl:param name="norm-flatref" as="xs:string"/>
      <xsl:param name="src-no" as="xs:integer"/>
      <xsl:variable name="types" select="tokenize($norm-types, $separator-hierarchy-regex)"/>
      <xsl:variable name="ns" select="tokenize($norm-flatref, $separator-hierarchy-regex)"/>
      <xsl:variable name="ns-converted"
         select="
            for $i in (1 to count($ns))
            return
               tan:replace-ns($types[$i], $ns[$i], $src-no)"/>
      <xsl:value-of select="string-join($ns-converted, $separator-hierarchy)"/>
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
      E.g., (1, 'bk ch', '1 4', 1) - > ('1 2', '1 4', 1)
      -->
      <xsl:param name="src-no" as="xs:integer?"/>
      <xsl:param name="norm-types" as="xs:string?"/>
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
                  select="tan:equate-ref($realignment-anchor/@src, $realignment-anchor/@type, $realignment-anchor/@ref, $realignment-anchor/@seg)"
               />
            </xsl:when>
            <xsl:when
               test="not(exists($realignment-anchor)) and $first-realignment/preceding-sibling::tan:div-ref[@src ne $first-realignment/@src]">
               <!-- If there's no anchor, but there's another source before it, get the @eq-ref and @seg values of the first div-ref -->
               <xsl:copy-of
                  select="tan:equate-ref($first-realignment/../tan:div-ref[1]/@src, $first-realignment/../tan:div-ref[1]/@type, $first-realignment/../tan:div-ref[1]/@ref, $first-realignment/../tan:div-ref[1]/@seg)"
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
               select="tan:replace-sequence(tan:convert-ns-to-numerals($norm-types, $norm-ref, $src-no), $src-1st-da-div-types-equiv-replace[$src-no]/tan:replace)"/>
            <xsl:copy-of select="$seg-no"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

</xsl:stylesheet>
