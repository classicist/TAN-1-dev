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
      <xsl:variable name="src-1st-da-segmented" select="tan:get-src-1st-da-segmented()"
         as="document-node()*"/>
      <xsl:copy-of select="tan:get-self-expanded-5($self-expanded-4, $src-1st-da-segmented)"/>
   </xsl:function>
   <xsl:function name="tan:get-self-expanded-5" as="document-node()?">
      <xsl:param name="self-expanded-4" as="document-node()?"/>
      <xsl:param name="src-1st-da-segmented" as="document-node()*"/>
      <xsl:document>
         <xsl:apply-templates mode="self-expanded-5" select="$self-expanded-4">
            <xsl:with-param name="src-1st-da-segmented" select="$src-1st-da-segmented"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="node()" mode="self-expanded-5">
      <xsl:param name="src-1st-da-segmented" as="document-node()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="src-1st-da-segmented" select="$src-1st-da-segmented"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:realign | tan:align" mode="self-expanded-5">
      <xsl:param name="src-1st-da-segmented" as="document-node()*"/>
      <xsl:variable name="this-realign-or-align" select="."/>
      <xsl:variable name="to-be-distributed" select="@distribute = true()"/>
      <xsl:variable name="div-refs-expanded" as="element()">
         <group>
            <xsl:copy-of select="tan:expand-seg(*, $src-1st-da-segmented)"/>
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
            select="$src-1st-da-segmented[*/@src = $this-div-ref/@src]/tan:TAN-T/tan:body/tan:div[@ref = $this-div-ref/@ref]"/>
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
   <xsl:template match="tan:div[not(*)]" mode="realign-segmented-class-1">
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
               ()"
      />
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="realigned-ref"
            select="
            ($explicit-realign-anchor/@ref, $explicit-realign-div-ref-eq,
            $this-ref)[1]"/>
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
      <xsl:for-each-group select="$src-1st-da-realigned/tan:TAN-T/tan:body/(tan:div[not(tan:seg)], tan:div/tan:seg)"
         group-by="if (self::tan:div) then @realigned-ref else concat(@ref,'##',@seg)">
         <xsl:if
            test="count(current-group()) = $return-groups-of-size or empty($return-groups-of-size)">
            <group ref="{current-grouping-key()}"
               src="{for $i in current-group() return root($i)/*/@src}">
               <xsl:sequence select="current-group()"/>
            </group>
         </xsl:if>
      </xsl:for-each-group> 
   </xsl:function>




   <!-- Items below are yet to be reviewed for inclusion or deletion -->

   <!--<xsl:function name="tan:get-srcs-whose-tokens-are-defined">
      <xsl:copy-of select="tan:src-ids-to-nos($head/tan:declarations/tan:token-definition/@src)"/>
   </xsl:function>-->
   <!--<xsl:function name="tan:get-src-1st-da-data-segmented" as="document-node()*">
      <xsl:copy-of
         select="tan:segment-tokenized-prepped-class-1-doc(tan:tokenize-prepped-class-1-doc(tan:get-src-1st-da-prepped()))"
      />
   </xsl:function>-->


   <!--<xsl:function name="tan:get-work-iris" as="element()*">
      <xsl:variable name="equate-works" select="tan:get-work-equivalents()"/>
      <xsl:variable name="src-1st-da-heads" select="tan:get-src-1st-da-heads()"/>
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
   </xsl:function>-->
   <!--<xsl:function name="tan:expand-equate-div-types" as="element()*">
      <xsl:variable name="src-1st-da-all-div-types" select="tan:get-src-1st-da-all-div-types()"/>
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
   </xsl:function>-->
   <!--<xsl:function name="tan:get-equate-div-types-replaces" as="node()+">
      <!-\- Sequence of one element per source, then one element per div-type, correlating @xml:id or its renamed 
         value with an integer for the position of the first div-type within all div-types that share 
         an IRI value -\->
      <xsl:variable name="equate-div-types-sorted" select="tan:expand-equate-div-types()"/>
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xml:source>
            <xsl:for-each select="tan:get-src-1st-da-all-div-types()/tan:source[$this-src]/tan:div-type">
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
               <!-\- Used to strip out leading punctuation -\->
               <tan:pattern>^:</tan:pattern>
               <tan:replacement/>
            </tan:replace>
         </xml:source>
      </xsl:for-each>
   </xsl:function>-->
   <!-- March 2016: let's see if we can't get rid of this and calculate leaf div splits
   during the tan:segment-tokenized-prepped-class-1-doc() operation. -->
   <!--<xsl:function name="tan:get-leaf-div-splits-raw" as="element()*">
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
   </xsl:function>
   <xsl:function name="tan:group-leaf-div-splits" as="element()*">
      <xsl:for-each-group select="tan:get-leaf-div-splits-raw()/tan:source/tan:div/tan:tok"
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
   </xsl:function>-->
   <!--<xsl:function name="tan:get-realigns-normalized">
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:copy-of select="tan:expand-realign($body/tan:realign, $src-1st-da-prepped)"/>
   </xsl:function>-->
   <!--<xsl:function name="tan:get-aligns-normalized">
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:copy-of select="tan:expand-align($body/tan:align, $src-1st-da-prepped)"/>
   </xsl:function>-->


   <!-- CONTEXT INDEPENDENT FUNCTIONS -->

   <!--<xsl:function name="tan:replace-sequence" as="xs:string?">
      <!-\- Input: single string and a sequence of tan:replace elements.
         Output: string that results from each tan:replace being sequentially applied to the input string.
         Used to calculate series of changes to be made to a single flatref. -\->
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
   </xsl:function>-->

   <!-- CONTEXT DEPENDENT FUNCTIONS -->

   <!--<xsl:function name="tan:pick-src-1st-da-resolved" as="document-node()*">
      <!-\- Input: any number of elements in the form <tan:* @src @ref /> (normally 
         tan:div-ref and tan:tok; @seg, @val, @pos, and @char are immaterial)
         Output: Series of resolved sources with nothing but the <head> (intact) and those parts of the
         <body> that have been picked by the input.
         This will check a <div-ref>'s parent's @exclusive (../@exclusive) to determine whether
         to use other work equivalents or not.
      -\->
      <xsl:param name="div-ref-or-tok" as="element()*"/>
      <xsl:param name="src-1st-da-resolved" as="document-node()*"/>
      <xsl:variable name="equate-works" select="tan:get-work-equivalents($src-1st-da-resolved)"/>
      <xsl:variable name="src-div-types-to-suppress" select="tan:get-src-div-types-to-suppress()"/>
      <!-\- next variable a good candidate for creation of a new function -\->
      <xsl:variable name="expanded-refs" as="element()*">
         <xsl:for-each select="$div-ref-or-tok">
            <xsl:variable name="this-element" select="."/>
            <xsl:variable name="this-ref-norm" select="tan:normalize-refs(@ref)"/>
            <xsl:variable name="is-exclusive"
               select="
                  if (name(.) = 'tok' or (../@exclusive = true())) then
                     true()
                  else
                     false()"
            />
            <xsl:variable name="these-sources"
               select="
                  if ($is-exclusive = true()) then
                     tokenize(tan:normalize-text(@src), '\s+')
                  else
                     distinct-values(for $i in tokenize(tan:normalize-text(@src), '\s+'),
                        $j in index-of($src-ids-all, $i),
                        $k in $equate-works[$j],
                        $l in index-of($equate-works, $k)
                     return
                        $src-ids-all[$l])"
            />
            <xsl:for-each select="$these-sources">
               <xsl:variable name="this-src" select="."/>
               <xsl:variable name="this-src-no" select="index-of($src-ids-all,$this-src)"/>
               <xsl:for-each select="tokenize($this-ref-norm,'\s*,\s+')">
                  <div-ref src="{$this-src}" ref="{.}"/>
               </xsl:for-each>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$src-1st-da-resolved"><!-\- no, this needs to be a $src-1st-da that has been flattened, then its @ns renamed -\->
         <xsl:variable name="pos" select="position()"/>
         <xsl:variable name="this-src-id" select="$src-ids-all[$pos]"/>
         <xsl:choose>
            <xsl:when test="$expanded-refs/@src = $this-src-id">
               <xsl:variable name="this-source-resolved" select="tan:resolve-doc(.)"/>
               <xsl:copy>
                  <xsl:apply-templates select="$this-source-resolved/*" mode="pick-src-1st-da">
                     <xsl:with-param name="refs" select="$expanded-refs[@src = $this-src-id]/@ref"/>
                     <xsl:with-param name="div-suppress" select="$src-div-types-to-suppress[$pos]"/>
                  </xsl:apply-templates>
               </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="$empty-doc"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each> 
   </xsl:function>-->
   <!--<xsl:template match="*" mode="pick-src-1st-da">
      <xsl:param name="refs" as="xs:string*"/>
      <xsl:param name="div-suppress" as="xs:string?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current" select="*">
            <xsl:with-param name="refs" select="$refs"/>
            <xsl:with-param name="div-suppress" select="$div-suppress"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>-->
   <!--<xsl:template match="tan:head" mode="pick-src-1st-da">
      <xsl:copy-of select="."/>
   </xsl:template>-->
   <!--<xsl:template match="tan:div | tei:div" mode="pick-src-1st-da">
      <xsl:param name="refs" as="xs:string*"/>
      <xsl:param name="div-suppress" as="xs:string?"/>
      <xsl:variable name="this-flatref" select="tan:flatref(.)"/>
      <xsl:variable name="this-flatref-adjusted"
         select="
            if (string-length($div-suppress) gt 0) then
               replace($this-flatref, $div-suppress, '')
            else
               $this-flatref"
      />
      <xsl:choose>
         <xsl:when test="$this-flatref-adjusted = $refs">
            <xsl:copy-of select="(., following-sibling::node()[1][self::text()])"/>
         </xsl:when>
         <xsl:when test="some $i in $refs satisfies tokenize($i,' - ')[1] = $this-flatref-adjusted">
            <xsl:variable name="these-matches" select="$refs[tokenize(.,' - ')[1] = $this-flatref-adjusted]"/>
            <xsl:choose>
               <xsl:when test="some $i in $these-matches satisfies matches($i,' - ')">
                  <!-\- I realize that there could be multiple matches, but in the interest of time, I'm matching only the first range -\->
                  <xsl:variable name="first-ranged-match" select="$these-matches[matches(.,' - ')][1]"/>
                  <xsl:variable name="target" select="tokenize($first-ranged-match,' - ')[2]"/>
                  <xsl:copy-of
                     select="
                        (self::*, following::*, following::text()[not(matches(.,'\S'))]) except following::*[(if (string-length($div-suppress) gt 0) then
                           replace(tan:flatref(.), $div-suppress, '')
                        else
                           tan:flatref(.)) = $target]/(following::*, following::text())"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:when
            test="
               some $i in $refs
                  satisfies (matches($i, concat('^', $this-flatref-adjusted, $separator-hierarchy-regex)))">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="refs" select="$refs"/>
                  <xsl:with-param name="div-suppress" select="$div-suppress"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
      </xsl:choose>
   </xsl:template>-->

   <!--<xsl:function name="tan:expand-div-ref" as="element()*">
      <!-\- takes one <div-ref> or <anchor-div-ref> and returns one <div-ref> per source per
      ref per segment, replacing @src with numerical value, @ref with normalized single reference, and 
      @seg (if present) with a single number. If the second parameter is true() a @work attribute is
      added with the integer value of the work. A copy of the original reference is retained, in case
      the original formula is needed.
      E.g., (<div-ref src="A B" ref="1 - 2" seg="1, last"/>, true()) - > (<div-ref work="1" src="1" ref="line.1" seg="1" orig-ref="1 - 2"/>, 
      <div-ref work="1" src="1" ref="line.1" seg="7" orig-ref="1 - 2"/>, <div-ref work="1" src="1" ref="line.2" seg="1" orig-ref="1 - 2"/>,
      <div-ref work="1" src="1" ref="line.1" seg="3" orig-ref="1 - 2"/>, <div-ref work="1" src="2" ref="line.1" seg="1" orig-ref="1 - 2"/>, ...) 
      The parameter $shallow-picks specifies whether ranges should be resolved shallowly or deeply. See tan:itemize-refs().
      -\->
      <xsl:param name="div-ref-element" as="element()?"/>
      <xsl:param name="include-work" as="xs:boolean"/>
      <xsl:param name="shallow-picks" as="xs:boolean"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:variable name="these-srcs" select="tan:src-ids-to-nos($div-ref-element/@src)"/>
      <xsl:variable name="work-equivalents" select="tan:get-work-equivalents($src-1st-da-prepped)"/>
      <xsl:variable name="src-1st-da-data-segmented"
         select="tan:segment-tokenized-prepped-class-1-doc(tan:tokenize-prepped-class-1-doc(tan:get-src-1st-da-prepped()))"/>
      <xsl:for-each select="$these-srcs">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="this-ref-norm" select="tan:normalize-refs($div-ref-element/@ref)"/>
         <xsl:variable name="this-ref-expand"
            select="
               if ($div-ref-element/@seg) then
                  tan:itemize-leaf-refs($this-ref-norm, $this-src, $src-1st-da-prepped)
               else
                  tan:itemize-refs($this-ref-norm, $this-src, $shallow-picks, $src-1st-da-prepped)"
         />
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
                     <xsl:attribute name="work" select="$work-equivalents[$this-src]"/>
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
   </xsl:function>-->


   <!--<xsl:function name="tan:expand-realign" as="item()*">
      <!-\- Takes one or more <tan:realign> and returns a normalized, expanded version, taking into 
         account rules for distribution and <anchor-div-ref>. The result follows this pattern:
      <tan:realign [+ANY ATTRIBUTES]>
        <tan:group>[ONE, IF NOT DISTRIBUTED, OTHERWISE ONE PER DISTRIBUTION] [@error FOR UNMATCHED 
        DISTRIBUTIONS] [IF FED FROM tan:expand-align() THEN IF (@exclusive) THEN] src="[SOURCE NUMBER]" 
        [ELSE] work="[WORK NUMBER]"
         <tan:(anchor-)div-ref> [COPY OF, DISTRIBUTED, IF APPROPRIATE]
      -\->
      <xsl:param name="realign-element" as="element()*"/>
      <xsl:variable name="src-1st-da-prepped" select="tan:get-src-1st-da-prepped()"/>
      <xsl:for-each select="$realign-element">
         <xsl:variable name="this-realign" select="."/>
         <xsl:variable name="resolve-ranges-shallowly"
            select="
            if ($this-realign/@distribute = true()) then
            true()
            else
            false()
            "
         />
         <xsl:variable name="to-be-distributed" select="$resolve-ranges-shallowly"/>
         <xsl:variable name="anchor-itemized" as="element()">
            <group>
               <xsl:copy-of select="tan:distribute-src-and-ref($this-realign/tan:anchor-div-ref, $resolve-ranges-shallowly)"/>
            </group>
         </xsl:variable>
         <xsl:variable name="anchor-itemized-leaf-divs-only" as="element()">
            <xsl:apply-templates mode="remove-non-leaf-div-refs">
               <xsl:with-param name="src-1st-da-prepped" select="$src-1st-da-prepped"></xsl:with-param>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:variable name="realigned-itemized" as="element()*">
            <xsl:for-each-group select="$this-realign/tan:div-ref" group-by="count(preceding-sibling::*[not(@cont)])">
               <xsl:variable name="pass-1" select="tan:distribute-src-and-ref(current-group(), $resolve-ranges-shallowly)"/>
               <xsl:for-each-group select="$pass-1" group-by="@src">
                  <group>
                     <xsl:copy-of select="current-group()"/>
                  </group>
               </xsl:for-each-group>
            </xsl:for-each-group> 
         </xsl:variable>
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
               <xsl:when test="$to-be-distributed = true()">
                  <xsl:copy-of
                     select="tan:distribute-elements-of-elements(($anchor-itemized, $realigned-itemized))"/>
               </xsl:when>
               <xsl:otherwise>
                  <realign>
                     <xsl:copy-of select="$anchor-itemized, $realigned-itemized"/>
                  </realign>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>-->
   <!--<xsl:function name="tan:distribute-elements-of-elements" as="element()*">
      <!-\- Input: a sequence of elements with child elements to be distributed and regrouped. 
         Output: a sequence of elements where the nth item of each top-level input element is grouped 
         together. Items that cannot be distributed will be lumped together in a final group with the 
         attribute @error='true'.
         E.g., <group><a>one</a><a>two</a></group>, <group><b>three</b></group>
         - > 
         <group><a>one</a><b>three</b></group>, <group error="true"><a>two</a></group>
      -\->
      <xsl:param name="input-elements" as="element()*"/>
      <xsl:variable name="src-1st-da-prepped" select="tan:get-src-1st-da-prepped()"/>
      <xsl:variable name="count-per-element" select="for $i in $input-elements return count($i/*)"/>
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

   <!--<xsl:function name="tan:convert-ns-to-numerals" as="xs:string">
      <!-\- converts a flattened ref's @n values to numerals according to their use in a given source
            Input: single flatref as a string, source number as integer
            Output: revised flatref, substituting @n values for numerals where appropriate
            E.g., ('bk ch', 'xxiv 2b', 'grc', $n-types) - > '24 2#2'
        -\->
      <xsl:param name="norm-types" as="xs:string"/>
      <xsl:param name="norm-flatref" as="xs:string"/>
      <xsl:param name="src-id" as="xs:string"/>
      <xsl:param name="n-types" as="element()*"/>
      <xsl:variable name="types" select="tokenize($norm-types, $separator-hierarchy-regex)"/>
      <xsl:variable name="ns" select="tokenize($norm-flatref, $separator-hierarchy-regex)"/>
      <xsl:variable name="ns-converted"
         select="
         for $i in (1 to count($ns))
         return
         tan:replace-ns($types[$i], $ns[$i], $src-id, $n-types)"
      />
      <xsl:value-of select="string-join($ns-converted, $separator-hierarchy)"/>
   </xsl:function>-->
   <!--<xsl:function name="tan:replace-ns" as="xs:string">
      <!-\- Input: single value of @type and @n, source number
      Output: single string replacing (or not) the value of @n with its Arabic numerical equivalent as appropriate 
      and as a string.
      E.g., ('bk', 'xxiv', 'grc', $n-types) - > '24' -\->
      <xsl:param name="div-type" as="xs:string?"/>
      <xsl:param name="div-n" as="xs:string?"/>
      <xsl:param name="src-id" as="xs:string?"/>
      <xsl:param name="n-types" as="element()*"/>
      <xsl:variable name="this-n-type"
         select="$n-types[@src = $src-id]/tan:div-type[@xml:id = $div-type]/@n-type"/>
      <xsl:choose>
         <xsl:when test="$this-n-type = $n-type[1]">
            <xsl:value-of
               select="
                  if (matches($div-n, $n-type-pattern[1], 'i'))
                  then
                     tan:rom-to-int($div-n)
                  else
                     $div-n"
            />
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[2]">
            <!-\- digits don't need conversion -\->
            <xsl:value-of select="$div-n"/>
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[3]">
            <xsl:choose>
               <xsl:when test="matches($div-n, $n-type-pattern[3], 'i')">
                  <xsl:variable name="this-n-split"
                     select="tokenize(replace($div-n, $n-type-pattern[3], '$1 $2'), ' ')"/>
                  <xsl:value-of
                     select="concat($this-n-split[1], '#', tan:aaa-to-int($this-n-split[2]))"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$div-n"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[4]">
            <xsl:value-of
               select="
                  if (matches($div-n, $n-type-pattern[4], 'i'))
                  then
                     tan:aaa-to-int($div-n)
                  else
                     $div-n"
            />
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[5]">
            <xsl:choose>
               <xsl:when test="matches($div-n, $n-type-pattern[5], 'i')">
                  <xsl:variable name="this-n-split"
                     select="tokenize(replace($div-n, $n-type-pattern[5], '$1 $2'), ' ')"/>
                  <xsl:value-of
                     select="concat(tan:aaa-to-int($this-n-split[1]), '#', $this-n-split[2])"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$div-n"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <!-\- strings don't need conversion -\->
            <xsl:value-of select="$div-n"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>-->
   <!-- March 2016: I think this is probably overly complicated -->
   <!--<xsl:function name="tan:equate-ref" as="item()*">
      <!-\- Input: any source number, any single normalized ref, and any single segment number
      Output: reference that converts @ns to numerals when possible, @type to a div type number, and takes into account
      any exemptions made in a <realign>, segment number (altered if required by <realign>) 
      E.g., (1, 'bk ch', '1 4', 1) - > ('1 2', '1 4', 1)
      -\->
      <xsl:param name="src-id" as="xs:string?"/>
      <xsl:param name="norm-types" as="xs:string?"/>
      <xsl:param name="norm-ref" as="xs:string?"/>
      <xsl:param name="seg-no" as="xs:integer?"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:param name="div-type-equivalents" as="element()*"/>
      <xsl:param name="n-types" as="element()*"/>
      <xsl:variable name="realigns-normalized"
         select="
            for $i in $body/tan:realign
            return
               tan:expand-realign($i, $src-1st-da-prepped)"
      />
      <xsl:variable name="first-realignment"
         select="($realigns-normalized[not(@error)]/tan:div-ref[@src = $src-id][@ref = $norm-ref][not(@seg) or @seg = $seg-no])[1]"/>
      <xsl:variable name="realignment-anchor"
         select="$first-realignment/preceding-sibling::tan:anchor-div-ref"/>
      <xsl:variable name="realigned-eq-ref-and-seg" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($realignment-anchor)">
               <!-\- If there's an anchor in the realignment, get its @eq-ref and @seg values -\->
               <xsl:copy-of
                  select="tan:equate-ref($realignment-anchor/@src, $realignment-anchor/@type, $realignment-anchor/@ref, $realignment-anchor/@seg, $src-1st-da-prepped, $div-type-equivalents, $n-types)"
               />
            </xsl:when>
            <xsl:when
               test="not(exists($realignment-anchor)) and $first-realignment/preceding-sibling::tan:div-ref[@src ne $first-realignment/@src]">
               <!-\- If there's no anchor, but there's another source before it, get the @eq-ref and @seg values of the first div-ref -\->
               <xsl:copy-of
                  select="tan:equate-ref($first-realignment/../tan:div-ref[1]/@src, $first-realignment/../tan:div-ref[1]/@type, $first-realignment/../tan:div-ref[1]/@ref, $first-realignment/../tan:div-ref[1]/@seg, $src-1st-da-prepped, $div-type-equivalents, $n-types)"
               />
            </xsl:when>
            <xsl:otherwise>
               <!-\- Otherwise assume that it just is exempt from any realignment, and prepend a value to norm-ref that exempts it from auto-alignment -\->
               <xsl:copy-of select="(concat('s', $src-id, '_', $norm-ref), $seg-no)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="exists($first-realignment)">
            <xsl:sequence select="$realigned-eq-ref-and-seg"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence
               select="tan:replace-sequence(tan:convert-ns-to-numerals($norm-types, $norm-ref, $src-id, $n-types), 
               $src-1st-da-div-types-equiv-replace[$src-id]/tan:replace)"
            />
            <xsl:copy-of select="$seg-no"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>-->
   <!--<xsl:function name="tan:equate-ref" as="item()*">
      <!-\- Input: any source number, any single normalized ref, and any single segment number
      Output: reference that converts @ns to numerals when possible, @type to a div type number, and takes into account
      any exemptions made in a <realign>, segment number (altered if required by <realign>) 
      E.g., (1,'bk.1:ch.4',1) - > ('1.1:2.4',1)
      -\->
      <xsl:param name="src-no" as="xs:integer?"/>
      <xsl:param name="norm-ref" as="xs:string?"/>
      <xsl:param name="seg-no" as="xs:integer?"/>
      <xsl:variable name="src-1st-da-div-types-equiv-replace"
         select="tan:get-equate-div-types-replaces()"/>
      <xsl:variable name="realigns-normalized"
         select="
            for $i in $body/tan:realign
            return
               tan:normalize-realign($i)"/>
      <xsl:variable name="first-realignment"
         select="($realigns-normalized[not(@error)]/tan:div-ref[@src = $src-no][@ref = $norm-ref][not(@seg) or @seg = $seg-no])[1]"/>
      <xsl:variable name="realignment-anchor"
         select="$first-realignment/preceding-sibling::tan:anchor-div-ref"/>
      <xsl:variable name="realigned-eq-ref-and-seg" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($realignment-anchor)">
               <!-\- If there's an anchor in the realignment, get its @eq-ref and @seg values -\->
               <xsl:copy-of
                  select="tan:equate-ref($realignment-anchor/@src, $realignment-anchor/@ref, $realignment-anchor/@seg)"
               />
            </xsl:when>
            <xsl:when
               test="not(exists($realignment-anchor)) and $first-realignment/preceding-sibling::tan:div-ref[@src ne $first-realignment/@src]">
               <!-\- If there's no anchor, but there's another source before it, get the @eq-ref and @seg values of the first div-ref -\->
               <xsl:copy-of
                  select="tan:equate-ref($first-realignment/../tan:div-ref[1]/@src, $first-realignment/../tan:div-ref[1]/@ref, $first-realignment/../tan:div-ref[1]/@seg)"
               />
            </xsl:when>
            <xsl:otherwise>
               <!-\- Otherwise assume that it just is exempt from any realignment, and prepend a value to norm-ref that exempts it from auto-alignment -\->
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
   </xsl:function>-->

</xsl:stylesheet>
