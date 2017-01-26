<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>Jan 24, 2017</xd:p>
         <xd:p>Core variables and functions for class 2 TAN files (i.e., applicable to multiple
            class 2 TAN file types). Written principally for Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="TAN-core-functions.xsl"/>
   <xsl:include href="TAN-class-1-and-2-functions.xsl"/>
   <xsl:include href="TAN-class-2-and-3-functions.xsl"/>
   <xsl:include href="../errors/TAN-class-2-errors.xsl"/>

   <xsl:key name="div-via-ref" match="tan:div" use="@ref"/>

   <!-- PART I.
      GLOBAL VARIABLES AND PARAMETERS -->
   <!-- Source picking and identification -->
   <xsl:variable name="source-lacks-id"
      select="
         if ($head/tan:source/@xml:id) then
            false()
         else
            true()"/>

   <!-- Searches -->
   <xsl:param name="searches-ignore-accents" select="true()" as="xs:boolean"/>
   <xsl:param name="searches-are-case-sensitive" select="false()" as="xs:boolean"/>
   <xsl:param name="match-flags"
      select="
         if ($searches-are-case-sensitive = true()) then
            ()
         else
            'i'"
      as="xs:string?"/>
   <xsl:param name="searches-suppress-what-text" as="xs:string?" select="'[\p{M}]'"/>

   <!-- PART II.
      PROCESSING DOCUMENTS -->

   <xsl:variable name="src-elements" select="$head/tan:source"/>
   <xsl:variable name="src-ids"
      select="
         if ($src-elements/@xml:id) then
            $src-elements/@xml:id
         else
            '1'"
      as="xs:string+"/>

   <xsl:function name="tan:prep-resolved-class-2-doc" as="document-node()*">
      <!-- Input: a class 2 document -->
      <!-- Output: that same document, prepped, followed by its source documents, which have been prepped enough to justify or explain the content of the original class 2 document -->
      <!-- Preparation of a class 2 document is complicated, requiring navigation back and forth between the class-2 document and its sources, resolving them along the way. The first document returned is always the resolved class-2 document. Any documents that follow are resolved sources. Here's the process that is followed:
      
      FOCUS           ALTERATIONS
      =======   =============================================================================================
      sources   Resolve each source document (including add @src to root element)
      self      Expand @src (<equate-works> gets special treatment), @div-type-ref; normalize @ref; add @xml:id to TAN-LM <source>; add @group to elements that take @cont; add @work to continuations that should take it
      self      Expand <token-definition> and (TAN-A-div) <equate-works>, <equate-div-types>
      sources   Add @work to each root element (TAN-A-div), rename @ns, suppress select div types, replace div types with numerical equivalent. Sources' flat ref should now be commensurate with class 2 file's use of @ref.
      self      Expand @work, @ref (iterate elements over calculated values); provide help on <equate-works> and <equate-div-types>
      sources   Tokenize and (if the self is a TAN-A-div) segment those <div>s that are referred to
      self      Expand @val, @pos for <tok>, look for errors in previous step
      self      Check for errors in previous steps
      
      [Further preparation is then conducted by the functions specific to the particular class 2 format]
      -->
      <xsl:param name="resolved-class-2-doc" as="document-node()?"/>
      <xsl:variable name="is-tan-lm-lang"
         select="exists($resolved-class-2-doc/tan:TAN-LM) and not(exists($resolved-class-2-doc/tan:TAN-LM/tan:head/tan:source))"
      />
      <xsl:variable name="these-sources-resolved" as="document-node()*">
         <xsl:choose>
            <xsl:when test="$resolved-class-2-doc/*/@id = $doc-id and $sources-1st-da/*[@src]">
               <!-- If the input is the main document itself, and @src has been imprinted on the resolved sources, then just use $sources-1st-da -->
               <xsl:sequence select="$sources-1st-da"/>
            </xsl:when>
            <xsl:otherwise>
               <!-- Otherwise, get a resolved copy of every source -->
               <xsl:copy-of
                  select="tan:resolve-doc(tan:get-1st-doc($resolved-class-2-doc/*/tan:head/tan:source), false(), 'src', $resolved-class-2-doc/*/tan:head/tan:source/@xml:id, (), ())"
               />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="class-2-doc-pass-1" as="document-node()">
         <xsl:document>
            <xsl:apply-templates select="$resolved-class-2-doc" mode="prep-class-2-doc-pass-1"/>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="class-2-doc-pass-2" as="document-node()?"
         select="tan:prep-class-2-doc-pass-2($class-2-doc-pass-1, $these-sources-resolved)"/>
      <xsl:variable name="class-1-sources-prepped-pass-1"
         select="tan:prep-resolved-class-1-doc($class-2-doc-pass-1, $these-sources-resolved)"
         as="document-node()*"/>
      <xsl:variable name="class-2-doc-pass-3"
         select="tan:prep-class-2-doc-pass-3($class-2-doc-pass-2, $class-1-sources-prepped-pass-1)"
         as="document-node()?"/>
      <xsl:variable name="class-1-sources-prepped-pass-2"
         select="
               tan:get-src-1st-da-tokenized($class-2-doc-pass-3, $class-1-sources-prepped-pass-1, true(), true())"
         as="document-node()*"/>
      <xsl:variable name="class-2-doc-pass-4" as="document-node()?"
         select="
            if ($is-tan-lm-lang = true()) then
               $class-2-doc-pass-3
            else
               tan:prep-class-2-doc-pass-4($class-2-doc-pass-3, $class-1-sources-prepped-pass-2)"
      />
      <xsl:variable name="class-2-doc-errors-marked" as="document-node()">
         <xsl:document>
            <xsl:apply-templates select="$class-2-doc-pass-4" mode="class-2-errors"/>
         </xsl:document>
      </xsl:variable>
      <!-- diagnostics, results -->
      <!--<xsl:copy-of select="$resolved-class-2-doc"/>-->
      <!--<xsl:copy-of select="$class-2-doc-pass-1"/>-->
      <!--<xsl:copy-of select="$class-2-doc-pass-2"/>-->
      <!--<xsl:copy-of select="$class-2-doc-pass-3"/>-->
      <!--<xsl:copy-of select="$class-2-doc-pass-4"/>-->
      <xsl:copy-of select="$class-2-doc-errors-marked"/>
      <!--<xsl:copy-of select="$class-1-sources-prepped-pass-1"/>-->
      <xsl:copy-of select="$class-1-sources-prepped-pass-2"/>
   </xsl:function>

   <xsl:template match="comment()|processing-instruction()" mode="prep-class-2-doc-pass-1 prep-class-2-doc-pass-2 prep-tan-a-div-pass-3-prelim insert-seg-into-leaf-divs-in-hierarchy-fragment prep-class-2-doc-pass-3 prep-class-2-doc-pass-3-old prep-class-2-doc-pass-4 get-div-hierarchy-fragment"></xsl:template>
   <xsl:template match="*" mode="prep-class-2-doc-pass-1 prep-class-2-doc-pass-2 prep-tan-a-div-pass-3-prelim insert-seg-into-leaf-divs-in-hierarchy-fragment prep-class-2-doc-pass-3 prep-class-2-doc-pass-3-old prep-class-2-doc-pass-4 get-div-hierarchy-fragment">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:source[not(@xml:id)]" mode="prep-class-2-doc-pass-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="xml:id" select="count(preceding-sibling::tan:source) + 1"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:equate-works" mode="prep-class-2-doc-pass-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="*"/>
         <xsl:for-each select="tokenize(@work, ' ')">
            <work src="{.}"/>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>
   <xsl:template
      match="tan:anchor-div-ref | tan:div-ref | tan:div-type-ref | tan:rename-div-ns | tan:suppress-div-types | tan:tok | tan:token-definition"
      mode="prep-class-2-doc-pass-1">
      <!-- This template iterates an element across its values of @src; this excludes elements that use @work, i.e., <div-ref>, which are resolved only after works are equated and resolved -->
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-element-name" select="name($this-element)"/>
      <xsl:variable name="head-of-group"
         select="(preceding-sibling::*[name() = $this-element-name and (@src or @work)])[last()]"/>
      <xsl:variable name="is-continuation" select="not(exists((@src, @work)))"/>
      <xsl:variable name="all-possible-sources" select="/*/tan:head/tan:source/@xml:id"/>
      <xsl:variable name="this-src-attr" as="xs:string?"
         select="
            if ($is-continuation = true()) then
               $head-of-group/@src
            else
               @src"/>
      <xsl:variable name="srcs-pass-1" select="tokenize(tan:normalize-text($this-src-attr), ' ')"/>
      <xsl:variable name="these-sources"
         select="
            if (/tan:TAN-LM) then
               '1'
            else
               if ($srcs-pass-1 = '*') then
                  $all-possible-sources
               else
                  $srcs-pass-1"/>
      <xsl:variable name="these-div-types"
         select="tokenize(tan:normalize-text(@div-type-ref), '\s+')"/>
      <xsl:for-each
         select="
            if (exists($these-sources)) then
               $these-sources
            else
               ''">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="pos" select="position()"/>
         <xsl:for-each
            select="
               if (exists($these-div-types)) then
                  $these-div-types
               else
                  1">
            <xsl:element name="{$this-element-name}">
               <xsl:copy-of select="$this-element/@*"/>
               <!-- Oct 2016: normalization of @ref (e.g., Roman to Arabic numerals) and introduction of @orig-ref occurs now earlier, at resolve-doc() level -->
               <xsl:if test="string-length($this-src) gt 0">
                  <xsl:attribute name="src" select="$this-src"/>
               </xsl:if>
               <xsl:if test="exists($these-div-types)">
                  <xsl:attribute name="div-type-ref" select="."/>
               </xsl:if>
               <xsl:if test="$this-element-name = ('anchor-div-ref', 'div-ref', 'tok')">
                  <!-- we include a suffix, because when any of these elements has multiple sources, each one constitutes its own group, so the group needs a unique identifier -->
                  <xsl:variable name="group-suffix"
                     select="
                        if (count($these-sources) gt 1) then
                           concat('-', string($pos))
                        else
                           ()"
                     as="xs:string?"/>
                  <xsl:attribute name="group"
                     select="concat(string(count($this-element/preceding-sibling::*[not(@cont)]) + 1), $group-suffix)"/>
               </xsl:if>
               <xsl:if test="$is-continuation = true()">
                  <xsl:copy-of select="$head-of-group/(@strength, @cert, @work)"/>
               </xsl:if>
               <xsl:if test="tan:help-requested($this-element/@src)">
                  <xsl:copy-of
                     select="tan:help(concat('Valid values: ', string-join($all-possible-sources, ' ')), $all-possible-sources)"
                  />
               </xsl:if>
               <xsl:copy-of select="$this-element/node()"/>
            </xsl:element>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:template>
   <xsl:template match="tan:m" mode="prep-class-2-doc-pass-1">
      <xsl:variable name="orig-code" select="."/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="orig-code" select="normalize-space($orig-code)"/>
         <xsl:for-each select="tokenize(tan:normalize-text($orig-code), ' ')">
            <f n="{position()}">
               <xsl:value-of
                  select="
                     if (. = '-') then
                        ()
                     else
                        lower-case(.)"
               />
            </f>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>

   <!-- Resultant functions -->
   <xsl:function name="tan:expand-src-and-div-type-ref" as="element()*">
      <xsl:param name="elements-with-src-and-div-type" as="element()*"/>
      <xsl:apply-templates mode="prep-class-2-doc-pass-1" select="$elements-with-src-and-div-type"/>
   </xsl:function>
   <xsl:function name="tan:normalize-refs" as="xs:string*">
      <!-- Input: elements that take @ref; a numeral types declaration (elements produced by tan:analyze-attr-n-or-ref-numerals()) -->
      <!-- Output: a sequence of punctuation- and space-normalized reference strings, converting the items that match numerals into Arabic numerals and setting the strings lowercase -->
      <xsl:param name="elements-with-attr-ref" as="element()*"/>
      <xsl:param name="ambiguous-numeral-types" as="element()*"/>
      <!--<xsl:param name="roman-numerals-before-alphabetic" as="xs:boolean?"/>-->
      <xsl:variable name="this-amb-num-type"
         select="
            if (exists($ambiguous-numeral-types)) then
               $ambiguous-numeral-types
            else
               tan:analyze-elements-with-numeral-attributes($elements-with-attr-ref, (), true(), true())"
      />
      <xsl:for-each select="$elements-with-attr-ref">
         <xsl:variable name="raw-analysis"
            select="tan:analyze-elements-with-numeral-attributes(., (), false(), true())"/>
         <xsl:variable name="new-ref" as="xs:string*">
            <xsl:for-each select="$raw-analysis/tan:n"><xsl:choose>
               <xsl:when test="tan:val/@type = $n-type[1] and tan:val/@type = $n-type[4]">
                  <xsl:choose>
                     <xsl:when test="$this-amb-num-type/@type-i-or-a-is-probably = 'a'">
                        <!-- it's probably not a Roman numeral -->
                        <xsl:value-of select="(tan:val[not(@type = $n-type[1])])[1]"/>
                     </xsl:when>
                     <xsl:when test="$this-amb-num-type/@type-i-or-a-is-probably = 'i'">
                        <!-- it's probably not an alphabetic numeral -->
                        <xsl:value-of select="(tan:val[not(@type = $n-type[4])])[1]"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:value-of select="tan:val[1]"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:when>
               <xsl:otherwise>
                  <!-- no ambiguity; just use the first value -->
                  <xsl:value-of select="tan:val[1]"/>
               </xsl:otherwise>
            </xsl:choose></xsl:for-each>
         </xsl:variable>
         <xsl:value-of select="string-join($new-ref, $separator-hierarchy)"/>
      </xsl:for-each>
      <!--<xsl:variable name="ranges">
         <xsl:analyze-string select="lower-case($elements-with-attr-ref)" regex="\s*[,-]\s+">
            <xsl:matching-substring>
               <xsl:value-of select="concat(' ', normalize-space(.), ' ')"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:analyze-string select="." regex="\?\?\?">
                  <xsl:matching-substring>
                     <xsl:value-of select="."/>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <xsl:variable name="ref-elements"
                        select="tan:arabic-numerals(tokenize(., '\W+'), $roman-numerals-before-alphabetic)"/>
                     <xsl:value-of select="string-join($ref-elements, $separator-hierarchy)"/>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>-->
      <!--<xsl:value-of select="string-join($ranges, '')"/>-->
   </xsl:function>
   <xsl:template match="tan:rename" mode="arabic-numerals">
      <xsl:param name="ambiguous-numeral-types" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-old-norm" select="tan:normalize-text(lower-case(@old))"/>
      <xsl:variable name="raw-old"
         select="tan:analyze-elements-with-numeral-attributes(., (), false(), true())"/>
      <xsl:variable name="new-old" as="xs:string?">
         <xsl:choose>
            <xsl:when
               test="$raw-old/tan:n[tan:val/@type = $n-type[1] and tan:val/@type = $n-type[4]]">
               <xsl:choose>
                  <xsl:when test="$ambiguous-numeral-types/@type-i-or-a-is-probably = 'a'">
                     <!-- it's probably not a Roman numeral -->
                     <xsl:value-of select="($raw-old/tan:n/tan:val[not(@type = $n-type[1])])[1]"/>
                  </xsl:when>
                  <xsl:when test="$ambiguous-numeral-types/@type-i-or-a-is-probably = 'i'">
                     <!-- it's probably not an alphabetic numeral -->
                     <xsl:value-of select="($raw-old/tan:n/tan:val[not(@type = $n-type[4])])[1]"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:value-of select="$raw-old/tan:n/tan:val[1]"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <!-- no ambiguity; just use the first value -->
               <xsl:value-of select="$raw-old/tan:n/tan:val[1]"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not(@old = $new-old)">
            <xsl:attribute name="orig-old" select="@old"/>
            <xsl:attribute name="old" select="$new-old"/>
         </xsl:if>
         <!-- renames are empty, so no need to process further -->
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*[@ref and not(@orig-ref)]" mode="arabic-numerals">
      <!-- For the companion template, treating *[@n], see TAN-class-1-and-2-functions -->
      <xsl:param name="ambiguous-numeral-types" as="element()*" tunnel="yes"/>
      <!--<xsl:param name="treat-ambiguous-a-or-i-type-as-roman-numeral" as="xs:boolean?" tunnel="yes"/>
      <xsl:param name="warn-on-ambiguous-numerals" as="xs:boolean?" tunnel="yes"/>-->
      <!--<xsl:variable name="this-ref-norm" select="tan:normalize-text(lower-case(@ref))"/>-->
      <xsl:variable name="raw-ref" select="tan:analyze-elements-with-numeral-attributes(., (), false(), true())"/>
      <!--<xsl:variable name="new-ref"
         select="tan:normalize-refs(@ref, $treat-ambiguous-a-or-i-type-as-roman-numeral)"/>-->
      <xsl:variable name="new-ref-ns" as="xs:string*">
         <xsl:for-each select="$raw-ref/*">
            <xsl:choose>
               <xsl:when test="self::tan:sep">
                  <xsl:choose>
                     <xsl:when test="matches(.,'^ *, $|^ *- *$')">
                        <xsl:value-of select="replace(., '(\S)', ' $1 ')"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:value-of select="$separator-hierarchy"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:when>
               <xsl:when test="tan:val/@type = $n-type[1] and tan:val/@type = $n-type[4]">
                  <xsl:choose>
                     <xsl:when test="$ambiguous-numeral-types/@type-i-or-a-is-probably = 'a'">
                        <!-- it's probably not a Roman numeral -->
                        <xsl:value-of select="(tan:val[not(@type = $n-type[1])])[1]"/>
                     </xsl:when>
                     <xsl:when test="$ambiguous-numeral-types/@type-i-or-a-is-probably = 'i'">
                        <!-- it's probably not an alphabetic numeral -->
                        <xsl:value-of select="(tan:val[not(@type = $n-type[4])])[1]"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:value-of select="tan:val[1]"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:when>
               <xsl:otherwise>
                  <!-- no ambiguity; just use the first value -->
                  <xsl:value-of select="tan:val[1]"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="new-ref" select="normalize-space(string-join($new-ref-ns, ''))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not(@ref = $new-ref)">
            <xsl:attribute name="orig-ref" select="@ref"/>
            <xsl:attribute name="ref" select="$new-ref"/>
         </xsl:if>
         <xsl:apply-templates mode="arabic-numerals"/>
      </xsl:copy>
   </xsl:template>

   <!-- STEP SRC-1ST-DA: Get the first document available for each source picked -->
   <xsl:function name="tan:get-src-1st-da" as="document-node()*">
      <!-- zero-parameter version of the function below -->
      <xsl:copy-of select="tan:get-src-1st-da($src-ids)"/>
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da" as="document-node()*">
      <!-- This version allows one to exclude certain sources from processing -->
      <xsl:param name="srcs-picked" as="item()*"/>
      <xsl:variable name="srcs-picked-to-id-refs" select="tan:get-picked-srcs-id-refs($srcs-picked)"
         as="xs:string*"/>
      <xsl:copy-of
         select="
            for $i in ($srcs-picked-to-id-refs),
               $j in tan:first-loc-available($src-elements[(@xml:id, '1')[1] = $i])
            return
               if ($i = 'error' or $j = '') then
                  $empty-doc
               else
                  document($j)"
      />
   </xsl:function>

   <!-- functions for step -->
   <xsl:function name="tan:get-picked-srcs-id-refs" as="xs:string*">
      <xsl:param name="srcs-picked" as="item()*"/>
      <xsl:for-each select="$srcs-picked">
         <xsl:choose>
            <xsl:when test="matches(., '[-,] ')">
               <xsl:variable name="seq-exp" select="tan:sequence-expand(., count($src-elements))"/>
               <xsl:variable name="poss-ids" select="$src-elements[position() = $seq-exp]/@xml:id"/>
               <xsl:copy-of
                  select="
                     if (exists($poss-ids)) then
                        $poss-ids
                     else
                        '1'"
               />
            </xsl:when>
            <xsl:when test=". = $src-ids">
               <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test=". instance of xs:integer and . le count($src-elements)">
               <xsl:copy-of select="$src-elements[.]/(@xml:id, '1')[1]"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="'error'"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <!-- I think we can get rid of the next 2 functions, since this is being handled by tan:prep-resolved-class-1-doc() -->
   <!-- STEP SRC-1ST-DA-RESOLVED: Resolve source documents -->
   <xsl:function name="tan:get-src-1st-da-resolved" xml:id="v-src-1st-da-resolved">
      <!-- zero-parameter version of the next function -->
      <xsl:copy-of select="tan:get-src-1st-da-resolved(tan:get-src-1st-da(), $src-ids)"/>
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-resolved">
      <xsl:param name="picked-class-1-docs" as="document-node()*"/>
      <xsl:param name="picked-src-ids" as="xs:string*"/>
      <xsl:copy-of
         select="tan:resolve-doc($picked-class-1-docs, false(), 'src', $picked-src-ids, (), ())"/>
   </xsl:function>

   <!-- resultant functions -->
   <!-- Why do we need this function? -->
   <xsl:function name="tan:extract-src-elements" as="element()*">
      <xsl:param name="src-1st-da-resolved-elements" as="element()*"/>
      <xsl:for-each select="$src-1st-da-resolved-elements">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="src" select="root()/*/@src"/>
            <xsl:copy-of select="*"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>

   <!-- CLASS-2 PREPARATION, STEP 2: fully expand <equate-works>, <equate-div-types>, <token-definition>; check
   errors on the same, plus on <rename-div-ns>, <rename>, <suppress-div-types>-->

   <!--<xsl:function name="tan:get-self-expanded-2" as="document-node()*">
      <!-\- zero parameter function of the next -\->
      <xsl:variable name="self-expanded-1" select="tan:prep-resolved-class-2-doc($self-prepped[1])"/>
      <xsl:copy-of select="tan:get-self-expanded-2($self-prepped[1], tan:get-src-1st-da-resolved())"
      />
   </xsl:function>-->
   <xsl:function name="tan:prep-class-2-doc-pass-2" as="document-node()*">
      <!-- Input: class 2 document that has already gone through pass 1 of preparation; resolved documents -->
      <!-- Output: the class 2 document, with expansions of <equate-works> and <equate-div-types> and determination of <token-definition>. -->
      <xsl:param name="class-2-doc-prepped-pass-1" as="document-node()?"/>
      <xsl:param name="src-1st-da-resolved" as="document-node()*"/>
      <!--<xsl:variable name="token-definitions"
         select="tan:get-token-definitions-per-source($self-resolved-pass-1, $src-1st-da-resolved)"
         as="element()*"/>-->
      <xsl:variable name="work-elements"
         select="$src-1st-da-resolved/*/tan:head/tan:declarations/tan:work" as="element()*"/>
      <xsl:variable name="div-type-elements"
         select="$src-1st-da-resolved/*/tan:head/tan:declarations/tan:div-type" as="element()*"/>
      <xsl:variable name="token-definitions" as="element()*">
         <xsl:for-each select="$class-2-doc-prepped-pass-1/*/tan:head/tan:source/@xml:id">
            <xsl:variable name="this-src" select="."/>
            <xsl:variable name="this-tok-def"
               select="$class-2-doc-prepped-pass-1/*/tan:head/tan:declarations/tan:token-definition[@src = $this-src]"/>
            <xsl:variable name="that-tok-def"
               select="$src-1st-da-resolved/*[@src = $this-src]/tan:head/tan:declarations/tan:token-definition[1]"/>
            <xsl:choose>
               <xsl:when test="count($this-tok-def) = 1">
                  <xsl:copy-of select="$this-tok-def"/>
               </xsl:when>
               <xsl:when test="count($this-tok-def) gt 1">
                  <xsl:for-each select="$this-tok-def">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of select="tan:error('cl202')"/>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="($that-tok-def, $token-definitions-reserved)[1]"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="body-expansions" as="element()*">
         <xsl:if test="exists($class-2-doc-prepped-pass-1/tan:TAN-A-div)">
            <xsl:copy-of
               select="tan:group-by-IRIs($work-elements, $class-2-doc-prepped-pass-1/tan:TAN-A-div/tan:body/tan:equate-works)"/>
            <xsl:copy-of
               select="tan:group-by-IRIs($div-type-elements, $class-2-doc-prepped-pass-1/tan:TAN-A-div/tan:body/tan:equate-div-types)"
            />
         </xsl:if>
      </xsl:variable>
      <xsl:document>
         <xsl:apply-templates mode="prep-class-2-doc-pass-2" select="$class-2-doc-prepped-pass-1">
            <xsl:with-param name="token-definitions" select="$token-definitions" tunnel="yes"/>
            <xsl:with-param name="body-expansions" select="$body-expansions" tunnel="yes"/>
            <xsl:with-param name="div-type-elements" select="$div-type-elements" tunnel="yes"/>
            <xsl:with-param name="src-docs" select="$src-1st-da-resolved" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="tan:declarations" mode="prep-class-2-doc-pass-2">
      <xsl:param name="token-definitions" as="element()*" tunnel="yes"/>
      <xsl:param name="src-docs" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="src-n-types" as="element()*">
         <xsl:if test="descendant::tan:rename">
            <xsl:copy-of select="tan:get-n-types($src-docs)"/>
         </xsl:if>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$token-definitions"/>
         <xsl:apply-templates mode="#current" select="*[not(self::tan:token-definition)]">
            <xsl:with-param name="src-n-types" select="$src-n-types" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:suppress-div-types | tan:rename-div-ns" mode="prep-class-2-doc-pass-2">
      <xsl:param name="div-type-elements" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="relevant-div-type-elements"
         select="$div-type-elements[root()/*/@src = $this-element/@src]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if
            test="
               not(some $i in $relevant-div-type-elements
                  satisfies ($i/@xml:id = $this-element/@div-type-ref))">
            <xsl:variable name="this-message"
               select="concat('source ', @src, ' does not have div type ', @div-type-ref, '; try: ', string-join($relevant-div-type-elements/@xml:id, ', '))"/>
            <xsl:copy-of select="tan:error('dty01', $this-message)"/>
         </xsl:if>
         <xsl:apply-templates mode="prep-class-2-doc-pass-2"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:rename" mode="prep-class-2-doc-pass-2">
      <!--<xsl:param name="src-docs" as="document-node()*" tunnel="yes"/>-->
      <xsl:param name="src-n-types" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-rename" select="."/>
      <xsl:variable name="this-old" select="tan:normalize-text(@old)"/>
      <xsl:variable name="this-new" select="tan:normalize-text(@new)"/>
      <xsl:variable name="this-rename-parent" select=".."/>
      <xsl:variable name="relevant-n-types"
         select="$src-n-types[@src = $this-rename-parent/@src]/tan:div-type[@xml:id = $this-rename-parent/@div-type-ref]"/>
      <xsl:variable name="ns-in-use" select="tokenize($relevant-n-types/@unique-n-values, ' ')"/>
      <!--<xsl:variable name="this-src-root" select="$src-docs[*/@src = $this-rename-parent/@src]"/>-->
      <!--<xsl:variable name="this-src-relevant-divs"
         select="$this-src-root//*:div[@type = $this-rename-parent/@div-type-ref]"/>-->
      <!--<xsl:variable name="this-src-relevant-ns" as="xs:string*"
         select="tokenize($relevant-n-types/@unique-n-values, ' ')"/>-->
      <xsl:variable name="all-parallel-renames"
         select="ancestor::tan:declarations/tan:rename-div-ns[@src = $this-rename-parent/@src and @div-type-ref = $this-rename-parent/@div-type-ref]/tan:rename"/>
      <xsl:variable name="help-requested-attr-old" select="tan:help-requested(@old)"/>
      <xsl:variable name="old-close-matches" select="$ns-in-use[matches(., $this-old)]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$this-old = $this-new">
            <xsl:copy-of select="tan:error('cl203')"/>
         </xsl:if>
         <xsl:if
            test="
               count($all-parallel-renames[@old = $this-old]) gt 1
               or count($all-parallel-renames[@new = $this-new]) gt 1">
            <xsl:copy-of select="tan:error('cl204')"/>
         </xsl:if>
         <xsl:if test="not($this-old = $ns-in-use)">
            <xsl:variable name="this-message"
               select="concat('source ', @src, ' does not have ', $this-old, ' in div type ', @div-type-ref, '; close matches: ', string-join($old-close-matches, ', '), '; all possible values: ', string-join($ns-in-use, ', '))"
            />
            <xsl:copy-of select="tan:error('cl212', $this-message)"/>
         </xsl:if>
         <xsl:if test="$help-requested-attr-old = true()">
            <xsl:variable name="this-message"
               select="concat('close matches: ', string-join($old-close-matches, ', '), '; all possible values: ', string-join($ns-in-use, ', '))"
            />
            <xsl:copy-of select="tan:help($this-message, $old-close-matches)"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:body" mode="prep-class-2-doc-pass-2">
      <xsl:param name="body-expansions" as="element()*" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$body-expansions"/>
         <xsl:copy-of select="*[not(self::tan:equate-works | self::tan:equate-div-types)]"/>
      </xsl:copy>
   </xsl:template>

   <!-- Functions for step -->
   <xsl:function name="tan:group-by-IRIs" as="element()*">
      <xsl:param name="elements-with-IRI-children" as="element()*"/>
      <xsl:copy-of select="tan:group-by-IRIs($elements-with-IRI-children, ())"/>
   </xsl:function>
   <xsl:function name="tan:group-by-IRIs" as="element()*">
      <!-- Input: Any elements that have children <IRI>s; a sequence of elements that pre-determine select equations -->
       <!--  Output: Those same elements grouped as children of either <equate-works>, <equate-div-types>, or <group> (depending upon name of element), based on equivalencies in IRI values. Each <group> will also include an @n value, acting as a kind of identifier. -->
       <!--  Note, IRI equivalencies are greedy and transitive. If element X has IRI A,  Y has IRIs A and B, and Z has IRI B, then elements X and Z will be equated. -->
      <xsl:param name="elements-with-IRI-children" as="element()*"/>
      <xsl:param name="equate-elements" as="element()*"/>
      <xsl:variable name="elements-prep" as="element()*">
         <xsl:for-each select="$elements-with-IRI-children">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <!--<xsl:copy-of select="ancestor::tan:TAN-T/@src"/>-->
               <xsl:copy-of select="root()/*/@src"/>
               <xsl:copy-of select="node()"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="preliminary-tree-of-groups" as="element()">
         <tree>
            <xsl:for-each select="$equate-elements">
               <xsl:variable name="these-srcs" select=".//@src"/>
               <xsl:variable name="these-div-type-refs" select=".//@div-type-ref"/>
               <xsl:variable name="elements-to-place"
                  select="
                     $elements-prep[@src = $these-srcs][if (self::tan:div-type) then
                        @xml:id = $these-div-type-refs
                     else
                        true()]"/>
               <xsl:variable name="defective-div-type-refs"
                  select="
                     tan:div-type-ref[not(some $i in $elements-prep
                        satisfies ($i/@src = @src and $i/@xml:id = @div-type-ref))]"/>
               <xsl:variable name="redundant-equates"
                  select="
                     for $i in (2 to count($elements-to-place))
                     return
                        $elements-to-place[$i][tan:IRI = $elements-to-place[position() lt $i]/tan:IRI]"
               />
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="tan:help, tan:error, tan:info, tan:fatal"/>
                  <xsl:if test="self::tan:equate-div-types and exists($defective-div-type-refs)">
                     <xsl:variable name="this-message"
                        select="
                           string-join(for $i in $defective-div-type-refs
                           return
                              concat('source ', $i/@src, ' does not have div type ', $i/@div-type-ref), '; ')"/>
                     <xsl:copy-of select="tan:error('dty01', $this-message)"/>
                     <xsl:copy-of select="$defective-div-type-refs"/>
                     <!--<test><xsl:copy-of select="$defective-div-type-refs"/></test>-->
                  </xsl:if>
                  <xsl:if test="exists($redundant-equates)">
                     <xsl:copy-of select="tan:error('equ01')"/>
                  </xsl:if>
                  <xsl:copy-of select="$elements-to-place"/>
               </xsl:copy>
            </xsl:for-each>
         </tree>
      </xsl:variable>
      <xsl:variable name="unplaced-elements" select="$elements-prep[not(some $i in $preliminary-tree-of-groups//*
         satisfies deep-equal(., $i))]"/>
      <!--<test><xsl:copy-of select="$preliminary-tree-of-groups"/></test>-->
      <xsl:variable name="results" select="tan:group-by-IRIs-loop($preliminary-tree-of-groups, $unplaced-elements)"
      />
      <xsl:for-each select="$results">
         <!-- we have to re-sort it, because we started with specially equated items -->
         <xsl:sort
            select="
               min(for $i in */@src
               return
                  index-of($elements-prep/@src, $i))"
         />
         <xsl:copy-of select="."/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:group-by-IRIs-loop" as="element()*">
      <!-- Input: an element containing zero or more <group> children; a sequence of elements yet to be placed
         in a <group>
         Output: a sequence of groups (= <equate-works>, <equate-div-types>, or <group>) lumping together elements 
         based on commonality of their <IRI> values 
      -->
      <xsl:param name="tree-of-groups-so-far" as="element()?"/>
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:variable name="next-item" select="$elements-to-group[1]"/>
      <xsl:variable name="group-name" as="xs:string">
         <xsl:choose>
            <xsl:when test="$next-item/self::tan:work">
               <xsl:text>equate-works</xsl:text>
            </xsl:when>
            <xsl:when test="$next-item/self::tan:div-type">
               <xsl:text>equate-div-types</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>group</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!--<xsl:variable name="this-src" select="$next-item/ancestor::tan:TAN-T/@src"/>-->
      <xsl:variable name="this-src" select="root($next-item)/*/@src"/>
      <xsl:variable name="matched-groups"
         select="$tree-of-groups-so-far/*[*/tan:IRI = $next-item/tan:IRI]"/>
      <xsl:variable name="unmatched-groups"
         select="$tree-of-groups-so-far/*[not(*/tan:IRI = $next-item/tan:IRI)]"/>
      <xsl:variable name="new-group" as="element()">
         <xsl:element name="{$group-name}">
            <xsl:copy-of select="$matched-groups/*"/>
            <xsl:for-each select="$next-item">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="$this-src"/>
                  <xsl:copy-of select="node()"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:element>
      </xsl:variable>
      <xsl:variable name="new-tree" as="element()">
         <tree>
            <xsl:choose>
               <xsl:when test="exists($matched-groups)">
                  <xsl:copy-of select="$matched-groups[1]/preceding-sibling::*"/>
                  <!--<xsl:copy-of select="$matched-groups"/>-->
                  <xsl:copy-of select="$new-group"/>
                  <xsl:copy-of
                     select="$matched-groups[1]/following-sibling::* except $matched-groups"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="$tree-of-groups-so-far/*"/>
                  <xsl:copy-of select="$new-group"/>
               </xsl:otherwise>
            </xsl:choose>
         </tree>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="not(exists($next-item))">
            <xsl:copy-of select="$tree-of-groups-so-far/*"/>
            <!--<xsl:for-each select="$tree-of-groups-so-far/*">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="n" select="count(preceding-sibling::*) + 1"/>
                  <xsl:copy-of select="node()"/>
               </xsl:copy>
            </xsl:for-each>-->
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of
               select="tan:group-by-IRIs-loop($new-tree, $elements-to-group[position() gt 1])"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>
   
   <!-- Let's see if we can't integrate this into tan:prep-resolved-class-1-doc(). But maybe we can't because that function is the first one that corrects the @n values in the sources-->
   <xsl:function name="tan:pick-prepped-class-1-data" as="document-node()*">
      <!-- Used to create a subset of $src-1st-da-prepped 
         Input: (1) prepped source documents. (2) one or more elements with @src and @ref. It is assumed that both 
         attributes have single, atomic values (i.e., no ranges in @ref). (3) boolean indicating whether the values
         of @src and @ref should be treated as regular expressions
         Output: src-1st-da-prepped, proper subset that consists exclusively of matches
      -->
      <xsl:param name="elements-with-atomic-src-and-ref-attributes" as="element()*"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:param name="treat-src-and-ref-as-regex" as="xs:boolean"/>
      <xsl:variable name="erroneous-refs" as="element()*">
         <xsl:for-each select="$elements-with-atomic-src-and-ref-attributes">
            <xsl:variable name="this-element" select="."/>
            <xsl:if
               test="
                  not($src-1st-da-prepped/*[if ($treat-src-and-ref-as-regex = false()) then
                     @src = $this-element/@src
                  else
                     matches(@src, $this-element/@src)]/tan:body//tan:div[if ($treat-src-and-ref-as-regex = false()) then
                     @ref = $this-element/@ref
                  else
                     matches(@ref, $this-element/@ref)])">
               <xsl:sequence select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="valid-refs"
         select="$elements-with-atomic-src-and-ref-attributes except $erroneous-refs"/>
      <xsl:for-each
         select="
            $src-1st-da-prepped[if ($treat-src-and-ref-as-regex = false()) then
               */@src = $valid-refs/@src
            else
               for $i in $valid-refs
               return
                  matches(*/@src, $i/@src)]">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy>
            <xsl:copy-of select="processing-instruction() | comment()"/>
            <xsl:for-each select="*">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="tan:head"/>
                  <xsl:for-each select="tan:body">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:if test="exists($erroneous-refs)">
                           <xsl:copy-of
                              select="tan:error('ref01', string-join($erroneous-refs/@ref, ', '))"/>
                           <!--<errors>
                              <xsl:copy-of select="$erroneous-refs"/>
                           </errors>-->
                        </xsl:if>
                        <xsl:apply-templates mode="pick-prepped-class-1">
                           <xsl:with-param name="refs-norm"
                              select="
                                 $valid-refs[if ($treat-src-and-ref-as-regex = false()) then
                                    @src = $this-src
                                 else
                                    matches($this-src, @src)]"/>
                           <xsl:with-param name="treat-src-and-ref-as-regex"
                              select="$treat-src-and-ref-as-regex"/>
                        </xsl:apply-templates>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:copy>
            </xsl:for-each>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="tan:div" mode="pick-prepped-class-1">
      <xsl:param name="refs-norm" as="element()*"/>
      <xsl:param name="treat-src-and-ref-as-regex" as="xs:boolean"/>
      <xsl:choose>
         <xsl:when
            test="
               if ($treat-src-and-ref-as-regex = false()) then
                  self::tan:div/@ref = $refs-norm/@ref
               else
                  some $i in $refs-norm
                     satisfies
                     matches(self::tan:div/@ref, $i/@ref)">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:when
            test="
               if ($treat-src-and-ref-as-regex = false()) then
                  descendant::tan:div/@ref = $refs-norm/@ref
               else
                  some $i in $refs-norm,
                     $j in descendant::tan:div
                     satisfies
                     matches($j/@ref, $i/@ref)">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="refs-norm" select="$refs-norm"/>
                  <xsl:with-param name="treat-src-and-ref-as-regex"
                     select="$treat-src-and-ref-as-regex"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <!-- tan:cull-prepped-class-1-data() assumes you want most prepped data, just not some divs -->
   <!--<xsl:function name="tan:cull-prepped-class-1-data" as="document-node()*">
      <!-\- 1-param function of the 2-param version below -\->
      <xsl:param name="elements-with-atomic-src-and-ref-attributes" as="element()*"/>
      <xsl:variable name="src-1st-da-prepped" select="tan:prep-resolved-class-1-doc()"/>
      <xsl:copy-of
         select="tan:cull-prepped-class-1-data($elements-with-atomic-src-and-ref-attributes, $src-1st-da-prepped, false())"
      />
   </xsl:function>-->
   <xsl:function name="tan:cull-prepped-class-1-data" as="document-node()*">
      <!-- Used to create a subset of $src-1st-da-prepped 
         Input: (1) prepped source documents. (2) one or more elements with @src and @ref. It is assumed that both 
         attributes have single, atomic values (i.e., no ranges in @ref). (3) boolean indicating whether the values
         of @src and @ref should be treated as regular expressions
         Output: src-1st-da-prepped, proper subset, excluding matches
      -->
      <xsl:param name="elements-with-atomic-src-and-ref-attributes" as="element()*"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:param name="treat-src-and-ref-as-regex" as="xs:boolean"/>
      <xsl:variable name="erroneous-refs" as="element()*">
         <xsl:for-each select="$elements-with-atomic-src-and-ref-attributes">
            <xsl:variable name="this-element" select="."/>
            <xsl:if
               test="
                  not($src-1st-da-prepped/*[if ($treat-src-and-ref-as-regex = false()) then
                     @src = $this-element/@src
                  else
                     matches(@src, $this-element/@src)]/tan:body//tan:div[if ($treat-src-and-ref-as-regex = false()) then
                     @ref = $this-element/@ref
                  else
                     matches(@ref, $this-element/@ref)])">
               <xsl:sequence select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="valid-refs"
         select="$elements-with-atomic-src-and-ref-attributes except $erroneous-refs"/>
      <xsl:for-each select="$src-1st-da-prepped">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy>
            <xsl:copy-of select="processing-instruction() | comment()"/>
            <xsl:for-each select="*">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="tan:head"/>
                  <xsl:for-each select="tan:body">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:if test="exists($erroneous-refs)">
                           <xsl:copy-of
                              select="tan:error('ref01', string-join($erroneous-refs/@ref, ', '))"/>
                           <!--<errors>
                              <xsl:copy-of select="$erroneous-refs"/>
                           </errors>-->
                        </xsl:if>
                        <xsl:apply-templates mode="cull-prepped-class-1">
                           <xsl:with-param name="refs-norm"
                              select="
                                 $valid-refs[if ($treat-src-and-ref-as-regex = false()) then
                                    @src = $this-src
                                 else
                                    matches($this-src, @src)]"/>
                           <xsl:with-param name="treat-src-and-ref-as-regex"
                              select="$treat-src-and-ref-as-regex"/>
                        </xsl:apply-templates>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:copy>
            </xsl:for-each>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="tan:div" mode="cull-prepped-class-1">
      <xsl:param name="refs-norm" as="element()*"/>
      <xsl:param name="treat-src-and-ref-as-regex" as="xs:boolean"/>
      <xsl:choose>
         <xsl:when
            test="
               if ($treat-src-and-ref-as-regex = false()) then
                  self::tan:div/@ref = $refs-norm/@ref
               else
                  some $i in $refs-norm
                     satisfies
                     matches(self::tan:div/@ref, $i/@ref)"/>
         <xsl:when
            test="
               if ($treat-src-and-ref-as-regex = false()) then
                  descendant::tan:div/@ref = $refs-norm/@ref
               else
                  some $i in $refs-norm,
                     $j in descendant::tan:div
                     satisfies
                     matches($j/@ref, $i/@ref)">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="refs-norm" select="$refs-norm"/>
                  <xsl:with-param name="treat-src-and-ref-as-regex"
                     select="$treat-src-and-ref-as-regex"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- CLASS-2 PREPARATION, STEP 3: revise a step-2-prepped class-2 file by fully expanding @ref (<tok>, <realign>, <align>) and @seg; distribute into groups; depends upon src-1st-da-prepped, unless if @seg is invoked, in which case it depends upon src-1st-da-tokenized, or else the function attempts to convert <split-leaf-div-at> into tokenized and segmented divs -->

   <xsl:function name="tan:prep-class-2-doc-pass-3" as="document-node()?">
      <!-- Input: a class-2 document, that has gone through two stages of preparation; sources that have gone through one level of preparation -->
      <!-- Output: the class-2 document with @work and @ref expanded; provide help on <equate-works>, <equate-div-types> (TAN-A-div) -->
      <xsl:param name="class-2-doc-prepped-pass-2" as="document-node()?"/>
      <xsl:param name="sources-prepped-1" as="document-node()*"/>
      <xsl:document>
         <xsl:apply-templates mode="prep-class-2-doc-pass-3" select="$class-2-doc-prepped-pass-2">
            <xsl:with-param name="sources-prepped-1" select="$sources-prepped-1" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   
   <!-- Nov 2016: delenda -->
   <!--<xsl:function name="tan:prep-class-2-doc-pass-3-old" as="document-node()?">
      <!-\- Input: a class-2 document, that has gone through two stages of preparation; sources that have gone through one level of preparation -\->
      <!-\- Output: the class-2 document -\->
      <xsl:param name="class-2-doc-prepped-pass-2" as="document-node()?"/>
      <xsl:param name="sources-prepped-1" as="document-node()*"/>
      <xsl:variable name="class-2-doc-pass-3-prelim" as="document-node()?">
         <!-\- The primary templates that shape this variable are at TAN-A-div-functions.xsl -\->
         <xsl:document>
            <xsl:apply-templates select="$class-2-doc-prepped-pass-2"
               mode="prep-tan-a-div-pass-3-prelim">
               <xsl:with-param name="sources-prepped-1" select="$sources-prepped-1" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:document>
      </xsl:variable>
      <!-\-<xsl:copy-of select="$class-2-doc-pass-3-prelim"/>-\->
      <xsl:document>
         <xsl:apply-templates mode="prep-class-2-doc-pass-3-old"
            select="$class-2-doc-pass-3-prelim">
            <xsl:with-param name="sources-prepped-1" select="$sources-prepped-1" tunnel="yes"/>
            <!-\-<xsl:with-param name="keep-text" select="$include-text-in-attr-ref-expansions"
               tunnel="yes"/>-\->
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>-->
   
   
   <xsl:template match="*[@ref]" mode="prep-class-2-doc-pass-3">
      <xsl:param name="sources-prepped-1" as="document-node()*" tunnel="yes"/>
      <!-- Distribute elements across @work and @ref -->
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:variable name="this-work" select="tan:normalize-text(@work)"/>
      <xsl:variable name="help-requested" select="tan:help-requested(.)"/>
      <xsl:variable name="these-sources"
         select="
            if (exists($this-work)) then
               ancestor::tan:body/tan:equate-works[tan:work/@src = $this-work]/tan:work/@src
            else
               @src"
      />
      <xsl:for-each select="$these-sources">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="this-src-doc" select="$sources-prepped-1[*/@src = $this-src]"/>
         <xsl:variable name="ignore-error-if-ref-not-found"
            select="(exists($this-work) and not($this-src = $this-work))"/>
         <xsl:variable name="this-div-fragment" select="tan:convert-ref-to-div-fragment($this-src-doc, $this-element, $help-requested, $ignore-error-if-ref-not-found)"/>
         <xsl:choose>
            <xsl:when test="$this-element-name = 'tok'">
               <!-- In the case of <tok>, every @ref needs to be expanded -->
               <xsl:for-each
                  select="
                     if (exists($this-div-fragment)) then
                        $this-div-fragment
                     else
                        ''">
                  <xsl:variable name="atomic-ref" select="@ref"/>
                  <xsl:element name="{$this-element-name}">
                     <xsl:copy-of select="$this-element/(@* except @ref)"/>
                     <xsl:copy-of select="$this-src"/>
                     <xsl:if test="not($atomic-ref = $this-element/@ref)">
                        <xsl:attribute name="norm-ref" select="$this-element/@ref"/>
                     </xsl:if>
                     <xsl:attribute name="ref" select="$atomic-ref"/>
                     <xsl:copy-of
                        select="$this-element/(tan:error, tan:help, tan:info, tan:message)"/>
                     <xsl:copy-of select="."/>
                  </xsl:element>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <!-- In the case of <div-ref> and <anchor-div-ref> every @ref is part of a group -->
               <xsl:element name="{$this-element-name}">
                  <xsl:copy-of select="$this-element/@*"/>
                  <xsl:copy-of select="$this-src"/>
                  <xsl:copy-of select="$this-element/(tan:error, tan:help, tan:info, tan:message, tan:warning)"/>
                  <xsl:copy-of select="$this-div-fragment"/>
               </xsl:element>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>
   
   <xsl:function name="tan:convert-ref-to-div-fragment" as="item()*">
      <!-- Input: source document, at least prepped; an element with an unresolved @ref; indication whether the text should be retrieved or not -->
      <!-- Output: a fragment from the source document with the hierarchies of only those divs that correspond to the range specified by @ref -->
      <!-- It is assumed that the second parameter refers to the first; that is, the source document really is the one that the element with @ref is trying to cite. -->
      <!-- It is also assumed that in any range where the second element has fewer @n values than the first, then the abbreviated form will be checked before the form actually stated. For example, 1 1 - 2 will be tested first for 1 1 - 1 2, which, if not corresponding to an actual <div>, will be interpeted as 1 1 - 2 -->
      <xsl:param name="prepped-src-doc" as="document-node()?"/>
      <xsl:param name="element-with-ref-attr" as="element()?"/>
      <xsl:param name="keep-text" as="xs:boolean"/>
      <xsl:param name="missing-ref-returned-as-info-not-error" as="xs:boolean"/>
      <xsl:variable name="this-src" select="($element-with-ref-attr/@src, $prepped-src-doc/*/@src)[1]"/>
      <xsl:variable name="ref-analyzed" select="tan:analyze-ref($element-with-ref-attr/@ref)" as="element()"/>
      <!--<test><xsl:copy-of select="$ref-analyzed"/></test>-->
      <xsl:for-each-group select="$ref-analyzed/*" group-starting-with="tan:comma">
         <xsl:variable name="these-refs" select="current-group()/self::tan:ref"/>
         <xsl:variable name="div-start-prelim" select="key('div-via-ref', $these-refs[1], $prepped-src-doc)"/>
         <xsl:variable name="div-start"
            select="
               if (exists($div-start-prelim)) then
                  $div-start-prelim
               else
                  key('div-via-ref', $these-refs[1]/@orig, $prepped-src-doc)"
         />
         <!--<xsl:variable name="div-start-and-following-siblings" select="($div-start, $div-start/following-sibling::*)"/>-->
         <xsl:variable name="div-end-prelim" select="key('div-via-ref', $these-refs[2], $prepped-src-doc)"/>
         <xsl:variable name="div-end"
            select="
               if (exists($div-end-prelim)) then
                  $div-end-prelim
               else
                  key('div-via-ref', $these-refs[2]/@orig, $prepped-src-doc)"
         />
         <!--<test><xsl:copy-of select="$these-refs"/></test>-->
         <!--<xsl:variable name="div-end-and-preceding-siblings" select="($div-end/preceding-sibling::*, $div-end)"/>-->
         <!--<xsl:variable name="div-intersection" select="$div-start-and-following-siblings intersect $div-end-and-preceding-siblings"/>-->
         <xsl:variable name="ref-options" select="$these-refs/(text(), @orig)"/>
         <xsl:variable name="ref-options-help-requested"
            select="$ref-options[matches(., $help-trigger-regex)]"/>
         <xsl:variable name="ref-searches" as="xs:string*">
            <xsl:for-each select="$ref-options-help-requested">
               <xsl:variable name="this-ref-norm" select="tan:normalize-text(.)"/>
               <xsl:value-of
                  select="
                     if (matches($this-ref-norm, '\S')) then
                        $this-ref-norm
                     else
                        '^\w+$'"
               />
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="this-regex-search"
            select="string-join(distinct-values($ref-searches), '|')"/>
         <xsl:variable name="ref-near-matches" select="$prepped-src-doc/tan:TAN-T/tan:body//tan:div[matches(@ref, $this-regex-search)]"/>
         
         <xsl:variable name="div-start-ancestry" select="$div-start/ancestor-or-self::*"/>
         <xsl:variable name="div-end-ancestry" select="$div-end/ancestor-or-self::*"/>
         <xsl:variable name="common-ancestry" select="$div-start-ancestry intersect $div-end-ancestry"/>
         <xsl:variable name="last-common-ancestor" select="$common-ancestry[last()]"/>
         <!--<xsl:variable name="lca-middle-children" select="$last-common-ancestor/*[@ref = $div-start-ancestry/@ref]/following-sibling::* 
            except $last-common-ancestor/*[@ref = $div-end-ancestry/@ref]/(self::*, following-sibling::*)"/>-->
         <xsl:variable name="lca-ancestry" select="$last-common-ancestor/ancestor-or-self::*"/>
         <xsl:variable name="div-start-depth" select="count($div-start-ancestry)"/>
         <xsl:variable name="div-end-depth" select="count($div-end-ancestry)"/>
         <xsl:variable name="lca-depth" select="count($lca-ancestry)"/>
         <xsl:variable name="default-level" select="min(($div-start-depth, $div-end-depth))"/>
         <!--<xsl:variable name="shallower-start"
            select="
               if ($div-start-depth gt $default-level) then
                  $div-start-ancestry[$default-level]
               else
                  ()"
         />-->
         <!--<xsl:variable name="shallower-start" select="$div-start-ancestry[$default-level]"/>
         <xsl:variable name="shallower-end" select="$div-end-ancestry[$default-level]"/>-->
         <xsl:variable name="plucked-fragment">
            <plucked>
               <xsl:copy-of select="tan:pluck($last-common-ancestor, $default-level - $lca-depth + 1, true())"/>
            </plucked>
         </xsl:variable>
         <xsl:variable name="plucked-start" select="$plucked-fragment/tan:plucked/*[@ref = $div-start-ancestry/@ref]"/>
         <xsl:variable name="plucked-end" select="$plucked-fragment/tan:plucked/*[@ref = $div-end-ancestry/@ref]"/>
         <xsl:variable name="plucked-middle" select="$plucked-start/following-sibling::* intersect $plucked-end/preceding-sibling::*"/>
         <!--<xsl:variable name="plucked-start-refined" as="element()*">
            <xsl:choose>
               <xsl:when test="exists($shallower-start)">
                  <xsl:copy-of select="$div-start"/>
                  <xsl:copy-of select="$div-start-ancestry[position() gt $default-level]/following-sibling::*"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$plucked-start"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>-->
         <!--<xsl:variable name="plucked-end-refined" as="element()*">
            <xsl:choose>
               <xsl:when test="exists($shallower-end)">
                  <xsl:copy-of select="$div-end-ancestry[position() gt $default-level]/preceding-sibling::*"/>
                  <xsl:copy-of select="$div-end"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$plucked-end"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>-->
         <!--<test><xsl:copy-of select="$div-start-depth"/></test>-->
         <!--<test><xsl:copy-of select="$div-end-depth"/></test>-->
         <!--<test><xsl:copy-of select="tan:shallow-copy($shallower-start)"/></test>-->
         <!--<test><xsl:copy-of select="tan:shallow-copy($last-common-ancestor)"/></test>-->
         <!--<test><xsl:copy-of select="$default-level"/></test>-->
         <!--<test><xsl:copy-of select="$lca-depth"/></test>-->
         <!--<test><xsl:copy-of select="tan:shallow-copy($plucked-fragment/*/*)"/></test>-->
         <!--<test><xsl:copy-of select="tan:shallow-copy($plucked-end-refined)"/></test>-->
         
         <xsl:variable name="this-fragment" as="element()*">
            <xsl:choose>
               <xsl:when test="count($these-refs) = 1">
                  <xsl:choose>
                     <xsl:when test="$keep-text = true()">
                        <xsl:copy-of select="$div-start"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of select="tan:shallow-copy($div-start)"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="this-fragment-range"
                     select="
                        ($div-start,
                        $div-start-ancestry[position() gt $default-level]/following-sibling::*,
                        $plucked-middle,
                        $div-end-ancestry[position() gt $default-level]/preceding-sibling::*,
                        $div-end)"
                  />
                  <!--<xsl:variable name="this-fragment-range" as="element()*">
                     <!-\-<xsl:choose>
                        <xsl:when test="exists($div-intersection)">
                           <xsl:copy-of select="$div-intersection"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:copy-of select="$div-start-and-following-siblings"/>
                           <xsl:copy-of
                              select="tan:pluck($lca-middle-children, count($lca-ancestry), true())"/>
                           <xsl:copy-of select="$div-end-and-preceding-siblings"/>
                        </xsl:otherwise>
                     </xsl:choose>-\->
                     <xsl:sequence
                        select="($plucked-start-refined, $plucked-middle, $plucked-end-refined)"/>
                  </xsl:variable>-->
                  <xsl:choose>
                     <xsl:when test="$keep-text = true()">
                        <xsl:copy-of select="$this-fragment-range"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of select="tan:shallow-copy($this-fragment-range)"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:if test="exists($ref-options-help-requested)">
            <xsl:variable name="this-message"
               select="concat('for source ', $this-src, ' try: ', string-join($ref-near-matches/@ref, '; '))"/>
            <xsl:copy-of select="tan:help($this-message, $this-fragment)"/>
         </xsl:if>
         <xsl:if test="not(exists($this-fragment)) and (exists($div-start) and exists($div-end))">
            <xsl:copy-of select="tan:error('ref04', concat($div-start/@ref,' and ', $div-end/@ref, ' point to real divisions, but do not create a range'))"/>
         </xsl:if>
         <xsl:if test="exists($div-start[not(tan:div)]) and count($div-start) gt 1">
            <xsl:copy-of select="tan:error('ref02', string-join($these-refs[1]/(text(), @orig),' or '))"/>
         </xsl:if>
         <xsl:if test="exists($div-end[not(tan:div)]) and count($div-end) gt 1">
            <xsl:copy-of select="tan:error('ref02', string-join($these-refs[2]/(text(), @orig),' or '))"/>
         </xsl:if>
         <xsl:choose>
            <xsl:when
               test="not(exists($div-start)) or (count($these-refs) gt 1 and not(exists($div-end)))">
               <!-- ref doesn't match a div -->
               <xsl:variable name="this-message" as="xs:string*">
                  <xsl:text>source</xsl:text>
                  <xsl:value-of select="$this-src"/>
                  <xsl:text>does not have</xsl:text>
                  <xsl:value-of
                     select="
                        if (not(exists($div-start))) then
                           $these-refs[1]
                        else
                           ()"/>
                  <xsl:value-of
                     select="
                        if (not(exists($div-end))) then
                           $these-refs[2]
                        else
                           ()"
                  />
               </xsl:variable>
               <xsl:choose>
                  <xsl:when test="$missing-ref-returned-as-info-not-error = false()">
                     <xsl:copy-of select="tan:error('ref01', string-join($this-message, ' '))"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="tan:info(string-join($this-message, ' '), ())"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="$this-fragment"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each-group> 
      <!-- Jan 2017: delendum -->
      <!--<xsl:for-each select="tokenize($element-with-ref-attr/@ref, ' ?, ')">
         <xsl:variable name="ref-atoms" select="tokenize(tan:normalize-text(.), '\s+-\s+')"/>
         <xsl:variable name="ref-start" select="$ref-atoms[1]"/>
         <xsl:variable name="ref-start-ns" select="tokenize($ref-start, '\W')"/>
         <xsl:variable name="ref-end-raw" select="$ref-atoms[2]"/>
         <xsl:variable name="ref-end-raw-ns" select="tokenize($ref-end-raw, '\W')"/>
         <xsl:variable name="ref-end-diff" select="count($ref-start-ns) - count($ref-end-raw-ns)"/>
         <xsl:variable name="ref-end-norm"
            select="
               if ($ref-end-diff gt 0) then
                  string-join((subsequence($ref-start-ns, 1, $ref-end-diff), $ref-end-raw-ns), ' ')
               else
                  $ref-end-raw"
         />
         <!-\-<xsl:variable name="div-start"
            select="$prepped-src-doc/tan:TAN-T/tan:body//tan:div[@ref = $ref-start]"/>-\->
         <xsl:variable name="div-start"
            select="key('div-via-ref', $ref-start, $prepped-src-doc)"/>
         <!-\-<xsl:variable name="div-end-prelim"
            select="$prepped-src-doc/tan:TAN-T/tan:body//tan:div[@ref = $ref-end-norm]"/>-\->
         <xsl:variable name="div-start-and-following-siblings" select="($div-start, $div-start/following-sibling::*)"/>
         <xsl:variable name="div-end-prelim"
            select="key('div-via-ref', $ref-end-norm, $prepped-src-doc)"/>
         <!-\-<xsl:variable name="div-end"
            select="
               if (exists($div-end-prelim)) then
                  $div-end-prelim
               else
                  $prepped-src-doc/tan:TAN-T/tan:body//tan:div[@ref = $ref-end-raw]"
         />-\->
         <xsl:variable name="div-end"
            select="
               if (exists($div-end-prelim)) then
                  $div-end-prelim
               else
                  key('div-via-ref', $ref-end-raw, $prepped-src-doc)"
         />
         <xsl:variable name="div-end-and-preceding-siblings" select="($div-end/preceding-sibling::*, $div-end)"/>
         <xsl:variable name="div-intersection" select="$div-start-and-following-siblings intersect $div-end-and-preceding-siblings"/>

         <xsl:variable name="ref-start-search"
            select="
               if (not(matches($ref-start, '\S'))) then
                  '^\w+$'
               else
                  $ref-start"
         />
         <xsl:variable name="ref-end-search"
            select="
               if (not(matches($ref-end-norm, '\S'))) then
                  '^\w+$'
               else
                  $ref-end-norm"
         />
         <xsl:variable name="ref-start-help-requested"
            select="matches($ref-atoms[1], $help-trigger-regex)"/>
         <xsl:variable name="ref-end-help-requested"
            select="matches($ref-atoms[2], $help-trigger-regex)"/>
         <xsl:variable name="ref-start-near-matches"
            select="$prepped-src-doc/tan:TAN-T/tan:body//tan:div[matches(@ref, $ref-start-search)]"/>
         <xsl:variable name="ref-end-near-matches"
            select="$prepped-src-doc/tan:TAN-T/tan:body//tan:div[matches(@ref, $ref-end-search)]"/>
         

         <xsl:variable name="div-start-ancestry" select="$div-start/ancestor-or-self::*"/>
         <xsl:variable name="div-end-ancestry" select="$div-end/ancestor-or-self::*"/>
         <xsl:variable name="common-ancestry" select="$div-start-ancestry intersect $div-end-ancestry"/>
         <xsl:variable name="lowest-common-ancestor" select="$common-ancestry[last()]"/>
         <xsl:variable name="lca-middle-children" select="$lowest-common-ancestor/*[@ref = $div-start-ancestry/@ref]/following-sibling::* 
            except $lowest-common-ancestor/*[@ref = $div-end-ancestry/@ref]/(self::*, following-sibling::*)"/>
         <xsl:variable name="lca-ancestry" select="$lowest-common-ancestor/ancestor-or-self::*"/>
         <xsl:variable name="ref-level" select="min((count($div-start-ancestry), count($div-end-ancestry)))"/>
         
         


         <xsl:variable name="div-end-ancestors" select="$div-end/ancestor::tan:div"/>
         <xsl:variable name="this-fragment" as="element()*">
            <xsl:choose>
               <xsl:when test="count($ref-atoms) = 1">
                  <xsl:choose>
                     <xsl:when test="$keep-text = true()">
                        <xsl:copy-of select="$div-start"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of select="tan:shallow-copy($div-start)"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:when>
               <!-\-<xsl:when test="count($ref-atoms) = 1 and $keep-text = false()">
                  <xsl:apply-templates select="$div-start" mode="strip-text"/>
               </xsl:when>-\->
               <xsl:otherwise>
                  <xsl:variable name="this-fragment-range" as="element()*">
                     <xsl:choose>
                        <xsl:when test="exists($div-intersection)">
                           <xsl:copy-of select="$div-intersection"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:copy-of select="$div-start-and-following-siblings"/>
                           <xsl:copy-of
                              select="tan:pluck($lca-middle-children, count($lca-ancestry), true())"/>
                           <xsl:copy-of select="$div-end-and-preceding-siblings"/>
                        </xsl:otherwise>
                     </xsl:choose>
                     <!-\-<xsl:copy-of select="$div-start"/>
                     <xsl:copy-of
                        select="$div-start/following-sibling::* except ($div-end, $div-end/following-sibling::*)"/>
                     <xsl:copy-of
                        select="$div-end/preceding-sibling::* except ($div-start, $div-start/preceding-sibling::*)"/>
                     <xsl:copy-of select="$div-end"/>-\->
                  </xsl:variable>
                  <xsl:choose>
                     <xsl:when test="$keep-text = true()">
                        <xsl:copy-of select="$this-fragment-range"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of select="tan:shallow-copy($this-fragment-range)"/>
                     </xsl:otherwise>
                  </xsl:choose>

                  <!-\-<xsl:variable name="raw-divs"
                     select="$div-start/(descendant-or-self::*, following::*) except $div-end/following::*"/>
                  <xsl:apply-templates select="$raw-divs" mode="get-div-hierarchy-fragment">
                     <!-\\- We add the caveat to exclude div-end ancestors because when we use a reference like 1 1 - 1 3 5, we are
                        disinterested in grabbing 1 3, even if its last child is 1 3 5. -\\->
                     <xsl:with-param name="refs-to-keep"
                        select="$raw-divs/@ref[not(. = $div-end-ancestors/@ref)]" tunnel="yes"/>
                     <xsl:with-param name="keep-text" select="$keep-text" tunnel="yes"/>
                  </xsl:apply-templates>-\->
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:if test="$ref-start-help-requested = true()">
            <xsl:variable name="this-message"
               select="concat('for source ', $this-src, ' try: ', string-join($ref-start-near-matches/@ref, '; '))"/>
            <xsl:copy-of select="tan:help($this-message, $this-fragment)"/>
         </xsl:if>
         <xsl:if test="$ref-end-help-requested = true()">
            <xsl:variable name="this-message"
               select="concat('for source ', $this-src, ' try: ', string-join($ref-end-near-matches/@ref, '; '))"/>
            <xsl:copy-of select="tan:help($this-message, $this-fragment)"/>
         </xsl:if>
         <xsl:if test="not(exists($this-fragment)) and (exists($div-start) and exists($div-end))">
            <xsl:copy-of select="tan:error('ref04', concat($ref-start,' and ', $div-end/@ref, ' point to real divisions, but do not create a range'))"/>
         </xsl:if>
         <xsl:if test="$div-start[not(tan:div)] and count($div-start) gt 1">
            <xsl:copy-of select="tan:error('ref02', $ref-start)"/>
         </xsl:if>
         <xsl:if test="$div-end[not(tan:div)] and count($div-end) gt 1">
            <xsl:copy-of select="tan:error('ref02', $ref-end-norm)"/>
         </xsl:if>
         <xsl:choose>
            <xsl:when
               test="not(exists($div-start)) or (count($ref-atoms) gt 1 and not(exists($div-end)))">
               <!-\- ref doesn't match a div -\->
               <xsl:variable name="this-message" as="xs:string*">
                  <xsl:text>source</xsl:text>
                  <xsl:value-of select="$this-src"/>
                  <xsl:text>does not have</xsl:text>
                  <xsl:value-of
                     select="
                        if (not(exists($div-start))) then
                           $ref-start
                        else
                           ()"/>
                  <xsl:value-of
                     select="
                        if (not(exists($div-end))) then
                           $ref-end-norm
                        else
                           ()"
                  />
               </xsl:variable>
               <xsl:choose>
                  <xsl:when test="$missing-ref-returned-as-info-not-error = false()">
                     <xsl:copy-of select="tan:error('ref01', string-join($this-message, ' '))"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="tan:info(string-join($this-message, ' '), ())"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="$this-fragment"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>-->
   </xsl:function>
   
   <xsl:function name="tan:analyze-ref" as="element()">
      <!-- Input: any @ref's value -->
      <!-- Output: series of <ref>s, punctuated by <comma> or <dash>; each <ref> holds the likely best value; if that differs from the original, @orig holds the original value of the ref -->
      <xsl:param name="ref" as="xs:string"/>
      <xsl:variable name="pass1" as="element()">
         <analysis>
            <xsl:analyze-string select="$ref" regex="\s*[,-]\s*">
               <xsl:matching-substring>
                  <xsl:choose>
                     <xsl:when test="matches(.,',')">
                        <comma/>
                     </xsl:when>
                     <xsl:otherwise>
                        <dash/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <ref>
                     <xsl:variable name="these-ns" select="tokenize(., '[^\w\?]+')"/>
                     <xsl:attribute name="count" select="count($these-ns)"/>
                     <xsl:for-each select="$these-ns">
                        <n>
                           <xsl:value-of select="."/>
                        </n>
                     </xsl:for-each>
                  </ref>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </analysis>
      </xsl:variable>
      <xsl:variable name="pass2" as="element()">
         <xsl:apply-templates select="$pass1" mode="analyze-ref"/>
      </xsl:variable>
      <xsl:copy-of select="$pass2"/>
   </xsl:function>
   
   <xsl:template match="*" mode="analyze-ref">
      <xsl:copy>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:ref" mode="analyze-ref">
      <xsl:variable name="this-n-count" select="count(tan:n)"/>
      <xsl:variable name="preceding-models" select="preceding-sibling::tan:ref"/>
      <xsl:variable name="max-count" select="max($preceding-models/@count)"/>
      <xsl:variable name="this-model" select="($preceding-models[@count = $max-count])[last()]"/>
      <xsl:variable name="this-diff" select="$max-count - $this-n-count"/>
      <xsl:copy>
         <xsl:choose>
            <xsl:when test="$this-diff gt 0">
               <xsl:attribute name="orig" select="string-join(*, ' ')"/>
               <xsl:value-of select="string-join(($this-model/*[position() le $this-diff], *), ' ')"
               />
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="string-join(*, ' ')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="text()" mode="get-div-hierarchy-fragment">
      <xsl:param name="keep-text" as="xs:boolean?" tunnel="yes"/>
      <xsl:if test="$keep-text = true() and matches(., '\S')">
         <xsl:copy-of select="."/>
      </xsl:if>
   </xsl:template>
   <xsl:template match="tan:div" mode="get-div-hierarchy-fragment">
      <xsl:param name="refs-to-keep" as="xs:string*" tunnel="yes"/>
      <xsl:variable name="descendants-to-keep" select="descendant::tan:div[@ref = $refs-to-keep]"/>
      <xsl:variable name="descendants-to-exclude"
         select="descendant::tan:div[not(@ref = $refs-to-keep)]"/>
      <xsl:choose>
         <xsl:when
            test="
               @ref = $refs-to-keep and (every $i in descendant::tan:div/@ref
                  satisfies $i = $refs-to-keep)">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="get-div-hierarchy-fragment"/>
            </xsl:copy>
         </xsl:when>
         <xsl:when test="descendant::tan:div/@ref = $refs-to-keep">
            <xsl:apply-templates mode="get-div-hierarchy-fragment"/>
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <!-- STEP SRC-1ST-DA-TOKENIZED: tokenize prepped source documents, using token definitions in self-expanded-2 -->
   <xsl:function name="tan:get-src-1st-da-tokenized" as="document-node()*">
      <xsl:param name="class-2-doc-prepped-step-3" as="document-node()?"/>
      <xsl:param name="prepped-class-1-doc" as="document-node()*"/>
      <xsl:copy-of
         select="tan:get-src-1st-da-tokenized($class-2-doc-prepped-step-3, $prepped-class-1-doc, true(), false())"
      />
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-tokenized" as="document-node()*">
      <!-- Input: class-2 document prepped through stage 3; related source class 1 documents, prepped; boolean indicating whether @n should be added to new <tok>s; boolean indicating whether the entirety of the documents should be tokenized, or only those leaf difvs that are mentioned by the class 2 document -->
      <!-- Output: same class 1 documents tokenized, selectively or completely -->
      <xsl:param name="class-2-doc-prepped-step-3" as="document-node()?"/>
      <xsl:param name="prepped-class-1-doc" as="document-node()*"/>
      <xsl:param name="add-n-attr" as="xs:boolean"/>
      <xsl:param name="tokenize-selectively" as="xs:boolean"/>
      <xsl:variable name="token-definitions"
         select="$class-2-doc-prepped-step-3/*/tan:head/tan:declarations/tan:token-definition"/>
      <xsl:for-each select="$prepped-class-1-doc">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:variable name="ref-filter"
            select="$class-2-doc-prepped-step-3/*/tan:body//tan:tok[@src = $this-src]/@ref"/>
         <xsl:choose>
            <xsl:when test="$tokenize-selectively = true() and not(exists($ref-filter))">
               <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:document>
                  <xsl:apply-templates mode="tokenize-prepped-class-1">
                     <xsl:with-param name="token-definition"
                        select="$token-definitions[@src = $this-src]" tunnel="yes"/>
                     <xsl:with-param name="ref-filter" tunnel="yes" select="$ref-filter"/>
                     <xsl:with-param name="add-n-attr" select="$add-n-attr" tunnel="yes"/>
                  </xsl:apply-templates>
               </xsl:document>
            </xsl:otherwise></xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="tokenize-prepped-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[not((tan:div, tan:tok, tan:ver))] | tan:ver" mode="tokenize-prepped-class-1">
      <!-- tan:ver is part of the calculus, because of TAN-A-div merges, which require the introduction of <ver> at the leafmost parts of a document -->
      <xsl:param name="token-definition" as="element()?" tunnel="yes"/>
      <xsl:param name="add-n-attr" as="xs:boolean?" tunnel="yes"/>
      <xsl:param name="ref-filter" as="xs:string*" tunnel="yes"/>
      <xsl:param name="keep-copy-of-tei-elements" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="this-div"
         select="tan:copy-of-except(., ('error', 'help', 'warning', 'fatal', 'info'), (), ())"/>
      <xsl:variable name="this-text" select="tan:text-join($this-div, false())"/>
      <xsl:variable name="this-analyzed"
         select="tan:tokenize-leaf-div($this-text, $token-definition, $add-n-attr)"/>
      <xsl:choose>
         <xsl:when test="empty($ref-filter) or @ref = $ref-filter">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$this-analyzed/@max-toks"/>
               <!-- errors are retained -->
               <xsl:copy-of select="tan:*"/>
               <xsl:copy-of select="$this-analyzed/*"/>
               <xsl:if test="not($keep-copy-of-tei-elements = false())">
                  <xsl:copy-of select="tei:*"/>
               </xsl:if>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- Derivative functions -->
   <xsl:function name="tan:tokenize-div" as="element()*">
      <!-- This function allows one to quickly get select <divs> in tokenized form, but
      requires the <token-definition> -->
      <xsl:param name="divs" as="element()*"/>
      <xsl:param name="token-definitions" as="element()"/>
      <xsl:apply-templates select="$divs" mode="tokenize-prepped-class-1">
         <xsl:with-param name="token-definitions" select="$token-definitions" tunnel="yes"/>
         <xsl:with-param name="add-n-attr" select="false()" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>

   <!-- STEP SELF-EXPANDED-4: revise self-expanded-3 to fully expand @val and @pos in <tok>; not applicable to TAN-A-div -->

   <!--<xsl:function name="tan:get-self-expanded-4">
      <!-\- zero parameter function of the next -\->
      <xsl:copy-of
         select="tan:get-self-expanded-4(tan:get-self-expanded-3(), tan:get-src-1st-da-tokenized())"
      />
   </xsl:function>-->
   <xsl:function name="tan:prep-class-2-doc-pass-4" as="document-node()?">
      <xsl:param name="class-2-doc-prepped-pass-3" as="document-node()?"/>
      <xsl:param name="sources-selectively-tokenized" as="document-node()*"/>
      <xsl:document>
         <xsl:apply-templates mode="prep-class-2-doc-pass-4" select="$class-2-doc-prepped-pass-3">
            <xsl:with-param name="src-1st-da-tokenized" select="$sources-selectively-tokenized"
               tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="tan:tok" mode="prep-class-2-doc-pass-4">
      <xsl:param name="src-1st-da-tokenized" as="document-node()*" tunnel="yes"/>
      <xsl:copy-of select="tan:expand-tok(., $src-1st-da-tokenized)"/>
   </xsl:template>

   <!-- functions for step -->
   <xsl:function name="tan:expand-tok" as="element()*">
      <!-- Input: any <tok> with atomic @src and @ref values; any number of tokenized source documents -->
      <!-- Output: one <tok> per token invoked, adding @n to specify where in the <div> the token is to be found; if @chars is present it is replaced with a space-delimited list of integers -->
      <xsl:param name="tok-elements" as="element()*"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:for-each select="$tok-elements">
         <xsl:variable name="this-tok" select="."/>
         <xsl:variable name="this-div"
            select="$src-1st-da-tokenized/tan:TAN-T[@src = $this-tok/@src]/tan:body//tan:div[@ref = $this-tok/@ref]"/>
         <xsl:variable name="those-toks" select="tan:get-toks($this-div, $this-tok)" as="element()*"/>
         <!--<test><xsl:for-each select="$this-div">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
            </xsl:copy>
         </xsl:for-each></test>-->
         <xsl:apply-templates select="$those-toks" mode="mark-tok-chars"/>

         <!--<xsl:variable name="those-chars"
            select="
               if (exists(@chars)) then
                  tan:get-chars($those-toks/text(), @chars)
               else
                  ()"
            as="element()?"/>-->
         <!--<test><xsl:copy-of select="$those-toks"/></test>-->
         <!--<xsl:for-each select="$those-toks">
            <xsl:variable name="that-n" select="@n"/>
            <xsl:variable name="that-seq" select="position()"/>
            <xsl:variable name="that-val" select="text()"/>

            <xsl:copy>
               <xsl:copy-of select="$this-tok/@*"/>
               <xsl:attribute name="group" select="concat(@group, '-', $that-seq)"/>
               <xsl:attribute name="n" select="$that-n"/>
               <xsl:if test="exists($this-tok/@chars)">
                  <xsl:variable name="those-chars"
                     select="tan:get-chars($that-val, $this-tok/@chars)"/>
                  <xsl:attribute name="chars" select="$those-chars/tan:match/@n"/>
               </xsl:if>
            </xsl:copy>

         </xsl:for-each>-->
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:get-toks" as="element()*">
      <!-- returns the <tok>s from a given <div>, including @n with integer position -->
      <!-- Input: (1) any <div> with <tok> and <non-tok> children (result of tan:tokenize-prepped-1st-da()) (2) any number of <tok>s that are deemed to relate to the <div> chosen (i.e., @src and @ref will be ignored, assumed to correspond to the input <div>) -->
      <!-- Output: the <tok> elements picked. -->
      <xsl:param name="tokenized-div" as="element()?"/>
      <xsl:param name="tok-elements" as="element()*"/>
      <xsl:for-each select="$tok-elements">
         <xsl:variable name="this-tok-element" select="."/>
         <!-- if no @val then use the regex escape character for anything -->
         <xsl:variable name="this-val" select="(tan:normalize-text(@val), '.+')[1]"/>
         <xsl:variable name="these-matches"
            select="$tokenized-div/tan:tok[tan:matches(., concat('^', $this-val, '$'))]"/>
         <xsl:variable name="match-count" select="count($these-matches)"/>
         <xsl:variable name="near-matches"
            select="$tokenized-div/tan:tok[tan:matches(., $this-val)]"/>
         <xsl:variable name="near-match-message">
            <xsl:variable name="pass1" as="xs:string*">
               <xsl:for-each-group select="$near-matches" group-by=".">
                  <xsl:variable name="this-count" select="count(current-group())"/>
                  <xsl:choose>
                     <xsl:when test="$this-count gt 1">
                        <xsl:value-of select="concat(., ' (', $this-count, 'x)')"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:value-of select="."/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each-group>
            </xsl:variable>
            <xsl:value-of select="concat('Close matches: ', string-join($pass1, ', '))"/>
         </xsl:variable>
         <xsl:variable name="max-toks" select="count($these-matches)"/>
         <xsl:variable name="this-pos-norm" select="tan:normalize-text(@pos)"/>
         <xsl:variable name="these-pos-itemized" as="xs:integer*"
            select="
               if (string-length($this-pos-norm) gt 0) then
                  tan:sequence-expand($this-pos-norm, $max-toks)
               else
                  1"
         />
         <xsl:variable name="this-help-requested" select="tan:help-requested(.)"/>
         <xsl:variable name="pos-help-requested" select="tan:help-requested(@pos)"/>
         <xsl:variable name="val-help-requested" select="tan:help-requested(@val)"/>
         <xsl:variable name="chars-help-requested" select="tan:help-requested(@chars)"/>
         <xsl:for-each select="$these-pos-itemized">
            <xsl:variable name="this-pos" select="."/>
            <!--<test><xsl:copy-of select="$this-tok-element/@*"/></test>-->
            <tok>
               <xsl:copy-of select="$this-tok-element/@*"/>
               <xsl:copy-of select="$these-matches[$this-pos]/@*"/>
               <xsl:attribute name="ref" select="$tokenized-div/@ref"/>
               <xsl:attribute name="orig-ref" select="$this-tok-element/@ref"/>
               <xsl:if test="not(exists($these-matches[$this-pos]/@n))">
                  <xsl:attribute name="n"
                     select="count($these-matches[$this-pos]/preceding-sibling::tan:tok) + 1"/>
               </xsl:if>
               <xsl:copy-of select="$this-tok-element/*"/>
               <xsl:if test="not($tokenized-div/tan:tok)">
                  <xsl:copy-of select="tan:error('tok02')"/>
               </xsl:if>
               <xsl:if test="$this-pos lt 1">
                  <xsl:copy-of select="tan:error('tok01')"/>
                  <xsl:if test="$this-pos = 0">
                     <xsl:copy-of select="tan:error('seq01')"/>
                  </xsl:if>
                  <xsl:if test="$this-pos = -1">
                     <xsl:choose>
                        <xsl:when test="exists($this-tok-element/@val)">
                           <xsl:copy-of select="tan:error('cl209', $near-match-message)"/>
                           <xsl:if test="exists($this-tok-element/@pos)">
                              <xsl:copy-of
                                 select="
                                    tan:error('seq02', concat($this-val, ' appears ', $match-count, ' time', if ($match-count gt 1) then
                                       's'
                                    else
                                       ()))"
                              />
                           </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:copy-of select="tan:error('seq02')"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:if>
                  <xsl:if test="$this-pos = -2">
                     <xsl:copy-of select="tan:error('seq03')"/>
                  </xsl:if>
               </xsl:if>
               <xsl:if test="$this-tok-element/@val = '.+'">
                  <xsl:copy-of select="tan:error('cl210')"/>
               </xsl:if>
               <xsl:if test="$this-help-requested = true()">
                  <xsl:if test="$pos-help-requested = true()">
                     <test></test>
                     <xsl:copy-of
                        select="tan:help(concat('Maximum matched tokens: ', count($these-matches)), ())"
                     />
                  </xsl:if>
                  <xsl:if test="$val-help-requested = true()">
                     <xsl:copy-of select="tan:help($near-match-message, ())"/>
                  </xsl:if>
                  <xsl:if test="$chars-help-requested = true()">
                     <xsl:variable name="this-message"
                        select="
                           concat('string length: ', string-join(for $i in $these-matches
                           return
                              concat(string(string-length($i)), ' (', $i, ')'), ', '))"/>
                     <xsl:copy-of select="tan:help($this-message, ())"/>
                  </xsl:if>
               </xsl:if>
               <xsl:copy-of select="$these-matches[$this-pos]/text()"/>
            </tok>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   <xsl:template mode="mark-tok-chars" match="*[not(@chars)]">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template mode="mark-tok-chars" match="tan:tok[@chars]">
      <xsl:variable name="regex" select="'\P{M}\p{M}*'"/>
      <xsl:variable name="string-analyzed" as="xs:string*">
         <xsl:analyze-string select="text()" regex="{$regex}">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="char-nos" select="tan:sequence-expand(@chars, count($string-analyzed))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="tan:sequence-error($char-nos)"/>
         <xsl:for-each select="$string-analyzed">
            <xsl:variable name="pos" select="position()"/>
            <xsl:choose>
               <xsl:when test="$pos = $char-nos">
                  <c n="{$pos}">
                     <xsl:value-of select="."/>
                  </c>
               </xsl:when>
               <xsl:otherwise>
                  <x>
                     <xsl:value-of select="."/>
                  </x>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   
   <!--<xsl:function name="tan:get-chars" as="element()*">
      <!-\- Input: a string and the value of @chars
         Output: <tok> with each character put into <match> or <non-match>, depending upon if it has been chosen 
      -\->
      <xsl:param name="string" as="xs:string*"/>
      <xsl:param name="chars" as="xs:string?"/>
      <xsl:variable name="regex" select="'\P{M}\p{M}*'"/>
      <xsl:for-each select="$string">
         <xsl:variable name="string-analyzed" as="xs:string*">
            <xsl:analyze-string select="." regex="{$regex}">
               <xsl:matching-substring>
                  <xsl:value-of select="."/>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <xsl:variable name="char-nos" select="tan:sequence-expand($chars, count($string-analyzed))"/>
         <tok>
            <xsl:if test="$char-nos = 0">
               <xsl:copy-of select="tan:error('seq01')"/>
            </xsl:if>
            <xsl:if test="$char-nos = -1">
               <xsl:copy-of select="tan:error('seq02')"/>
            </xsl:if>
            <xsl:if test="$char-nos = -2">
               <xsl:copy-of select="tan:error('seq03')"/>
            </xsl:if>
            <xsl:for-each select="$string-analyzed">
               <xsl:variable name="pos" select="position()"/>
               <xsl:choose>
                  <xsl:when test="$pos = $char-nos">
                     <c n="{$pos}">
                        <xsl:value-of select="."/>
                     </c>
                  </xsl:when>
                  <xsl:otherwise>
                     <x>
                        <xsl:value-of select="."/>
                     </x>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </tok>
      </xsl:for-each>
   </xsl:function>-->
   <xsl:template match="node()" mode="char-setup">
      <xsl:param name="ref-tok-filter" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="char-setup">
            <xsl:with-param name="ref-tok-filter" select="$ref-tok-filter"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div" mode="char-setup analysis-stamp">
      <xsl:param name="ref-tok-filter" as="element()*"/>
      <xsl:choose>
         <xsl:when
            test="
               some $i in $ref-tok-filter,
                  $j in descendant-or-self::tan:div
                  satisfies matches($j/@ref, $i/@ref)">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="ref-tok-filter" select="$ref-tok-filter"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="tan:tok" mode="char-setup">
      <xsl:param name="ref-tok-filter" as="element()*"/>
      <xsl:variable name="this-ref" select="parent::tan:div/@ref"/>
      <xsl:choose>
         <xsl:when
            test="(count(preceding-sibling::tan:tok) + 1) = $ref-tok-filter[@ref = $this-ref][@chars]/@n">
            <xsl:variable name="regex" select="'\P{M}\p{M}*'"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:analyze-string select="text()" regex="{$regex}">
                  <xsl:matching-substring>
                     <c>
                        <xsl:value-of select="."/>
                     </c>
                  </xsl:matching-substring>
               </xsl:analyze-string>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>


   <!-- This concludes functions and templates essential to transforming all class-2 files. 
      This is not the end of the story, however, since specific class-2 formats require further 
      transformation for other purposes. Below are other helpful transformations
      not central to validation.
   -->

   <xsl:function name="tan:recombine-docs" as="document-node()*">
      <!-- Input: any number of documents
      Output: recombined documents
      This function is useful for cases where you have both picked and culled
      from a source, and you wish to combine the two documents into a single one
      that strips away duplicates. NB, the results may not preserve the original 
      document order of an original document. It also treats non-leaf white-
      space text nodes as dispensible.
      -->
      <xsl:param name="docs-to-recombine" as="document-node()*"/>
      <xsl:param name="ref-sort-key-docs" as="document-node()*"/>
      <xsl:for-each-group select="$docs-to-recombine" group-by="tan:element-key(*)">
         <xsl:variable name="this-src" select="current-group()[1]/*/@src"/>
         <xsl:document>
            <xsl:call-template name="merge-nodes">
               <xsl:with-param name="nodes-to-merge" select="current-group()/node()"/>
               <xsl:with-param name="ref-sequence"
                  select="$ref-sort-key-docs/*[@src = $this-src]/tan:body//@ref"/>
            </xsl:call-template>
         </xsl:document>
      </xsl:for-each-group>
   </xsl:function>
   <xsl:template name="merge-nodes" as="item()*">
      <xsl:param name="nodes-to-merge" as="node()*"/>
      <xsl:param name="ref-sequence" as="xs:string*"/>
      <xsl:variable name="is-leaf-element" select="
            not($nodes-to-merge[self::*])"
         as="xs:boolean"/>
      <xsl:variable name="unique-child-nodes"
         select="tan:strip-duplicate-nodes($nodes-to-merge, ())"/>
      <xsl:copy-of
         select="
            $unique-child-nodes[self::processing-instruction() or self::comment() or self::text()[$is-leaf-element]]"/>
      <xsl:for-each-group select="$unique-child-nodes[self::*]" group-by="tan:element-key(.)">
         <xsl:sort
            select="
               if (@ref) then
                  index-of($ref-sequence, @ref)
               else
                  0"/>
         <xsl:variable name="first-item" select="current-group()[1]"/>
         <xsl:variable name="root-name" select="name($first-item)"/>
         <xsl:element name="{$root-name}">
            <xsl:copy-of select="$first-item/@*"/>
            <xsl:call-template name="merge-nodes">
               <xsl:with-param name="nodes-to-merge" select="current-group()/node()"/>
               <xsl:with-param name="ref-sequence" select="$ref-sequence"/>
            </xsl:call-template>
         </xsl:element>
      </xsl:for-each-group>
   </xsl:template>
   <xsl:function name="tan:element-key" as="xs:string?">
      <xsl:param name="node" as="node()"/>
      <xsl:variable name="name" select="name($node)"/>
      <xsl:variable name="attrs" as="xs:string*">
         <xsl:for-each select="$node/@*">
            <xsl:sort/>
            <xsl:copy-of select="name()"/>
            <xsl:copy-of select="."/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join(($name, $attrs), '%%%')"/>
   </xsl:function>
   <xsl:function name="tan:strip-duplicate-nodes" as="node()*">
      <xsl:param name="nodes-to-check" as="node()*"/>
      <xsl:param name="checked-nodes" as="node()*"/>
      <xsl:choose>
         <xsl:when test="count($nodes-to-check) = 0">
            <xsl:copy-of select="$checked-nodes"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:choose>
               <xsl:when
                  test="
                     some $i in $checked-nodes
                        satisfies deep-equal($i, $nodes-to-check[1])">
                  <xsl:copy-of
                     select="tan:strip-duplicate-nodes($nodes-to-check[position() gt 1], ($checked-nodes))"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of
                     select="tan:strip-duplicate-nodes($nodes-to-check[position() gt 1], ($checked-nodes, $nodes-to-check[1]))"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:shallow-equal" as="xs:boolean">
      <!-- Input: any two elements. Output: true if shallowly equal.
         Two elements are shallowly equal if (1) they both have the same name; (2) the name of every 
         attribute in one is the name of an attribute in the other; and (3) for every pair of attributes,
         every space-separated value in one is found in the other. Any descendants are ignored.
         Example: 
         Input:
            <div class="gum mug droop">Testing</div>
            <div class="droop mug gum droop">Different text</div>
         Output: true
      -->
      <xsl:param name="element-1" as="element()?"/>
      <xsl:param name="element-2" as="element()?"/>
      <xsl:variable name="have-same-name" select="name($element-1) = name($element-2)"
         as="xs:boolean"/>
      <xsl:variable name="attr-names-1"
         select="
            for $i in $element-1/@*
            return
               name($i)"/>
      <xsl:variable name="attr-names-2"
         select="
            for $i in $element-2/@*
            return
               name($i)"/>
      <xsl:variable name="have-same-attribute-names"
         select="
            (every $i in $attr-names-1
               satisfies ($i = $attr-names-2)) and
            (every $j in $attr-names-2
               satisfies ($j = $attr-names-1))"/>
      <xsl:variable name="have-same-attribute-values"
         select="
            every $i in $attr-names-1
               satisfies (
               (every $j in tokenize($element-1/@*[name() = $i], '\s+')
                  satisfies $j = tokenize($element-2/@*[name() = $i], '\s+'))
               and
               (every $j in tokenize($element-2/@*[name() = $i], '\s+')
                  satisfies $j = tokenize($element-1/@*[name() = $i], '\s+'))
               )"
         as="xs:boolean"/>
      <xsl:value-of
         select="$have-same-name and $have-same-attribute-names and $have-same-attribute-values"/>
   </xsl:function>

   <xsl:function name="tan:get-src-1st-da-with-lms" as="document-node()">
      <!-- For now, this function assumes that every TAN-LM document pertains to
      the tokenized class-1 doc -->
      <xsl:param name="tokenized-class-1-doc" as="document-node()"/>
      <xsl:param name="prepped-tan-lm-docs" as="document-node()*"/>
      <xsl:document>
         <xsl:apply-templates select="$tokenized-class-1-doc" mode="add-lm-to-tok">
            <xsl:with-param name="tan-lms" select="$prepped-tan-lm-docs"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="node()" mode="add-lm-to-tok">
      <xsl:param name="tan-lms" as="document-node()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="add-lm-to-tok">
            <xsl:with-param name="tan-lms" select="$tan-lms"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:tok" mode="add-lm-to-tok">
      <xsl:param name="tan-lms" as="document-node()*"/>
      <xsl:variable name="this-ref" select="../@ref"/>
      <xsl:variable name="this-n" select="@n"/>
      <xsl:copy>
         <xsl:copy-of select="node()"/>
         <xsl:copy-of
            select="
               $tan-lms/tan:TAN-LM/tan:body/tan:ana[tan:tok[@ref = $this-ref
               and @pos = $this-n]]/tan:lm"
         />
      </xsl:copy>
   </xsl:template>

   <!-- PART III.
      CONTEXTUAL FUNCTIONS
   -->
   <!-- In this part, a context is a <see-also> with a <relationship which="context"/>. 
      Contexts are class 2 files or TAN-rdf files that provide supplementary TAN data. 
      For example, a TAN-T transcription may
      point to a contextual TAN-LM file for lexico-morphological data, or to 
      a TAN-A-div file that aligns it with others. Or a TAN-A-div file may directly supply
      context TAN-LM files for its sources. The following functions assume a class 2 file 
      as a kind of hub, from which the spokes of its sources (the TAN-T(EI) files) might
      lead to contextual information.
   -->

   <xsl:function name="tan:get-context-prepped" as="document-node()*">
      <!-- Input: a class 2 document, transformed to level $self2 or higher; one or more contextual class 2 documents
      whose should reference system should be reconciled to the first document; the intervening source documents, in both
      prepped and resolved forms.
      Output: the class 2 context documents, with values converted (where needed) to the main class 2 document
      
      This function is used primarily in the context of a TAN-A-div file, where one finds supplementary TAN-LM and TAN-A-tok
      data that provides contextual information about source documents. This function will convert those satellite class 2 files
      to the naming conventions adopted in the original class 2 files. Because the prepped sources are oftentimes the intermediary,
      they are like a spoke connecting the original document (the hub) to the contextual documents (the rim).
      -->
      <xsl:param name="class-2-self3" as="document-node()"/>
      <xsl:param name="class-2-context-self2" as="document-node()*"/>
      <xsl:param name="srcs-prepped" as="document-node()*"/>
      <xsl:param name="srcs-resolved" as="document-node()*"/>
      <xsl:variable name="hub" select="$class-2-self3"/>
      <xsl:variable name="hub-srcs" select="$hub/*/tan:head/tan:source"/>
      <xsl:variable name="hub-sdts" select="$hub/*/tan:head/tan:declarations/tan:suppress-div-types"/>
      <xsl:variable name="hub-tds" select="$hub/*/tan:head/tan:declarations/tan:token-definition"/>
      <xsl:variable name="hub-rdns" select="$hub/*/tan:head/tan:declarations/tan:rename-div-ns"/>
      <xsl:variable name="spokes" select="$srcs-prepped"/>
      <xsl:variable name="rim" as="document-node()*">
         <xsl:for-each select="$class-2-context-self2">
            <xsl:variable name="these-srcs" select="*/tan:head/tan:source"/>
            <xsl:variable name="src-key" as="element()*">
               <xsl:choose>
                  <xsl:when test="tan:TAN-LM">
                     <src-key old="1" new="{tan:TAN-LM/@src}"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:for-each select="$hub-srcs">
                        <xsl:variable name="this-hub-src" select="."/>
                        <src-key old="{$these-srcs[tan:IRI = $this-hub-src/tan:IRI]/@xml:id}"
                           new="{@xml:id}"/>
                     </xsl:for-each>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:document>
               <xsl:apply-templates mode="prep-rim-pass-1">
                  <xsl:with-param name="src-key" select="$src-key"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$rim">
         <xsl:variable name="this-rims-spokes"
            select="
               for $i in */tan:head/tan:source
               return
                  $spokes[tan:TAN-T/@id = $i/tan:IRI]"/>
         <xsl:variable name="this-rims-src" select="$this-rims-spokes/tan:TAN-T/@src"/>
         <xsl:variable name="rim-is-multi-src"
            select="
               if (tan:TAN-LM) then
                  false()
               else
                  true()"/>
         <xsl:variable name="this-rims-sdts"
            select="
               */tan:head/tan:declarations/tan:suppress-div-types[if ($rim-is-multi-src = true()) then
                  tokenize((@src, '1')[1], '\s+') = $this-rims-src
               else
                  true()]"/>
         <xsl:variable name="this-rims-tds"
            select="
               */tan:head/tan:declarations/tan:token-definition[if ($rim-is-multi-src = true()) then
                  tokenize((@src, '1')[1], '\s+') = $this-rims-src
               else
                  true()]"/>
         <xsl:variable name="this-rims-rdns"
            select="
               */tan:head/tan:declarations/tan:rename-div-ns[if ($rim-is-multi-src = true()) then
                  tokenize((@src, '1')[1], '\s+') = $this-rims-src
               else
                  true()]"/>
         <xsl:document>
            <xsl:choose>
               <!-- First two tests weed out non-starters: differences between rim and hub over 
                  suppressed div types and token definitions -->
               <xsl:when
                  test="
                     not(every $i in $this-rims-sdts
                        satisfies
                        some $j in $hub-sdts[tokenize((@src, '1')[1], '\s+') = $this-rims-src]
                           satisfies deep-equal($i, $j)) or not(every $i in $hub-sdts[tokenize((@src, '1')[1], '\s+') = $this-rims-src]
                        satisfies
                        some $j in $this-rims-sdts
                           satisfies deep-equal($i, $j))">
                  <xsl:document>
                     <xsl:variable name="message" as="xs:string">
                        <xsl:value-of select="$this-rims-sdts"/>
                        <xsl:value-of
                           select="$hub-sdts[tokenize((@src, '1')[1], '\s+') = $this-rims-src]"/>
                     </xsl:variable>
                     <xsl:copy-of select="tan:error('adv02', $message)"/>
                     <!--<error src="{$this-rims-src}">Reconcile suppress-div-types before using this
                        function. <xsl:copy-of select="$this-rims-sdts"/>
                        <xsl:copy-of
                           select="$hub-sdts[tokenize((@src, '1')[1], '\s+') = $this-rims-src]"/>
                     </error>-->
                  </xsl:document>
               </xsl:when>
               <xsl:when
                  test="not($this-rims-tds/@regex = $hub-tds[tokenize((@src, '1')[1], '\s+')]/@regex)">
                  <xsl:document>
                     <xsl:copy-of select="$rim"/>
                     <xsl:variable name="message" as="xs:string">
                        <xsl:value-of select="$this-rims-src"/>
                        <xsl:value-of select="*/tan:head/tan:declarations/tan:token-definition"/>
                     </xsl:variable>
                     <xsl:copy-of select="tan:error('adv01', $message)"/>
                     <!--<error src="{$this-rims-src}">Reconcile token-definitions before using this
                        function. <these-srcs><xsl:value-of select="$this-rims-src"/></these-srcs>
                        <xsl:copy-of select="*/tan:head/tan:declarations/tan:token-definition"/>
                     </error>-->
                  </xsl:document>
               </xsl:when>
               <xsl:when
                  test="not(exists($this-rims-rdns) or exists($hub-rdns[tokenize((@src, '1')[1], '\s+') = $this-rims-src]))">
                  <!-- If neither rim nor hub rename any div types, then just proceed -->
                  <xsl:sequence select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <!-- If we've gotten here, then the rim or the hub rename div types, and synonyms need to be reconciled. 
                  The strategy is to get two version of the spoke: one that reflects the naming covention of the hub, 
                  the other for the rim. One then traverses from the rim through the two spokes to the hub, or vice
                  versa: rim ⇄ spoke-prepped-for-rim ⇄ spoke-prepped-for-hub ⇄ hub
                  Of these four files, we are missing only the second.
                  -->
                  <xsl:variable name="spokes-prepped-for-rim"
                     select="tan:prep-resolved-class-1-doc(., $srcs-resolved[*/@src = $this-rims-src])"/>
                  <xsl:variable name="conversions" as="element()*">
                     <xsl:for-each select="$this-rims-src">
                        <xsl:variable name="this-src" select="."/>
                        <xsl:for-each
                           select="$spokes-prepped-for-rim/tan:TAN-T[@src = $this-src]/tan:body//tan:div">
                           <xsl:variable name="rim-ref" select="@ref"/>
                           <xsl:variable name="rim-spoke-ref" select="(@orig-ref, @ref)[1]"/>
                           <xsl:variable name="hub-ref"
                              select="$srcs-prepped/*[@src = $this-src]/tan:body//tan:div[(@orig-ref, @ref)[1] = $rim-spoke-ref]/@ref"/>
                           <convert src="{$this-src}" old="{$rim-ref}" new="{$hub-ref}"/>
                        </xsl:for-each>
                     </xsl:for-each>
                  </xsl:variable>
                  <xsl:variable name="rim-self-3" as="document-node()*"
                     select="tan:prep-class-2-doc-pass-3(., $spokes-prepped-for-rim)"/>
                  <!-- reconciled output -->
                  <xsl:apply-templates select="$rim-self-3" mode="prep-rim-pass-2">
                     <xsl:with-param name="key" select="$conversions"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="prep-rim-pass-1">
      <xsl:param name="src-key" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="src-key" select="$src-key"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:source" mode="prep-rim-pass-1">
      <xsl:param name="src-key" as="element()*"/>
      <!-- allow fallback of '1' in case the file is TAN-LM (i.e., no src ids) -->
      <xsl:variable name="this-id" select="(@xml:id, '1')[1]"/>
      <xsl:variable name="new-id" select="$src-key[@old = $this-id]/@new"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="xml:id" select="($new-id, @xml:id)[1]"/>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template
      match="tan:anchor-div-ref | tan:div-ref | tan:div-type-ref | tan:equate-works | tan:rename-div-ns | tan:suppress-div-types | tan:tok | tan:token-definition"
      mode="prep-rim-pass-1">
      <xsl:param name="src-key" as="element()*"/>
      <xsl:variable name="these-srcs" select="tokenize((@src, '1')[1], '\s+')" as="xs:string*"/>
      <xsl:variable name="new-srcs"
         select="
            for $i in $these-srcs
            return
               if ($src-key[@old = $i]) then
                  ($src-key[@old = $i]/@new)
               else
                  $i"
         as="xs:string*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="src" select="$new-srcs"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="node()" mode="prep-rim-pass-2">
      <xsl:param name="key" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="key" select="$key"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:anchor-div-ref | tan:div-ref | tan:tok" mode="prep-rim-pass-2">
      <xsl:param name="key" as="element()*"/>
      <xsl:variable name="this-src" select="@src"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="new-ref" as="xs:string"
         select="$key[@src = $this-src][@old = $this-ref]/@new"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="ref" select="$new-ref"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="key" select="$key"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>

   <!-- Functions to be applied to TAN-LM files, as context or not -->
   <xsl:function name="tan:unconsolidate-tan-lm" as="document-node()*">
      <!-- Reformats TAN-LM files, such that each <ana> has one and only
      one <tok> + <l> + <m> combination -->
      <xsl:param name="tan-lm-docs" as="document-node()*"/>
      <xsl:param name="srcs-tokenized" as="document-node()*"/>
      <xsl:choose>
         <xsl:when test="not(count($tan-lm-docs) = count($srcs-tokenized))">
            <xsl:message>There must be an equal number of TAN-LM documents and their tokenized
               sources</xsl:message>
         </xsl:when>
         <xsl:otherwise>
            <xsl:for-each select="$tan-lm-docs">
               <xsl:variable name="pos" select="position()"/>
               <xsl:document>
                  <xsl:apply-templates mode="unconsolidate-anas">
                     <xsl:with-param name="src-tokenized" select="$srcs-tokenized[$pos]"/>
                  </xsl:apply-templates>
               </xsl:document>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:template match="node()" mode="unconsolidate-anas">
      <xsl:param name="src-tokenized" as="document-node()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="unconsolidate-anas">
            <xsl:with-param name="src-tokenized" select="$src-tokenized"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:head" mode="unconsolidate-anas">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tan:ana" mode="unconsolidate-anas">
      <xsl:param name="src-tokenized" as="document-node()"/>
      <xsl:variable name="this-ana" select="."/>
      <xsl:for-each select="tan:tok[not(@cont)]">
         <xsl:variable name="this-tok" select="."/>
         <!-- this has not yet been written to anticipate @ref with multiple values -->
         <xsl:variable name="this-ref-norm" select="tan:normalize-refs(., ())"/>
         <xsl:variable name="this-val-norm" select="(@val, '.')[1]"/>
         <xsl:variable name="that-div"
            select="$src-tokenized/tan:TAN-T/tan:body//tan:div[@ref = $this-ref-norm]"/>
         <xsl:variable name="tok-ceiling" select="count($that-div/tan:tok)"/>
         <xsl:variable name="this-pos-norm"
            select="
               if (@pos) then
                  tan:sequence-expand(@pos, $tok-ceiling)
               else
                  1"/>
         <xsl:for-each select="$this-pos-norm">
            <xsl:variable name="this-pos" select="."/>
            <xsl:for-each select="$this-ana/tan:lm">
               <xsl:variable name="this-lm" select="."/>
               <xsl:for-each select="tan:l">
                  <xsl:variable name="this-l" select="."/>
                  <xsl:for-each select="$this-lm/tan:m">
                     <xsl:variable name="this-m" select="."/>
                     <ana>
                        <xsl:copy-of select="$this-ana/(comment(), tan:comment)"/>
                        <tok>
                           <xsl:copy-of select="$this-tok/@*"/>
                           <xsl:if test="not($this-pos = 1)">
                              <xsl:attribute name="pos" select="$this-pos"/>
                           </xsl:if>
                           <xsl:copy-of select="$this-tok/comment()"/>
                        </tok>
                        <lm>
                           <xsl:copy-of select="$this-lm/@*"/>
                           <xsl:copy-of select="$this-lm/(comment(), tan:comment)"/>
                           <l>
                              <xsl:copy-of select="$this-l/@*"/>
                              <xsl:copy-of select="$this-l/node()"/>
                           </l>
                           <m>
                              <xsl:copy-of select="$this-m/@*"/>
                              <xsl:copy-of select="$this-m/node()"/>
                           </m>
                        </lm>
                     </ana>
                  </xsl:for-each>
               </xsl:for-each>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:template>

   <!-- PART IV.
      FUNCTIONS USEFUL FOR VALIDATION, CALCULATION
   -->

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

   <xsl:function name="tan:ordinal" xml:id="f-ordinal" as="xs:string*">
      <!-- Input: one or more numerals
        Output: one or more strings with the English form of the ordinal form of the input number
        E.g., (1, 4, 17)  ->  ('first','fourth','17th'). 
        -->
      <xsl:param name="in" as="xs:integer*"/>
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
                  if ($i lt 1) then
                     'none'
                  else
                     concat(xs:string($i), $ordinal-suffixes[($i mod 10) + 1])"
      />
   </xsl:function>

   <xsl:function name="tan:max-integer" xml:id="f-max-integer" as="xs:integer?">
      <!-- input: string of TAN @pos or @chars selectors 
        output: largest integer, ignoring value of 'last'
        E.g., "5 - 15, last-20" -> 15 
        Useful for validation routines that want merely to check if a range is out of limits
      -->
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

</xsl:stylesheet>
