<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>July 6, 2016</xd:p>
         <xd:p>Core variables and functions for class 1 and 2 TAN files (i.e., not applicable to
            class 3 TAN file types). Written principally for Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <!-- TEXT FUNCTIONS -->

   <xsl:variable name="special-end-div-chars" select="'&#x200D;', '&#xAD;'" as="xs:string+"/>
   <xsl:variable name="special-end-div-chars-regex"
      select="concat('[', string-join($special-end-div-chars, ''), ']$')" as="xs:string"/>

   <xsl:function name="tan:text-join" as="xs:string">
      <xsl:param name="items" as="item()*"/>
      <xsl:copy-of select="tan:text-join($items, true())"/>
   </xsl:function>
   <xsl:function name="tan:text-join" as="xs:string">
      <!-- Input: any number of elements, text nodes, or strings
         Output: a single string that joins and normalizes them according to TAN requirements. 
         The items are converted to strings. Any adjacent strings are joined
         by a space, unless if one of the special div-end characters are used (ZWJ U+200D or SOFT HYPHEN U+AD)
         at the end of the first of a pair of strings to be joined. In that 
         case, the terminal mark is deleted, no intervening space is introduced, and the strings are effectively 
         fused. After joining all divs, text is space-normalized. If  the second parameter is true, then the end of the 
         resultant string is checked for special div-end characters
      -->
      <xsl:param name="items" as="item()*"/>
      <xsl:param name="prep-end" as="xs:boolean"/>
      <xsl:variable name="string-sequence" as="xs:string*">
         <xsl:for-each select="$items">
            <xsl:variable name="this-item" select="."/>
            <xsl:choose>
               <xsl:when test="$this-item instance of xs:string">
                  <xsl:value-of select="$this-item"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of
                     select="
                        for $i in $this-item/descendant-or-self::*:div[not(*:div)]
                        return
                           string-join($i/text(), '')"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="new-sequence" as="xs:string*"
         select="
            if ($prep-end = true()) then
               tan:normalize-div-text($string-sequence)
            else
               concat(tan:normalize-div-text($string-sequence[not(last())]), $string-sequence[last()])"/>
      <xsl:value-of select="string-join($new-sequence, '')"/>
   </xsl:function>

   <xsl:function name="tan:normalize-div-text" as="xs:string*">
      <!-- Input: any sequence of strings
         Output: the same sequence, normalized. Each item in the sequence is space normalized and then 
         if its end matches one of the special div-end characters, ZWJ U+200D or SOFT HYPHEN U+AD, 
         the character is removed, otherwise a space is added at the end. Zero-length strings are skipped. -->
      <xsl:param name="div-strings" as="xs:string*"/>
      <xsl:for-each select="$div-strings">
         <xsl:variable name="this-norm" select="normalize-space(.)"/>
         <xsl:choose>
            <xsl:when test="matches($this-norm, $special-end-div-chars-regex)">
               <xsl:value-of select="replace($this-norm, $special-end-div-chars-regex, '')"/>
            </xsl:when>
            <xsl:when test="string-length(.) lt 1"/>
            <xsl:otherwise>
               <xsl:value-of select="concat($this-norm, ' ')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <!-- PREPARATION -->

   <xsl:variable name="n-type-pattern" xml:id="v-n-type-pattern"
      select="
         (concat('^(', $roman-numeral-pattern, ')$'),
         '^(\d+)$',
         concat('^(\d+)(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')$'),
         concat('^(', $letter-numeral-pattern, ')(\d+)$'),
         '(.)')"/>

   <xsl:function name="tan:prep-resolved-class-1-doc" as="document-node()*">
      <!-- Input: sequence of resolved class 1 TAN documents 
         Output: sequence of documents with these changes:
         /*   - >   @work="[DIGIT TAKEN FROM TAN-A-div //tan:group[tan:work]/@id]"
         tei:TEI - > tan:TAN-T
         tei:text/tei:body   - >   tan:body
         tei:div  - >  tan:div
         <div [copy of @*] @ref="[NORMALIZED, FLATTENED REF WITH N 
         SUBSTITUTIONS AND SUPPRESSIONS]">[COPY OF TEXT][SECOND COPY INSIDE TEI MARKUP, IF ANY]</div>
         Text remains untokenized.
      -->
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="resolved-class-1-documents" as="document-node()*"/>
      <xsl:for-each select="$resolved-class-1-documents">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:variable name="pos" select="position()"/>
         <xsl:copy>
            <xsl:apply-templates mode="prep-class-1" select="node()">
               <xsl:with-param name="key-to-this-src" tunnel="yes"
                  select="
                     $self-expanded-2/*/(tan:head/tan:declarations/tan:*[@src = $this-src],
                     tan:body)"
               />
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="prep-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:TAN-T | tei:TEI" mode="prep-class-1">
      <!-- Homogenize tei:TEI to tan:TAN-T -->
      <xsl:param name="key-to-this-src" as="element()*" tunnel="yes"/>
      <xsl:variable name="src-id" select="@src"/>
      <TAN-T>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="work"
            select="($key-to-this-src/tan:group[tan:work/@src = $src-id]/@n, 1)[1]"/>
         <test><xsl:value-of select="tan:q-ref(.)"/></test>
         <xsl:apply-templates mode="#current"/>
         <!--<xsl:apply-templates mode="#current">
            <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
         </xsl:apply-templates>-->
      </TAN-T>
   </xsl:template>
   <xsl:template match="tei:body" mode="prep-class-1">
      <!--<xsl:param name="key-to-this-src" as="element()*"/>-->
      <body>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <!--<xsl:apply-templates mode="#current">
            <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
         </xsl:apply-templates>-->
      </body>
   </xsl:template>
   <xsl:template match="tei:text" mode="prep-class-1">
      <!-- Makes sure the tei:body drops rootward one level, as is customary in TAN and HTML -->
      <!--<xsl:param name="key-to-this-src" as="element()*"/>-->
      <xsl:apply-templates mode="#current"/>
      <!--<xsl:apply-templates mode="#current">
         <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
      </xsl:apply-templates>-->
   </xsl:template>
   <xsl:template match="tan:div | tei:div" mode="prep-class-1" xml:id="t-prep-class-1-data">
      <xsl:param name="key-to-this-src" as="element()*" tunnel="yes"/>
      <xsl:variable name="div-types-to-suppress"
         select="$key-to-this-src[self::tan:suppress-div-types]/@div-type-ref"/>
      <xsl:variable name="div-ns-to-rename" select="$key-to-this-src[self::tan:rename-div-ns]"/>
      <xsl:choose>
         <xsl:when test="@type = $div-types-to-suppress">
            <xsl:apply-templates mode="#current">
               <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
            </xsl:apply-templates>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="orig-ref"
               select="string-join((ancestor-or-self::tei:div, ancestor-or-self::tan:div)/@n, ' ')"/>
            <xsl:variable name="new-ns" as="xs:string*">
               <xsl:for-each
                  select="(ancestor-or-self::tei:div, ancestor-or-self::tan:div)[not(@type = $div-types-to-suppress)]">
                  <xsl:variable name="this-type" select="@type"/>
                  <xsl:variable name="this-n" select="@n"/>
                  <xsl:variable name="these-renames"
                     select="$div-ns-to-rename[@div-type-ref = $this-type]/tan:rename"/>
                  <xsl:variable name="alias-specific" select="$these-renames[@old = $this-n]/@new"/>
                  <xsl:variable name="alias-generic"
                     select="
                        if ($these-renames[@old = '#a'] and matches($this-n, $n-type-pattern[4]))
                        then
                           string(tan:aaa-to-int($this-n))
                        else
                           if ($these-renames[@old = '#i'] and matches($this-n, $n-type-pattern[1]))
                           then
                              string(tan:rom-to-int($this-n))
                           else
                              ()"/>
                  <xsl:copy-of select="(($alias-specific, $alias-generic, $this-n))[1]"/>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="new-ref" select="string-join($new-ns, ' ')"/>
            <!-- Homogenize tei:div to tan:div -->
            <div>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="ref" select="$new-ref"/>
               <xsl:if test="not($orig-ref = $new-ref)">
                  <xsl:attribute name="orig-ref" select="$orig-ref"/>
               </xsl:if>
               <xsl:if test="tan:help-requested(.) = true()">
                  <xsl:copy-of select="tan:help($orig-ref,())"/>
               </xsl:if>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
               </xsl:apply-templates>
            </div>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- INFUSION -->
   <xsl:function name="tan:div-to-div-transfer" as="element()*">
      <!-- Input: (1) any set of divs with content to be transferred into the structure of (2) another 
      set of divs.
      Output: The div structure of (2), infused with the content of (1). The content is allocated 
      proportionately, with preference given to punctuation, within a certain range, and then
      word breaks.
      This function is useful for transforming class-1 documents from one reference system to another.
      It starts by getting the text content of (1), then string values for (2).
      -->
      <xsl:param name="divs-with-content-to-be-transferred" as="element()*"/>
      <xsl:param name="divs-to-be-infused-with-new-content" as="element()*"/>
      <xsl:variable name="content" select="tan:text-join($divs-with-content-to-be-transferred)"/>
      <xsl:variable name="attribute-names"
         select="
            for $i in $divs-to-be-infused-with-new-content//@*
            return
               name($i)"/>
      <xsl:variable name="mold-prep-1" as="element()">
         <mold>
            <xsl:apply-templates select="$divs-to-be-infused-with-new-content"
               mode="c1-add-string-length">
               <xsl:with-param name="mark-only-leaf-divs" select="false()" tunnel="yes"/>
            </xsl:apply-templates>
         </mold>
      </xsl:variable>
      <xsl:variable name="mold" as="element()">
         <xsl:apply-templates select="$mold-prep-1" mode="c1-add-string-pos"/>
      </xsl:variable>
      <xsl:variable name="mold-infused" as="element()">
         <xsl:apply-templates select="$mold" mode="infuse-content">
            <xsl:with-param name="raw-content-tokenized" select="tokenize($content, ' ')"
               tunnel="yes"/>
            <xsl:with-param name="total-length"
               select="sum(($mold//*:div)[last()]/(@string-length, @string-pos))" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <!--<test>
         <content><xsl:copy-of select="$content"/></content>
         <tokens count="{count(tokenize($content, ' '))}"><xsl:copy-of select="tokenize($content, ' ')"/></tokens>
         <total-length><xsl:copy-of select="sum(($mold//*:div)[last()]/(@string-length, @string-pos))"/></total-length>
      </test>-->
      <xsl:apply-templates select="$mold-infused/*" mode="strip-all-attributes-except">
         <xsl:with-param name="attributes-to-keep" select="$attribute-names" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>

   <xsl:template match="node()" mode="infuse-content c1-add-string-pos c1-add-string-length">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*:div" mode="infuse-content">
      <xsl:param name="raw-content-tokenized" as="xs:string*" tunnel="yes"/>
      <xsl:param name="total-length" as="xs:double" tunnel="yes"/>
      <xsl:variable name="is-leaf-div"
         select="
            if (*:div) then
               false()
            else
               true()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="$is-leaf-div = false()">
               <xsl:apply-templates mode="infuse-content"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-first" as="xs:double?"
                  select="ceiling(@string-pos div $total-length * count($raw-content-tokenized))"/>
               <xsl:variable name="next-first" as="xs:double?"
                  select="ceiling((@string-pos + @string-length) div $total-length * count($raw-content-tokenized))"/>
               <xsl:variable name="text-sequence"
                  select="subsequence($raw-content-tokenized, $this-first, ($next-first - $this-first))"/>
               <xsl:copy-of select="string-join($text-sequence, ' ')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>

   <!-- STRING LENGTHS, POS -->

   <xsl:function name="tan:analyze-string-length" as="document-node()*">
      <!-- One-parameter function of the two-parameter version below -->
      <xsl:param name="resolved-class-1-doc" as="document-node()*"/>
      <xsl:copy-of select="tan:analyze-string-length($resolved-class-1-doc, false())"/>
   </xsl:function>

   <xsl:function name="tan:analyze-string-length" as="document-node()*">
      <!-- Function to calculate string lengths of each leaf div and their relative position,
         so that a raw text can be segmented proportionally and given the structure of a model
         exemplar.
         Input: any class-1 document; an indication whether string lengths should be added 
         only to leaf divs, or to every div.
         Output: the same document, with @string-length and @string-pos added to every div
         NB: any $special-end-div-chars that terminate a <div> not only will not be counted, but the
         assumed space that follows will also not be counted. On the other hand, the lack of a special
         character at the end means that the nominal space that follows a div will be included in both
         the length and the position. Thus input...
         <div type="m" n="1">abc&#xad;</div>
         <div type="m" n="2">def&#x200d;</div>
         <div type="m" n="3">ghi</div>
         <div type="m" n="4">xyz</div>
         ...presumes a raw joined text of "abcdefghi xyz ", and so becomes output:
         <div type="m" n="1" string-length="3" string-pos="1">abc&#xad;</div>
         <div type="m" n="2" string-length="3" string-pos="4">def&#x200d;</div>
         <div type="m" n="3" string-length="4" string-pos="7">ghi</div>
         <div type="m" n="4" string-length="4" string-pos="11">xyz</div>
      -->
      <xsl:param name="resolved-class-1-doc" as="document-node()*"/>
      <xsl:param name="mark-only-leaf-divs" as="xs:boolean"/>
      <xsl:variable name="pass-1" as="document-node()*">
         <xsl:for-each select="$resolved-class-1-doc">
            <xsl:document>
               <xsl:apply-templates mode="c1-add-string-length">
                  <xsl:with-param name="mark-only-leaf-divs" select="$mark-only-leaf-divs"
                     tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$pass-1">
         <xsl:document>
            <xsl:apply-templates mode="c1-add-string-pos"/>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="*:div | *:body" mode="c1-add-string-length">
      <xsl:param name="mark-only-leaf-divs" as="xs:boolean" tunnel="yes"/>
      <xsl:variable name="is-leaf-div"
         select="
            if (*:div) then
               false()
            else
               true()"/>
      <xsl:choose>
         <xsl:when test="$mark-only-leaf-divs = true() and $is-leaf-div = false()">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <!-- The string length will include the hypothetical space that follows the div (or if an special end-div marker is present, the space 
                  and the marker will be ignored -->
               <xsl:attribute name="string-length" select="string-length(tan:text-join(.))"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!-- The following extensions of c1-add-string-length to process tan:diff() results -->
   <xsl:template match="tan:s1 | tan:s2 | tan:common" mode="c1-add-string-length">
      <xsl:variable name="this-length" select="string-length(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="self::tan:common or self::tan:s1">
            <xsl:attribute name="s1-length" select="$this-length"/>
         </xsl:if>
         <xsl:if test="self::tan:common or self::tan:s2">
            <xsl:attribute name="s2-length" select="$this-length"/>
         </xsl:if>
         <xsl:copy-of select="text()"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*:div[@string-length]" mode="c1-add-string-pos">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!--<xsl:attribute name="string-pos"
            select="string-length(tan:text-join(preceding::*:div[not(*:div)])) + 1"/>-->
         <xsl:attribute name="string-pos"
            select="sum(preceding::*:div[not(*:div)]/@string-length) + 1"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:s1 | tan:s2 | tan:common" mode="c1-add-string-pos">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists(@s1-length)">
            <xsl:attribute name="s1-pos" select="sum(preceding-sibling::*/@s1-length) + 1"/>
         </xsl:if>
         <xsl:if test="exists(@s2-length)">
            <xsl:attribute name="s2-pos" select="sum(preceding-sibling::*/@s2-length) + 1"/>
         </xsl:if>
         <xsl:copy-of select="text()"/>
      </xsl:copy>
   </xsl:template>

   <!-- STATS -->

   <xsl:function name="tan:analyze-stats" as="element()?">
      <!-- Takes a series of integers, doubles, or other numbers and returns basic statistics
      as attributes in a single element -->
      <xsl:param name="arg" as="xs:anyAtomicType*"/>
      <xsl:variable name="this-avg" select="avg($arg)"/>
      <xsl:variable name="these-deviations"
         select="
            for $i in $arg
            return
               math:pow(($i - $this-avg), 2)"/>
      <xsl:variable name="this-variance" select="avg($these-deviations)"/>
      <xsl:variable name="this-standard-deviation" select="math:sqrt($this-variance)"/>
      <stats xmlns="tag:textalign.net,2015:ns">
         <xsl:attribute name="count" select="count($arg)"/>
         <xsl:attribute name="sum" select="sum($arg)"/>
         <xsl:attribute name="avg" select="$this-avg"/>
         <xsl:attribute name="max" select="max($arg)"/>
         <xsl:attribute name="min" select="min($arg)"/>
         <xsl:attribute name="var" select="$this-variance"/>
         <xsl:attribute name="std" select="$this-standard-deviation"/>
         <xsl:for-each select="$arg">
            <xsl:variable name="pos" select="position()"/>
            <xsl:element name="d" namespace="tag:textalign.net,2015:ns">
               <xsl:attribute name="dev" select="$these-deviations[$pos]"/>
               <xsl:value-of select="."/>
            </xsl:element>
         </xsl:for-each>
      </stats>
   </xsl:function>

   <!-- SKELETONS -->
   <xsl:function name="tan:get-src-skeleton" as="document-node()?">
      <!-- one-parameter form of the master version below -->
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:copy-of select="tan:get-src-skeleton($src-1st-da-prepped, ())"/>
   </xsl:function>
   <xsl:function name="tan:get-src-skeleton" as="document-node()?">
      <!-- input: one or more prepped class 1 document (usually has @ref with flatref values) and a sequence of strings 
         specifying what attributes should be retained after the merge.
      output: a single document that merges the structures of the input documents - - a skeleton, that is, no text in the 
      body, just a div structure that reflects both what is common among all input documents and what is unique. 
      This function is especially useful for validation scenarios, where you wish to see exactly how two very comparable documents 
      differ. -->
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:param name="keep-what-attributes" as="xs:string*"/>
      <xsl:variable name="srcs-as-skeletons" as="document-node()*">
         <xsl:for-each select="$src-1st-da-prepped">
            <xsl:variable name="root-src" select="root(.)/*/@src"/>
            <xsl:variable name="src"
               select="
                  if (exists($root-src)) then
                     $root-src
                  else
                     position()"/>
            <xsl:document>
               <xsl:apply-templates select="." mode="make-skeleton">
                  <xsl:with-param name="src" select="$src" tunnel="yes"/>
                  <xsl:with-param name="keep-what-attributes" select="$keep-what-attributes"
                     tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <!--<xsl:copy-of select="$srcs-as-skeletons[1]"/>-->
      <xsl:copy-of select="tan:merge-src-skeletons($srcs-as-skeletons, $keep-what-attributes)"/>
   </xsl:function>

   <xsl:template match="processing-instruction()" mode="make-skeleton"/>
   <xsl:template match="*" mode="make-skeleton">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:TAN-T | tei:TEI" mode="make-skeleton">
      <xsl:param name="src" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="src" select="$src"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div" mode="make-skeleton">
      <xsl:param name="src" tunnel="yes"/>
      <xsl:param name="keep-what-attributes" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@ref"/>
         <xsl:copy-of select="@*[name(.) = $keep-what-attributes]"/>
         <xsl:attribute name="src" select="$src"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:head" mode="make-skeleton">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="text()" mode="make-skeleton"/>

   <xsl:function name="tan:merge-src-skeletons" as="document-node()?">
      <!-- one-param version of the version below -->
      <xsl:param name="skeletons-to-be-merged" as="document-node()*"/>
      <xsl:copy-of select="tan:merge-src-skeletons($skeletons-to-be-merged, 'ref', true())"/>
   </xsl:function>
   <xsl:function name="tan:merge-src-skeletons" as="document-node()?">
      <!-- two-param version of the version below -->
      <xsl:param name="skeletons-to-be-merged" as="document-node()*"/>
      <xsl:param name="keep-what-attribute" as="xs:string*"/>
      <xsl:copy-of
         select="tan:merge-src-skeletons($skeletons-to-be-merged, $keep-what-attribute, true())"/>
   </xsl:function>
   <xsl:function name="tan:merge-src-skeletons" as="document-node()?">
      <!-- Input: one or more skeletons
         Output: a single skeleton that merges all other skeletons, based upon shared values of @ref in the divs
      -->
      <xsl:param name="skeletons-to-be-merged" as="document-node()*"/>
      <xsl:param name="keep-what-attribute" as="xs:string*"/>
      <xsl:param name="add-stats" as="xs:boolean"/>
      <xsl:variable name="skeleton-srcs"
         select="
            distinct-values(for $i in $skeletons-to-be-merged/*/@src
            return
               tokenize($i, '\s+'))"
         as="xs:string*"/>
      <xsl:variable name="root-name" select="name($skeletons-to-be-merged[1]/*)"/>
      <xsl:variable name="body-stats-merged"
         select="tan:merge-analyzed-stats($skeletons-to-be-merged/*/tan:body, $add-stats)"/>
      <xsl:variable name="skeleton-prep" as="document-node()?">
         <xsl:document>
            <xsl:element name="{$root-name}" namespace="tag:textalign.net,2015:ns">
               <xsl:attribute name="src" select="string-join($skeleton-srcs, ' ')"/>
               <xsl:attribute name="id" namespace="http://www.w3.org/XML/1998/namespace"
                  select="
                     concat(string-join($skeletons-to-be-merged/*/@xml:id, '--'), (if ($add-stats = true()) then
                        ('---add')
                     else
                        ('---diff')))"/>
               <xsl:copy-of select="$skeletons-to-be-merged/*/tan:head"/>
               <!--<test><xsl:copy-of select="$body-stats-merged"/></test>-->
               <xsl:element name="body" namespace="tag:textalign.net,2015:ns">
                  <xsl:copy-of select="$body-stats-merged/(@*, node())"/>
                  <xsl:copy-of select="$skeletons-to-be-merged/*/tan:body/tan:div"/>
               </xsl:element>
            </xsl:element>
         </xsl:document>
      </xsl:variable>
      <!--<xsl:copy-of select="$skeleton-prep"/>-->
      <xsl:copy-of
         select="tan:clean-up-src-skeleton($skeleton-prep, $keep-what-attribute, 1, $add-stats)"/>
   </xsl:function>

   <xsl:function name="tan:merge-analyzed-stats" as="element()">
      <!-- Takes a group of elements that follow the pattern that results from tan:analyze-stats and
      synthesizes them into a single element. If $add-stats is true, then they are added; if false, the
      sum of the 2nd - last elements is subtracted from the first. Will work on elements of any name,
      so long as they have tan:d children, with the data points to be merged. -->
      <xsl:param name="analyzed-stats" as="element()*"/>
      <xsl:param name="add-stats" as="xs:boolean"/>
      <xsl:variable name="datum-counts" as="xs:integer*"
         select="
            for $i in $analyzed-stats
            return
               count($i/tan:d)"/>
      <xsl:variable name="data-summed" as="xs:anyAtomicType*"
         select="
            for $i in (1 to $datum-counts[1])
            return
               sum($analyzed-stats/tan:d[$i])"/>
      <xsl:variable name="data-diff" as="element()">
         <stats>
            <xsl:attribute name="count"
               select="(avg($analyzed-stats[position() gt 1]/@count)) - $analyzed-stats[1]/@count"/>
            <xsl:attribute name="sum"
               select="(avg($analyzed-stats[position() gt 1]/@sum)) - $analyzed-stats[1]/@sum"/>
            <xsl:attribute name="avg"
               select="(avg($analyzed-stats[position() gt 1]/@avg)) - $analyzed-stats[1]/@avg"/>
            <xsl:attribute name="max"
               select="(avg($analyzed-stats[position() gt 1]/@max)) - $analyzed-stats[1]/@max"/>
            <xsl:attribute name="min"
               select="(avg($analyzed-stats[position() gt 1]/@min)) - $analyzed-stats[1]/@min"/>
            <xsl:attribute name="var"
               select="(avg($analyzed-stats[position() gt 1]/@var)) - $analyzed-stats[1]/@var"/>
            <xsl:attribute name="std"
               select="(avg($analyzed-stats[position() gt 1]/@std)) - $analyzed-stats[1]/@std"/>
            <xsl:for-each select="$analyzed-stats[1]/tan:d">
               <xsl:variable name="pos" select="position()"/>
               <d>
                  <xsl:copy-of
                     select="avg($analyzed-stats[position() gt 1]/tan:d[$pos]) - $analyzed-stats[1]/tan:d[$pos]"
                  />
               </d>
            </xsl:for-each>
         </stats>
      </xsl:variable>
      <stats>
         <xsl:choose>
            <xsl:when test="$analyzed-stats/tan:d and count(distinct-values($datum-counts)) gt 1">
               <xsl:copy-of select="tan:error('adv03', $datum-counts)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:choose>
                  <xsl:when test="$add-stats = true() and $analyzed-stats/tan:d">
                     <xsl:copy-of select="tan:analyze-stats($data-summed)/(@*, node())"/>
                  </xsl:when>
                  <xsl:when test="$add-stats = false() and $analyzed-stats/tan:d">
                     <xsl:copy-of select="$data-diff/(@*, node())"/>
                     <!--<xsl:copy-of select="tan:analyze-stats($data-diff)/(@*, node())"/>-->
                  </xsl:when>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
      </stats>
   </xsl:function>

   <xsl:function name="tan:clean-up-src-skeleton" as="document-node()?">
      <!-- This takes a rough skeleton, created by a raw concatenation of the bodies of
         a skeleton, and joins sibling <div>s that share a common @ref. 
         Further, if any statistics are present and $add-stats is true, then the matching 
         attributes in merged <div>s are added or averaged, as required. If $add-stats is false
         then the statistics are subtracted (the sum of the tail is subtracted from the head)
      -->
      <xsl:param name="skeleton-to-be-merged" as="document-node()?"/>
      <xsl:param name="keep-what-attributes" as="xs:string*"/>
      <xsl:param name="depth" as="xs:integer"/>
      <xsl:param name="add-stats" as="xs:boolean"/>
      <xsl:variable name="max-depth" as="xs:integer"
         select="
            max(((for $i in $skeleton-to-be-merged/*/tan:body//tan:div[not(tan:div)]
            return
               count($i/ancestor-or-self::tan:div)), 0))"/>
      <xsl:choose>
         <xsl:when test="$depth gt $max-depth">
            <xsl:copy-of select="$skeleton-to-be-merged"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="new-skeleton">
               <xsl:document>
                  <xsl:apply-templates select="$skeleton-to-be-merged"
                     mode="synthesize-src-skeleton">
                     <xsl:with-param name="depth" select="$depth" tunnel="yes"/>
                     <xsl:with-param name="add-stats" select="$add-stats" tunnel="yes"/>
                     <xsl:with-param name="keep-what-attributes" select="$keep-what-attributes"
                        tunnel="yes"/>
                  </xsl:apply-templates>
               </xsl:document>
            </xsl:variable>
            <xsl:copy-of
               select="tan:clean-up-src-skeleton($new-skeleton, $keep-what-attributes, $depth + 1, $add-stats)"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:template match="node()" mode="synthesize-src-skeleton">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div | tan:body" mode="synthesize-src-skeleton">
      <xsl:param name="depth" as="xs:integer" tunnel="yes"/>
      <xsl:param name="add-stats" as="xs:boolean" tunnel="yes"/>
      <xsl:param name="keep-what-attributes" tunnel="yes"/>
      <xsl:variable name="this-depth" select="count(ancestor::*)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="self::tan:body">
            <xsl:attribute name="add-stats" select="$add-stats"/>
         </xsl:if>
         <xsl:choose>
            <xsl:when test="$this-depth lt $depth">
               <xsl:apply-templates mode="synthesize-src-skeleton"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="tan:d"/>
               <xsl:for-each-group select="tan:div" group-by="@ref">
                  <xsl:variable name="these-merged"
                     select="tan:merge-analyzed-stats(current-group(), $add-stats)"/>
                  <div ref="{current-grouping-key()}">
                     <xsl:for-each select="$keep-what-attributes">
                        <xsl:variable name="this-att" select="."/>
                        <xsl:variable name="these-vals"
                           select="distinct-values(current-group()/@*[name(.) = $this-att])"/>
                        <xsl:choose>
                           <xsl:when test="count($these-vals) = 1">
                              <xsl:attribute name="{$this-att}" select="$these-vals"/>
                           </xsl:when>
                           <xsl:when test="count($these-vals) gt 1">
                              <xsl:for-each select="current-group()">
                                 <xsl:variable name="this-src" select="@src"/>
                                 <xsl:attribute name="{concat($this-att,'-',$this-src)}"
                                    select="@*[name(.) = $this-att]"/>
                              </xsl:for-each>
                           </xsl:when>
                        </xsl:choose>
                     </xsl:for-each>
                     <!--<xsl:attribute name="{$keep-what-attributes}" select="current-grouping-key()"></xsl:attribute>-->
                     <xsl:if
                        test="count(current-group()) lt count(tokenize((ancestor::*/@src)[last()], '\s+'))">
                        <xsl:attribute name="src">
                           <xsl:value-of select="current-group()/@src"/>
                        </xsl:attribute>
                     </xsl:if>
                     <xsl:copy-of select="$these-merged/(@*, node())"/>
                     <xsl:copy-of select="current-group()/tan:div"/>
                  </div>
               </xsl:for-each-group>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
