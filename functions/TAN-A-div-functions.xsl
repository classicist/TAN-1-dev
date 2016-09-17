<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd tan fn tei"
   version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Revised</xd:b>Aug 28, 2015</xd:p>
         <xd:p>Core functions for TAN-A-div files. Written principally for Schematron validation,
            but suitable for general use in other contexts</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="TAN-class-2-functions.xsl"/>

   <!-- PART I. GLOBAL VARIABLES AND PARAMETERS -->

   <xsl:variable name="self-and-sources-prepped" select="tan:prep-resolved-class-2-doc($self-core-errors-marked)"/>
   <xsl:variable name="self-prepped" select="$self-and-sources-prepped[1]"/>
   <xsl:variable name="sources-prepped" select="$self-and-sources-prepped[position() gt 1]"/>
   
   <!-- PART II. PROCESSING SELF -->

   <xsl:function name="tan:get-info" as="document-node()*">
      <!-- Input: a TAN-A-div file prepped and its sources, also prepped
         Output: the same files, with information marked of relevance to the validation process.
      -->
      <xsl:param name="TAN-A-div-prepped" as="document-node()?"/>
      <xsl:param name="TAN-A-div-sources-prepped" as="document-node()*"/>
      <xsl:variable name="this-skeleton" select="tan:get-src-skeleton($TAN-A-div-sources-prepped)"/>
      <xsl:document>
         <xsl:apply-templates select="$TAN-A-div-prepped" mode="get-info">
            <xsl:with-param name="source-skeleton" select="$this-skeleton" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:document>
      <xsl:sequence select="$TAN-A-div-sources-prepped"/>
   </xsl:function>
   
   <xsl:template match="node()" mode="get-info">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="get-info"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="/*" mode="get-info">
      <xsl:param name="source-skeleton" tunnel="yes" as="document-node()?"/>
      <xsl:variable name="these-realigns" select="tan:body/tan:realign"/>
      <xsl:variable name="defective-divs"
         select="
            $source-skeleton//tan:div[@src][not(
            some $i in $these-realigns/*
               satisfies
               ($i/@src = tokenize(@src, '\s+') and $i//@ref = @ref))]"
      />
      <xsl:variable name="defective-div-count" select="count($defective-divs)"/>
      <xsl:variable name="defective-divs-message" as="xs:string*">
         <xsl:value-of select="$defective-div-count"/>
         <xsl:text> defective div</xsl:text>
         <xsl:if test="$defective-div-count != 1">
            <xsl:text>s</xsl:text>
         </xsl:if>
         <xsl:if test="$defective-div-count gt 0">
            <xsl:text> (</xsl:text>
            <xsl:value-of
               select="
                  for $i in $defective-divs
                  return
                     concat(($i/@ref),
                     ' [', $i/@src, ']')"
            />
            <xsl:text>)</xsl:text>
         </xsl:if>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="tan:info(string-join($defective-divs-message, ''), ())"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:info" mode="get-info">
      <help>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="node()"/>
      </help>
   </xsl:template>
   

   <!-- PART III. PROCESSING SOURCE DOCUMENTS -->
   <!-- 
      TAN-A-div          TAN-class-1           Comments   
      ===========        ===========           ===============================
                         src-1st-da-segmented  In each <div> group <tok>s into <segs> based on TAN-A-div <split-leaf-div-at>s
                         src-1st-da-realigned  Using <realign>s, add @ref-eq to each <seg> with the proper value.
                         src-1st-da-statted    To each <body> and <div> adds @tok-qty, @tok-avg, @tok-std for the number, average, and standard deviation of tokens; useful for analysis
   -->

   <!-- STEP SRC-1ST-DA-SEGMENTED: segment tokenized source documents -->
   <!--<xsl:function name="tan:get-src-1st-da-segmented" as="document-node()*">
      <!-\- zero-parameter version of the next function -\->
      <xsl:variable name="self-expanded-3" select="tan:get-self-expanded-3()" as="document-node()?"/>
      <xsl:variable name="src-1st-da-tokenized" select="tan:get-src-1st-da-tokenized()"
         as="document-node()*"/>
      <xsl:copy-of select="tan:get-src-1st-da-segmented($self-expanded-3, $src-1st-da-tokenized)"/>
   </xsl:function>-->
   <xsl:function name="tan:get-src-1st-da-segmented" as="document-node()*">
      <xsl:param name="self-expanded-3" as="document-node()?"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:variable name="all-leaf-div-splits"
         select="$self-expanded-3/tan:TAN-A-div/tan:body/tan:split"/>
      <xsl:for-each select="$src-1st-da-tokenized">
         <xsl:variable name="this-src" select="/*/@src"/>
         <xsl:copy>
            <xsl:apply-templates mode="segment-tokd-prepped-class-1">
               <xsl:with-param name="all-leaf-div-splits" tunnel="yes"
                  select="$all-leaf-div-splits[@src = $this-src]"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="segment-tokd-prepped-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[not((tan:tok, tan:div))]" mode="segment-tokd-prepped-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
            <seg n="1">
            <xsl:copy-of select="text()"/>
            </seg>
         <xsl:sequence select="tei:*"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[tan:tok]" mode="segment-tokd-prepped-class-1">
      <xsl:param name="all-leaf-div-splits" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-div" select="."/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="this-max-toks" select="xs:integer(@max-toks)"/>
      <xsl:variable name="splits-at" select="$all-leaf-div-splits[@ref = $this-ref]"/>
      <xsl:variable name="this-div-seg-starts"
         select="
            (1,
            for $i in $splits-at/tan:tok/@n
            return
               xs:integer($i))"
         as="xs:integer+"/>
      <xsl:variable name="this-div-seg-ends"
         select="
            ((for $i in $splits-at/tan:tok/@n
            return
               xs:integer($i) - 1),
            $this-max-toks)"
         as="xs:integer+"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="splits-at" select="$splits-at/tan:tok/@n"/>
         <xsl:for-each select="(1 to (count($splits-at/tan:tok) + 1))">
            <xsl:variable name="pos" select="."/>
            <xsl:variable name="start" select="$this-div-seg-starts[$pos]"/>
            <xsl:variable name="end" select="$this-div-seg-ends[$pos]"/>
            <seg n="{$pos}">
               <xsl:copy-of
                  select="
                     $this-div/tan:tok[position() = ($start to $end)]/(self::*, following-sibling::*[1][self::tan:non-tok])"
               />
            </seg>
         </xsl:for-each>
         <xsl:sequence select="tei:*"/>
      </xsl:copy>
   </xsl:template>

   <!-- STEP SELF-EXPANDED-5: distribute, group @seg, expand <align>, <realign> -->
   <!-- The following function and template commented out 2016-07-17, since it seems to have been taken care of in the self3 revision. -->
   <!--<xsl:function name="tan:get-self-expanded-5" as="document-node()?">
      <!-\- zero-parameter version of the next function -\->
      <xsl:variable name="self-expanded-4" select="tan:get-self-expanded-4()" as="document-node()?"/>
      <xsl:copy-of select="tan:get-self-expanded-5($self-expanded-4)"/>
   </xsl:function>-->
   <!--<xsl:function name="tan:get-self-expanded-5" as="document-node()?">
      <xsl:param name="self-expanded-4" as="document-node()?"/>
      <xsl:document>
         <xsl:apply-templates mode="self-expanded-5" select="$self-expanded-4"/>
      </xsl:document>
   </xsl:function>-->
   <!--<xsl:template match="node()" mode="self-expanded-5">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>-->
   <!--<xsl:template match="tan:realign | tan:align" mode="self-expanded-5">
      <xsl:variable name="this-realign-or-align" select="."/>
      <xsl:variable name="to-be-distributed" select="@distribute = true()"/>
      <xsl:variable name="splits-declared"
         select="preceding-sibling::tan:split-leaf-divs-at/tan:tok"/>
      <xsl:variable name="div-refs-expanded" as="element()">
         <group>
            <xsl:for-each select="*">
               <xsl:variable name="this-div-ref" select="."/>
               <xsl:variable name="this-src" select="@src"/>
               <xsl:variable name="this-ref" select="@ref"/>
               <xsl:variable name="this-seg" select="@seg"/>
               <xsl:variable name="seg-count"
                  select="
                     count($splits-declared[@src = $this-src and
                     @ref = $this-ref]) + 1"/>
               <xsl:variable name="seg-iterations"
                  select="
                     if (exists($this-seg)) then
                        tan:sequence-expand($this-seg, $seg-count)
                     else
                        1"/>
               <xsl:for-each select="$seg-iterations">
                  <xsl:element name="{name($this-div-ref)}">
                     <xsl:copy-of select="$this-div-ref/@*"/>
                     <xsl:if test="$seg-count gt 0 or $this-div-ref/@seg">
                        <xsl:attribute name="seg"
                           select="
                              if (. gt $seg-count) then
                                 concat('max', string($seg-count), '+', string(. - $seg-count))
                              else
                                 ."
                        />
                     </xsl:if>
                     <xsl:if test="position() lt count($seg-iterations)">
                        <!-\- This ensures that itemized segments are treated as a single group -\->
                        <xsl:attribute name="cont" select="true()"/>
                     </xsl:if>
                  </xsl:element>
               </xsl:for-each>
            </xsl:for-each>
            <!-\-<xsl:copy-of select="tan:expand-seg(*, $src-1st-da-segmented)"/>-\->
         </group>
      </xsl:variable>
      <xsl:variable name="div-refs-grouped" as="element()*">
         <!-\-<xsl:for-each-group select="$div-refs-expanded/*"
            group-by="count(preceding-sibling::*[not(@cont)])">
            <group>
               <xsl:copy-of select="current-group()"/>
            </group>
         </xsl:for-each-group>-\->
         <xsl:for-each-group select="$div-refs-expanded/*" group-by="@group">
            <group>
               <xsl:copy-of select="current-group()"/>
            </group>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="$to-be-distributed = true() and self::tan:realign">
            <xsl:variable name="div-refs-redistributed"
               select="tan:distribute-elements-of-elements($div-refs-grouped)"/>
            <xsl:for-each select="$div-refs-redistributed">
               <realign>
                  <xsl:copy-of select="$this-realign-or-align/@*"/>
                  <xsl:copy-of select="@error"/>
                  <!-\-<xsl:for-each-group select="tan:div-ref, tan:anchor-div-ref" group-by="@group">
                     <group>
                        <xsl:copy-of select="current-group()"/>
                     </group>
                  </xsl:for-each-group>-\->
                  <xsl:copy-of select="."/>
               </realign>
            </xsl:for-each>
         </xsl:when>
         <xsl:when test="$to-be-distributed = true() and self::tan:align">
            <!-\- aligns need predistribution since, unlike realign, multiple sources that share a single
            work should be treated as multiple sets, not a single large one. -\->
            <xsl:variable name="pre-distribution" as="element()*">
               <xsl:for-each select="$div-refs-grouped">
                  <xsl:for-each-group select="*" group-by="@src">
                     <group>
                        <xsl:copy-of select="current-group()"/>
                     </group>
                  </xsl:for-each-group>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="div-refs-redistributed"
               select="tan:distribute-elements-of-elements($pre-distribution)"/>
            <xsl:for-each select="$div-refs-redistributed">
               <align>
                  <xsl:copy-of select="$this-realign-or-align/@*"/>
                  <xsl:copy-of select="@error"/>
                  <!-\-<xsl:for-each-group select="tan:div-ref" group-by="@group">
                     <group>
                        <xsl:copy-of select="current-group()"/>
                     </group>
                  </xsl:for-each-group>-\->
                  <xsl:copy-of select="."/>
               </align>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$div-refs-grouped"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>-->

   <!-- functions used in step -->
   <!-- commented out 2016-07-17 since I'm not sure how it's being used -->
   <!--<xsl:function name="tan:expand-seg" as="element()*">
      <xsl:param name="elements-with-seg" as="element()*"/>
      <xsl:param name="src-1st-da-segmented" as="document-node()*"/>
      <xsl:for-each select="$elements-with-seg">
         <xsl:variable name="this-div-ref" select="."/>
         <xsl:variable name="div-picked"
            select="$src-1st-da-segmented[*/@src = $this-div-ref/@src]/tan:TAN-T/tan:body//tan:div[@ref = $this-div-ref/@ref]"/>
         <xsl:variable name="seg-count" select="count($div-picked/tan:seg)"/>
         <xsl:variable name="seg-itemized" select="tan:sequence-expand(@seg, $seg-count)"/>
         <xsl:for-each
            select="
               if (exists($seg-itemized)) then
                  $seg-itemized
               else
                  1">
            <xsl:element name="{name($this-div-ref)}">
               <xsl:copy-of select="$this-div-ref/@*"/>
               <xsl:if test="$seg-count gt 0 or $this-div-ref/@seg">
                  <xsl:attribute name="seg"
                     select="
                        if (. gt $seg-count) then
                           concat('max', string($seg-count), '+', string(. - $seg-count))
                        else
                           ."
                  />
               </xsl:if>
               <xsl:if test="position() lt count($seg-itemized)">
                  <!-\- This ensures that itemized segments are treated as a single group -\->
                  <xsl:attribute name="cont" select="true()"/>
               </xsl:if>
            </xsl:element>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>-->

   <!-- Commented out 2016-07-17, since it seems to be rendered obsolete by the $self3 revisions -->
   <!--<xsl:function name="tan:distribute-elements-of-elements" as="element()*">
      <!-\- Input: a sequence of elements with child elements to be distributed and regrouped. 
         Output: a sequence of elements where the nth item of each top-level input element is grouped 
         together. Items that cannot be distributed will be lumped together in a final group with the 
         attribute @error='true'.
         E.g., <group><a>one</a><a>two</a></group>, <group><b>three</b></group>
                        - > 
         <group><a>one</a><b>three</b></group>, <group error="true"><a>two</a></group>
         Useful for <realign> and <align>, both of which take @distribute.
      -\->
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
   </xsl:function>-->

   <!-- STEP SRC-1ST-DA-REALIGNED: realign segmented source documents -->
   <!--<xsl:function name="tan:get-src-1st-da-realigned" as="document-node()*">
      <!-\- zero-parameter version of the next function -\->
      <xsl:variable name="self-expanded-3" select="tan:get-self-expanded-3()" as="document-node()?"/>
      <xsl:variable name="src-1st-da-segmented" select="tan:get-src-1st-da-segmented()"
         as="document-node()*"/>
      <xsl:copy-of select="tan:get-src-1st-da-realigned($self-expanded-3, $src-1st-da-segmented)"/>
   </xsl:function>-->
   <xsl:function name="tan:get-src-1st-da-realigned" as="document-node()*">
      <xsl:param name="self-expanded-3" as="document-node()?"/>
      <xsl:param name="src-1st-da-prepped-or-segmented" as="document-node()*"/>
      <xsl:for-each select="$src-1st-da-prepped-or-segmented">
         <xsl:copy>
            <xsl:apply-templates mode="realign-segmented-class-1">
               <xsl:with-param name="self-expanded-3" select="$self-expanded-3" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="realign-segmented-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div" mode="realign-segmented-class-1">
      <xsl:param name="self-expanded-3" as="document-node()?" tunnel="yes"/>
      <xsl:variable name="this-src" select="root(.)/*/@src"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <!--<xsl:variable name="explicit-realign-groups"
         select="$self-expanded-5/tan:TAN-A-div/tan:body/tan:realign/tan:group[tan:div-ref[@src = $this-src][@ref = $this-ref]]"/>-->
      <xsl:variable name="explicit-realignments"
         select="$self-expanded-3/tan:TAN-A-div/tan:body/tan:realign[tan:div-ref[@src = $this-src][tan:div/@ref = $this-ref]]"
      />
      <xsl:variable name="explicit-segs"
         select="tan:sequence-expand($explicit-realignments/tan:div-ref[@src = $this-src]/@seg, count(tan:seg))"
      />
      <xsl:variable name="ancestral-explicit-realignments"
         select="$self-expanded-3/tan:TAN-A-div/tan:body/tan:realign[tan:div-ref[@src = $this-src][tan:div//tan:div/@ref = $this-ref]]"
      />
      <xsl:variable name="shortest-distance-to-explicitly-realigned-ancestor"
         select="
            min(for $i in
            $ancestral-explicit-realignments/tan:div-ref[@src = $this-src]//tan:div[@ref = $this-ref]
            return
               count($i/ancestor::tan:div))"
      />
      <xsl:variable name="nearest-ancestral-explicit-realignments" select="$ancestral-explicit-realignments/tan:div-ref[@src = $this-src]//tan:div[@ref = $this-ref][count(ancestor::tan:div) = $shortest-distance-to-explicitly-realigned-ancestor]"/>
      <xsl:variable name="new-ref-value" as="xs:string">
         <xsl:choose>
            <xsl:when test="exists($explicit-realignments)">
               <xsl:choose>
                  <xsl:when
                     test="
                        count($explicit-realignments) = 1 and count($explicit-realignments/tan:anchor-div-ref/tan:div) = 1
                        and (count($explicit-realignments/tan:div-ref[@src = $this-src]/tan:div) = 1)
                        and not(exists($explicit-realignments/(tan:div-ref[@src = $this-src], tan:anchor-div-ref)/@seg[matches(., '\D')]))">
                     <!-- If there is only one realignment, and it's in a one-to-one realignment, and the realignment does not involve multiple segments, then just adopt 
                        the value of the anchor div's @ref -->
                     <xsl:value-of select="$explicit-realignments/tan:anchor-div-ref/tan:div/@ref"/>
                  </xsl:when>
                  <xsl:when
                     test="
                        count($explicit-realignments) = 1 and not(exists($explicit-realignments/tan:anchor-div-ref))
                        and (every $i in $src-ids
                           satisfies count($explicit-realignments/tan:div-ref[@src = $i]/tan:div) le 1)">
                     <!-- There is only one realignment, and it's one div and zero anchor divs, then just reassign the value 
                        of @ref to the first div-ref, prepended by '#' (to make sure it's excluded from auto alignment) -->
                     <xsl:value-of
                        select="concat('#', $explicit-realignments/tan:div-ref[1]/tan:div/@ref)"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <!-- If there are multiple realignments, or any realignment where the realignment is one to many, 
                        many to many, or many to one, then change @ref to the values of all relevant realignment numbers,
                        delimited by space + hash + space, e.g., ref="realign#1 # realign#7" -->
                     <xsl:value-of
                        select="
                           string-join(for $i in $explicit-realignments
                           return
                              concat('realign#', string(count($i/preceding-sibling::tan:realign) + 1)), ' # ')"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <xsl:choose>
                  <xsl:when test="exists($ancestral-explicit-realignments)">
                     <!-- In this case, there's not an explicit realignment of the div in question, but one of its
                     ancestors has been realigned. In those cases, find the one that is the nearest ancestor. If there
                     is only one, and it alone is pegged to only one anchor, then let @ref take the value of 
                     its current value, with the opening part of the reference string replaced by the new one. For example,
                     if the file has realigned 1 4 to 1 3 3, and the div in question is 1 4 b, then the result should be
                     1 3 3 b. If there are multiple ancestral explicit realignments, or any of them those realignments involve
                     realigning one div to many, many to many, or many to one, then just copy the number of the realignment,
                     as above. It's up to subsequent users to determine how to interpret that realignment. -->
                     <xsl:choose>
                        <xsl:when
                           test="
                              count($nearest-ancestral-explicit-realignments) = 1 and count($nearest-ancestral-explicit-realignments/tan:anchor-div-ref/tan:div) = 1
                              and count($nearest-ancestral-explicit-realignments/tan:div-ref[@src = $this-src]/tan:div)">
                           <xsl:value-of
                              select="replace(@ref, concat('^', $nearest-ancestral-explicit-realignments/tan:div-ref/tan:div/@ref), $nearest-ancestral-explicit-realignments/tan:anchor-div-ref/tan:div/@ref)"
                           />
                        </xsl:when>
                        <xsl:when
                           test="
                              count($nearest-ancestral-explicit-realignments) = 1 and not(exists($nearest-ancestral-explicit-realignments/tan:anchor-div-ref))
                              and (every $i in $src-ids
                                 satisfies count($nearest-ancestral-explicit-realignments/tan:div-ref[@src = $i]/tan:div) le 1)">
                           <!-- There is only one ancestral realignment, and it's one div and zero anchor divs, then just reassign the value 
                        of @ref to the first div-ref, prepended by '#' (to make sure it's excluded from auto alignment) -->
                           <xsl:value-of
                              select="concat('#', $nearest-ancestral-explicit-realignments/tan:div-ref[1]/tan:div/@ref)"
                           />
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:value-of
                              select="
                                 string-join(for $i in $nearest-ancestral-explicit-realignments
                                 return
                                    concat('realign#', string(count($i/preceding-sibling::tan:realign) + 1)), ' # ')"
                           />
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                     <!-- In this case, there's no explicit realignment, and there's no ancestor that is explicitly realigned,
                     so it's ok to just copy the @ref -->
                     <xsl:value-of select="@ref"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!--<xsl:variable name="explicit-realign-anchor"
         select="($explicit-realignments/../../tan:anchor-div-ref[1])[1]"/>-->
      <!--<xsl:variable name="explicit-realign-unanchored"
         select="($explicit-realignments/../../tan:div-ref[1])[1]"/>-->
      <!--<xsl:variable name="explicit-realign-div-ref-eq"
         select="
            if (exists($explicit-realign-unanchored)) then
               concat('#' (:adding the # ensures it is removed from auto alignment :), $explicit-realign-unanchored/@ref)
            else
               ()"/>-->
      <!--<xsl:variable name="realigned-ref"
         select="
            ($explicit-realign-anchor/@ref, $explicit-realign-div-ref-eq,
            $this-ref)[1]"
      />-->
      <xsl:copy>
         <xsl:copy-of select="@* except @ref"/>
         <xsl:attribute name="ref" select="$new-ref-value"/>
         <!--<xsl:attribute name="test" select="exists(tan:seg)"></xsl:attribute>-->
         <!--<xsl:attribute name="test2" select="exists($explicit-realignments/tan:div-ref[@src = $this-src]/@seg)"></xsl:attribute>-->
         <xsl:if test="not(exists(tan:seg)) and exists($explicit-realignments)">
            <xsl:copy-of select="tan:error('seg01')"/>
         </xsl:if>
         <xsl:if test="$explicit-segs = 0">
            <xsl:copy-of select="tan:error('seq01')"/>
         </xsl:if>
         <xsl:if test="$explicit-segs = -1">
            <xsl:copy-of select="tan:error('seq02')"/>
         </xsl:if>
         <xsl:if test="$explicit-segs = -2">
            <xsl:copy-of select="tan:error('seq03')"/>
         </xsl:if>
         <xsl:if test="count($explicit-realignments) gt 1">
            <xsl:variable name="message">Realigned <xsl:value-of select="count($explicit-realignments)"/> times.</xsl:variable>
            <xsl:copy-of select="tan:error('rea01', $message)"/>
         </xsl:if>
         <!--<xsl:if
            test="
               $explicit-segs = -1 or (some $i in $explicit-segs
                  satisfies $i gt count(tan:seg))">
            <xsl:copy-of select="$errors//*[@xml:id = 'seg02']"/>
         </xsl:if>-->
         <!--<xsl:choose>
            <xsl:when test="count($explicit-realignments) = 1">
               <!-\-<xsl:attribute name="ref" select="$realigned-ref"/>-\->
               <xsl:attribute name="ref"
                  select="replace($this-ref, concat('^', $explicit-realignments/@ref), $realigned-ref)"
               />
               <xsl:attribute name="orig-ref" select="$this-ref"/>
            </xsl:when>
            <xsl:when test="count($explicit-realignments) gt 1">
               <xsl:attribute name="ref" select="$this-ref"/>
               <xsl:attribute name="error" select="'rea01'"/>
               <xsl:copy-of select="$errors//tan:error[@xml:id = 'rea01']"/>
            </xsl:when>
         </xsl:choose>-->
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="realigned-ref"
               select="
                  if ($new-ref-value = @ref) then
                     ()
                  else
                     $new-ref-value"
            />
            <xsl:with-param name="segs-to-realign"
               select="
                  if (exists($explicit-segs)) then
                     $explicit-segs
                  else
                     1"
            />
            <!--<xsl:with-param name="self-expanded-5" select="$self-expanded-5"/>-->
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:seg" mode="realign-segmented-class-1">
      <xsl:param name="self-expanded-5" as="document-node()?" tunnel="yes"/>
      <xsl:param name="realigned-ref" as="xs:string?"/>
      <xsl:param name="segs-to-realign" as="xs:integer+"/>
      <xsl:variable name="this-seg" select="."/>
      <xsl:variable name="this-seg-no"
         select="
            if (exists(@n)) then
               @n
            else
               count(preceding-sibling::tan:seg) + 1"
      />
      <xsl:variable name="inherited-ref" select="../@ref"/>
      
      
      <!--<xsl:variable name="this-src" select="root(.)/*/@src"/>
      <xsl:variable name="explicit-realign-groups"
         select="$self-expanded-5/tan:TAN-A-div/tan:body/tan:realign/tan:group[tan:div-ref[@src = $this-src][@ref = $inherited-ref][@seg = $this-seg/@n]]"/>
      <xsl:variable name="explicit-realign-anchor"
         select="($explicit-realign-groups/../tan:group/tan:anchor-div-ref[1])[1]"/>
      <xsl:variable name="explicit-realign-unanchored"
         select="($explicit-realign-groups/../tan:group/tan:div-ref[1])[1]"/>
      <xsl:variable name="explicit-realign-div-ref-eq"
         select="
            if (exists($explicit-realign-unanchored)) then
               concat('#' (:adding the # ensures it is removed from auto alignment :), $explicit-realign-unanchored/@ref)
            else
               ()"/>-->
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!--<xsl:attribute name="ref"
            select="
               ($explicit-realign-anchor/@ref, $explicit-realign-div-ref-eq,
               $inherited-ref)[1]"/>-->
         <!--<xsl:attribute name="seg"
            select="($explicit-realign-anchor/@seg, $explicit-realign-unanchored/@seg, @n)[1]"/>-->
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <!-- resultant functions -->
   <xsl:function name="tan:group-realigned-sources" as="element()*">
      <xsl:param name="src-1st-da-realigned" as="document-node()*"/>
      <xsl:sequence select="tan:group-realigned-sources($src-1st-da-realigned, ())"/>
   </xsl:function>
   <xsl:function name="tan:group-realigned-sources" as="element()*">
      <!-- Groups non-leaf <div>s and <seg>s according to their @ref and @seg values -->
      <xsl:param name="src-1st-da-realigned" as="document-node()*"/>
      <xsl:param name="return-groups-of-size" as="xs:integer*"/>
      <xsl:for-each-group
         select="$src-1st-da-realigned/tan:TAN-T/tan:body//(tan:div, tan:seg)"
         group-by="
            if (self::tan:div) then
               @ref
            else
               concat(@ref, '##', @seg)">
         <xsl:if
            test="count(current-group()) = $return-groups-of-size or empty($return-groups-of-size)">
            <group ref="{current-grouping-key()}"
               src="{for $i in current-group() return root($i)/*/@src}">
               <xsl:sequence select="current-group()"/>
            </group>
         </xsl:if>
      </xsl:for-each-group>
   </xsl:function>

   <!-- STEP SRC-1ST-DA-STATTED: retrieve count, average, and standard deviations of tokens -->
   <!-- This function takes any tokenized source files or higher. It assumes that every <tok> has an @n -->
   <!--<xsl:function name="tan:get-src-1st-da-statted" as="document-node()*">
      <!-\- zero-parameter version of the next function -\->
      <xsl:variable name="src-1st-da-tokenized" select="tan:get-src-1st-da-tokenized()"
         as="document-node()*"/>
      <xsl:copy-of select="tan:get-src-1st-da-statted($src-1st-da-tokenized)"/>
   </xsl:function>-->
   <xsl:function name="tan:get-src-1st-da-statted" as="document-node()*">
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:for-each select="$src-1st-da-tokenized">
         <xsl:copy>
            <xsl:apply-templates mode="count-tokenized-class-1"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="count-tokenized-class-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="count-tokenized-class-1"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:body | tan:div" mode="count-tokenized-class-1">
      <xsl:variable name="this-ref" select="(@ref, '.+')[1]"/>
      <!-- One must look for all divs, not just descendants, because there may have been realignment -->
      <xsl:variable name="leaf-divs"
         select="(self::*, root(current())/tan:TAN-T/tan:body//tan:div[matches(@ref, concat('^', $this-ref, ' '))])[tan:seg, tan:tok]"
      />
      <xsl:variable name="tok-qty-per-leaf-div"
         select="
            if (exists($leaf-divs)) then
               for $i in descendant-or-self::*[tan:tok, tan:non-tok]
               return
                  count($i/tan:tok)
            else
               0"
      />
      <xsl:variable name="tok-avg" select="avg($tok-qty-per-leaf-div)"/>
      <xsl:variable name="tok-deviations"
         select="
            for $i in $tok-qty-per-leaf-div
            return
               math:pow(($i - $tok-avg), 2)"/>
      <xsl:variable name="tok-variance" select="avg($tok-deviations)"/>
      <xsl:variable name="tok-standard-deviation" select="math:sqrt($tok-variance)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="leaf-div-qty" select="count($tok-qty-per-leaf-div)"/>
         <xsl:attribute name="tok-qty" select="sum($tok-qty-per-leaf-div)"/>
         <xsl:attribute name="tok-avg" select="$tok-avg"/>
         <xsl:attribute name="tok-max" select="max($tok-qty-per-leaf-div)"/>
         <xsl:attribute name="tok-min" select="min($tok-qty-per-leaf-div)"/>
         <xsl:attribute name="tok-dev" select="$tok-deviations"/>
         <xsl:attribute name="tok-var" select="$tok-variance"/>
         <xsl:attribute name="tok-std" select="$tok-standard-deviation"/>
         <xsl:apply-templates mode="count-tokenized-class-1"/>
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
