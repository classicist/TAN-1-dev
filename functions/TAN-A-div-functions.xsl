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

   <!-- None so far; items in this section should be kept to a minimum, to reduce time validating files -->

   <!-- PART II. PROCESSING SOURCE DOCUMENTS -->
   <!-- For previous steps 1 - 5 see TAN-class-2-functions.xsl, part II -->
   <!-- TAN-A-div files are exanded in tandem with their  underlying source files.
      Each transformation results in a document node, conducted in a sequence of steps:
      TAN-A-div          TAN-class-1           Comments   
      ===========        ===========           ===============================
                         src-1st-da-segmented  In each <div> group <tok>s into <segs> based on TAN-A-div <split-leaf-div-at>s
      self-expanded-5                          Expand @seg, expand <align>, <realign>
                         src-1st-da-realigned  Using <realign>s, add @ref-eq to each <seg> with the proper value.
   -->

   <!-- STEP SRC-1ST-DA-SEGMENTED: segment tokenized source documents -->
   <xsl:function name="tan:get-src-1st-da-segmented" as="document-node()*">
      <!-- zero-parameter version of the next function -->
      <xsl:variable name="self-expanded-4" select="tan:get-self-expanded-4()" as="document-node()?"/>
      <xsl:variable name="src-1st-da-tokenized" select="tan:get-src-1st-da-tokenized()"
         as="document-node()*"/>
      <xsl:copy-of select="tan:get-src-1st-da-segmented($self-expanded-4, $src-1st-da-tokenized)"/>
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-segmented" as="document-node()*">
      <xsl:param name="self-expanded-4" as="document-node()?"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:variable name="all-leaf-div-splits"
         select="$self-expanded-4/tan:TAN-A-div/tan:body/tan:split-leaf-div-at/tan:tok"/>
      <xsl:for-each select="$src-1st-da-tokenized">
         <xsl:variable name="this-src" select="/*/@src"/>
         <xsl:copy>
            <xsl:apply-templates mode="segment-tokd-prepped-class-1">
               <xsl:with-param name="all-leaf-div-splits"
                  select="$all-leaf-div-splits[@src = $this-src]"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="segment-tokd-prepped-class-1">
      <xsl:param name="all-leaf-div-splits" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="all-leaf-div-splits" select="$all-leaf-div-splits"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[tan:tok]" mode="segment-tokd-prepped-class-1">
      <xsl:param name="all-leaf-div-splits" as="element()*"/>
      <xsl:variable name="this-div" select="."/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="this-max-toks" select="xs:integer(@max-toks)"/>
      <xsl:variable name="splits-at" select="$all-leaf-div-splits[@ref = $this-ref]"/>
      <xsl:variable name="this-div-seg-starts"
         select="
            (1,
            for $i in $splits-at/@n
            return
               xs:integer($i))"
         as="xs:integer+"/>
      <xsl:variable name="this-div-seg-ends"
         select="
            ((for $i in $splits-at/@n
            return
               xs:integer($i) - 1),
            $this-max-toks)"
         as="xs:integer+"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="splits-at" select="$splits-at/@n"/>
         <xsl:for-each select="(1 to (count($splits-at) + 1))">
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

   <!-- STEP SELF-EXPANDED-5: distribute @seg, expand <align>, <realign> -->
   <xsl:function name="tan:get-self-expanded-5" as="document-node()?">
      <!-- zero-parameter version of the next function -->
      <xsl:variable name="self-expanded-4" select="tan:get-self-expanded-4()" as="document-node()?"/>
      <xsl:copy-of select="tan:get-self-expanded-5($self-expanded-4)"/>
   </xsl:function>
   <xsl:function name="tan:get-self-expanded-5" as="document-node()?">
      <xsl:param name="self-expanded-4" as="document-node()?"/>
      <xsl:document>
         <xsl:apply-templates mode="self-expanded-5" select="$self-expanded-4"/>
      </xsl:document>
   </xsl:function>
   <xsl:template match="node()" mode="self-expanded-5">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:realign | tan:align" mode="self-expanded-5">
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
               <xsl:variable name="seg-iterations" select="if (exists($this-seg)) then
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
                        <!-- This ensures that itemized segments are treated as a single group -->
                        <xsl:attribute name="cont" select="true()"/>
                     </xsl:if>
                  </xsl:element>
               </xsl:for-each>
            </xsl:for-each>
            <!--<xsl:copy-of select="tan:expand-seg(*, $src-1st-da-segmented)"/>-->
         </group>
      </xsl:variable>
      <xsl:variable name="div-refs-grouped" as="element()+">
         <xsl:for-each-group select="$div-refs-expanded/*"
            group-by="count(preceding-sibling::*[not(@cont)])">
            <group>
               <xsl:copy-of select="current-group()"/>
            </group>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$div-refs-grouped"/>
      </xsl:copy>
      <xsl:choose>
         <xsl:when test="$to-be-distributed = true() and self::tan:realign">
            <xsl:variable name="div-refs-redistributed"
               select="tan:distribute-elements-of-elements($div-refs-grouped)"/>
            <xsl:for-each select="$div-refs-redistributed">
               <realign>
                  <xsl:copy-of select="$this-realign-or-align/@*"/>
                  <xsl:copy-of select="@error"/>
                  <xsl:copy-of select="."/>
               </realign>
            </xsl:for-each>
         </xsl:when>
         <xsl:when test="$to-be-distributed = true() and self::tan:align">
            <!-- aligns need predistribution since, unlike realign, multiple sources that share a single
            work should be treated as multiple sets, not a single large one. -->
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
   </xsl:template>

   <!-- functions used in step -->
   <xsl:function name="tan:expand-seg" as="element()*">
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
                  <!-- This ensures that itemized segments are treated as a single group -->
                  <xsl:attribute name="cont" select="true()"/>
               </xsl:if>
            </xsl:element>
         </xsl:for-each>
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
         Useful for <realign> and <align>, both of which take @distribute.
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

   <!-- STEP SRC-1ST-DA-REALIGNED: realign segmented source documents -->
   <xsl:function name="tan:get-src-1st-da-realigned" as="document-node()*">
      <!-- zero-parameter version of the next function -->
      <xsl:variable name="self-expanded-5" select="tan:get-self-expanded-5()" as="document-node()?"/>
      <xsl:variable name="src-1st-da-segmented" select="tan:get-src-1st-da-segmented()"
         as="document-node()*"/>
      <xsl:copy-of select="tan:get-src-1st-da-realigned($self-expanded-5, $src-1st-da-segmented)"/>
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-realigned" as="document-node()*">
      <xsl:param name="self-expanded-5" as="document-node()?"/>
      <xsl:param name="src-1st-da-segmented" as="document-node()*"/>
      <xsl:for-each select="$src-1st-da-segmented">
         <xsl:copy>
            <xsl:apply-templates mode="realign-segmented-class-1">
               <xsl:with-param name="self-expanded-5" select="$self-expanded-5"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="realign-segmented-class-1">
      <xsl:param name="self-expanded-5" as="document-node()?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="self-expanded-5" select="$self-expanded-5"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[tan:div]" mode="realign-segmented-class-1">
      <xsl:param name="self-expanded-5" as="document-node()?"/>
      <xsl:variable name="this-src" select="root(.)/*/@src"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="explicit-realign-groups"
         select="$self-expanded-5/tan:TAN-A-div/tan:body/tan:realign/tan:group[tan:div-ref[@src = $this-src][@ref = $this-ref]]"/>
      <xsl:variable name="explicit-realign-anchor"
         select="($explicit-realign-groups/tan:anchor-div-ref[1])[1]"/>
      <xsl:variable name="explicit-realign-unanchored"
         select="($explicit-realign-groups/tan:div-ref[1])[1]"/>
      <xsl:variable name="explicit-realign-div-ref-eq"
         select="
            if (exists($explicit-realign-unanchored)) then
               concat('#' (:adding the # ensures it is removed from auto alignment :), $explicit-realign-unanchored/@ref)
            else
               ()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="realigned-ref"
            select="
               ($explicit-realign-anchor/@ref, $explicit-realign-div-ref-eq,
               $this-ref)[1]"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="self-expanded-5" select="$self-expanded-5"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:seg" mode="realign-segmented-class-1">
      <xsl:param name="self-expanded-5" as="document-node()?"/>
      <xsl:variable name="this-seg" select="."/>
      <xsl:variable name="this-src" select="root(.)/*/@src"/>
      <xsl:variable name="inherited-ref" select="../@ref"/>
      <xsl:variable name="explicit-realign-groups"
         select="$self-expanded-5/tan:TAN-A-div/tan:body/tan:realign/tan:group[tan:div-ref[@src = $this-src][@ref = $inherited-ref][@seg = $this-seg/@n]]"/>
      <xsl:variable name="explicit-realign-anchor"
         select="($explicit-realign-groups/tan:anchor-div-ref[1])[1]"/>
      <xsl:variable name="explicit-realign-unanchored"
         select="($explicit-realign-groups/tan:div-ref[1])[1]"/>
      <xsl:variable name="explicit-realign-div-ref-eq"
         select="
            if (exists($explicit-realign-unanchored)) then
               concat('#' (:adding the # ensures it is removed from auto alignment :), $explicit-realign-unanchored/@ref)
            else
               ()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="ref"
            select="
               ($explicit-realign-anchor/@ref, $explicit-realign-div-ref-eq,
               $inherited-ref)[1]"/>
         <xsl:attribute name="seg"
            select="($explicit-realign-anchor/@seg, $explicit-realign-unanchored/@seg, @n)[1]"/>
         <xsl:apply-templates mode="#current"> </xsl:apply-templates>
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
         select="$src-1st-da-realigned/tan:TAN-T/tan:body/(tan:div[not(tan:seg)], tan:div/tan:seg)"
         group-by="
            if (self::tan:div) then
               @realigned-ref
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

</xsl:stylesheet>
