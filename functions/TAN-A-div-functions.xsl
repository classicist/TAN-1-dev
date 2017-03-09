<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd tan fn tei"
   version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Revised</xd:b>Nov 11, 2016</xd:p>
         <xd:p>Core functions for TAN-A-div files. Written principally for Schematron validation,
            but suitable for general use in other contexts</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="incl/TAN-class-2-functions.xsl"/>
   <xsl:include href="errors/TAN-A-div-errors.xsl"/>

   <!-- PART I. 
      GLOBAL VARIABLES AND PARAMETERS -->

   <xsl:variable name="self-and-sources-prepped-prelim"
      select="tan:prep-resolved-class-2-doc($self-core-errors-marked)"/>
   <xsl:variable name="self-and-sources-prepped"
      select="tan:prep-resolved-tan-a-div-doc($self-and-sources-prepped-prelim)"/>
   <xsl:variable name="self-prepped" select="$self-and-sources-prepped[1]"/>
   <xsl:variable name="sources-prepped" select="$self-and-sources-prepped[position() gt 1]"/>

   <!-- PART II. 
      FUNCTIONS PROCESSING SELF -->

   <xsl:function name="tan:prep-resolved-tan-a-div-doc" as="document-node()*">
      <!-- Input: a TAN-A-div document and its sources, as prepared by tan:prep-resolved-class-2-doc() -->
      <!-- Output: the same documents, prepared with TAN-A-div specific considerations -->
      <!--
      FOCUS           ALTERATIONS
      =======   =============================================================================================
      sources   Segment sources
      self      Expand <div-ref> and <anchor-div-ref> on @seg, making in <realign> a deep copy of the <div>s and <seg>s referred to
      self      Distribute <align> and <realign>; signal errors of realignment
      self      Mark errors
      -->
      <!-- Note, because this function is designed to expedite validation, it does not realign the sources, which must be done through tan:merge-tan-a-div-prepped() -->
      <xsl:param name="self-and-sources-prepped-class-2" as="document-node()*"/>
      <xsl:variable name="this-class-2"
         select="
            if (exists($self-and-sources-prepped-class-2)) then
               $self-and-sources-prepped-class-2[1]
            else
               $self-and-sources-prepped-prelim[1]"/>
      <xsl:variable name="these-sources"
         select="
            if (count($self-and-sources-prepped-class-2) gt 1) then
               $self-and-sources-prepped-class-2[position() gt 1]
            else
               $self-and-sources-prepped-prelim[position() gt 1]"/>
      <xsl:variable name="class-1-sources-prepped-pass-a"
         select="tan:get-src-1st-da-segmented($this-class-2, $these-sources)" as="document-node()*"/>
      <xsl:variable name="tan-a-div-prepped-pass-a" as="document-node()?">
         <xsl:document>
            <xsl:apply-templates select="$this-class-2" mode="prep-tan-a-div-pass-a">
               <xsl:with-param name="sources-segmented" select="$class-1-sources-prepped-pass-a"
                  tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="tan-a-div-prepped-pass-b" as="document-node()?">
         <xsl:document>
            <xsl:apply-templates select="$tan-a-div-prepped-pass-a" mode="prep-tan-a-div-pass-b"/>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="tan-a-div-prepped-pass-c" as="document-node()?"
         select="tan:prep-TAN-claims($tan-a-div-prepped-pass-b)"/>
      <xsl:variable name="tan-a-div-prepped-errors-flagged" as="document-node()?">
         <xsl:document>
            <xsl:apply-templates select="$tan-a-div-prepped-pass-c" mode="TAN-A-div-errors"/>
         </xsl:document>
      </xsl:variable>
      <!-- diagnostics, output -->
      <!--<xsl:copy-of select="$this-class-2"/>-->
      <!--<xsl:copy-of select="$tan-a-div-prepped-pass-a"/>-->
      <!--<xsl:copy-of select="$tan-a-div-prepped-pass-b"/>-->
      <!--<xsl:copy-of select="$tan-a-div-prepped-pass-c"/>-->
      <xsl:copy-of select="$tan-a-div-prepped-errors-flagged"/>
      <xsl:copy-of select="$class-1-sources-prepped-pass-a"/>
   </xsl:function>

   <!-- Templates rooted in TAN-class-2-functions.xsl -->

   <xsl:template match="node()"
      mode="segment-tokd-prepped-class-1 prep-tan-a-div-pass-a prep-tan-a-div-pass-b realign-tan-a-div-sources">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:equate-works" mode="prep-tan-a-div-pass-a">
      <xsl:variable name="source-order" select="/tan:TAN-A-div/tan:head/tan:source/@xml:id"/>
      <xsl:variable name="help-requested" select="tan:help-requested(.)"/>
      <xsl:variable name="viable-groups" select="../tan:equate-works[tan:work]"/>
      <xsl:variable name="this-message" as="xs:string*">
         <xsl:value-of select="count($viable-groups/tan:work)"/>
         <xsl:text> sources fall in </xsl:text>
         <xsl:value-of select="count($viable-groups)"/>
         <xsl:text> works: </xsl:text>
         <xsl:for-each select="$viable-groups">
            <xsl:variable name="work-title" select="distinct-values(tan:work/tan:name)"/>
            <xsl:variable name="secondary-work-title-message"
               select="
                  if (count($work-title) gt 1) then
                     concat(' (', string-join($work-title[position() gt 1], '; '), ')')
                  else
                     ()"/>
            <xsl:value-of
               select="
                  concat('[', string-join(tan:work/@src, ' '), '] ', $work-title[1], if (count($work-title) gt 1) then
                     $secondary-work-title-message
                  else
                     ())"
            />
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$help-requested = true()">
            <xsl:copy-of select="tan:help(string-join($this-message, ''), ())"/>
         </xsl:if>
         <xsl:copy-of select="* except tan:work"/>
         <xsl:for-each select="tan:work">
            <xsl:sort select="index-of($source-order, @src)"/>
            <xsl:copy-of select="."/>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>
   <xsl:template
      match="tan:equate-div-types[tan:help-requested(.)] | tan:equate-div-types/tan:div-type-ref[tan:help-requested(.)]"
      mode="prep-tan-a-div-pass-a">
      <xsl:variable name="viable-groups"
         select="ancestor::tan:body/tan:equate-div-types[tan:div-type]"/>
      <xsl:variable name="this-message" as="xs:string*">
         <xsl:value-of select="count($viable-groups/tan:div-type)"/>
         <xsl:text> div types fall in </xsl:text>
         <xsl:value-of select="count($viable-groups)"/>
         <xsl:text> groups: </xsl:text>
         <xsl:for-each select="$viable-groups">
            <xsl:variable name="div-type-title" select="distinct-values(tan:div-type/tan:name)"/>
            <xsl:variable name="secondary-div-type-title-message"
               select="
                  if (count($div-type-title) gt 1) then
                     concat(' (', string-join($div-type-title[position() gt 1], '; '), ')')
                  else
                     ()"/>
            <xsl:value-of
               select="
                  concat('[', string-join(for $i in tan:div-type
                  return
                     concat($i/@src, ' ', $i/@xml:id), ' '), '] ', $div-type-title[1], if (count($div-type-title) gt 1) then
                     $secondary-div-type-title-message
                  else
                     (), ' ')"
            />
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="tan:help(string-join($this-message, ''), ())"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:realign" mode="prep-tan-a-div-pass-a">
      <xsl:variable name="pos" select="string(count(preceding-sibling::tan:realign) + 1)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="id" select="concat('#realign', $pos)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:align" mode="prep-tan-a-div-pass-a">
      <xsl:variable name="pos" select="string(count(preceding-sibling::tan:align) + 1)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="id" select="concat('#align', $pos)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*[@seg]" mode="prep-tan-a-div-pass-a">
      <!-- goal: flag errors in @seg; if it's a <realign>, make a copy of the entire <div> -->
      <xsl:param name="sources-segmented" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:variable name="this-src" select="@src"/>
      <xsl:variable name="this-ref" select="*/@ref"/>
      <xsl:variable name="this-seg" select="@seg"/>
      <xsl:variable name="these-divs"
         select="$sources-segmented/tan:TAN-T[@src = $this-src]/tan:body//tan:div[@ref = $this-ref][not(@type = '#seg')]"/>
      <xsl:variable name="is-in-realign" as="xs:boolean" select="exists(parent::tan:realign)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="(tan:error, tan:help, tan:warning, tan:message, tan:info)"/>
         <xsl:for-each select="$these-divs">
            <xsl:variable name="these-segs" select="tan:div[@type = '#seg']"/>
            <xsl:variable name="this-seg-count" select="count($these-segs)"/>
            <xsl:variable name="seg-nos-picked"
               select="tan:sequence-expand($this-seg, $this-seg-count)"/>
            <xsl:variable name="this-message"
               select="concat(@ref, ' has ', string($this-seg-count), ' segments')"/>
            <xsl:copy-of select="tan:sequence-error($seg-nos-picked, $this-message)"/>
            <xsl:if test="exists(tan:div[not(@type = '#seg')])">
               <xsl:copy-of select="tan:error('seg01')"/>
            </xsl:if>
            <xsl:choose>
               <xsl:when test="$is-in-realign = false()">
                  <div>
                     <xsl:copy-of select="$these-segs[position() = $seg-nos-picked]/@*"/>
                  </div>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="$these-segs[position() = $seg-nos-picked]"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div-ref[not(@seg)][parent::tan:realign] | tan:anchor-div-ref[not(@seg)][parent::tan:realign]"
      mode="prep-tan-a-div-pass-a">
      <!-- We make a copy of the referenced <div> only if it is a <realign>, so that we can save work for a later process that adjusts the sources -->
      <xsl:param name="sources-segmented" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="this-src" select="@src"/>
      <xsl:variable name="this-ref" select="*/@ref"/>
      <xsl:variable name="this-div"
         select="$sources-segmented/tan:TAN-T[@src = $this-src]/tan:body//tan:div[@ref = $this-ref]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="(tan:error, tan:help, tan:fatal, tan:message, tan:warning)"/>
         <xsl:copy-of select="$this-div"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:align | tan:realign" mode="prep-tan-a-div-pass-b">
      <!-- Goal: redistribute contents of aligns and realigns -->
      <xsl:variable name="this-align-or-realign" select="."/>
      <xsl:variable name="is-realign" select="name(.) = 'realign'" as="xs:boolean"/>
      <xsl:variable name="source-count" select="count(distinct-values(tan:div-ref/@src))"/>
      <xsl:variable name="anchor-div-ref-counts" select="count(tan:anchor-div-ref/tan:div[not(@complex)])"/>
      <xsl:variable name="these-group-ids" select="distinct-values(tan:div-ref/@group)"/>
      <xsl:variable name="div-ref-counts"
         select="
            for $i in $these-group-ids
            return
               count(*[@group = $i]/tan:div[not(@complex)])"/>
      <!-- If there are no anchors, then ignore them -->
      <xsl:variable name="min-div-ref-group"
         select="
            min(($div-ref-counts,
            if ($anchor-div-ref-counts gt 0) then
               $anchor-div-ref-counts
            else
               ()))"
      />
      <xsl:variable name="max-div-ref-group"
         select="
            max(($div-ref-counts,
            if ($anchor-div-ref-counts gt 0) then
               $anchor-div-ref-counts
            else
               ()))"
      />
      <xsl:variable name="uneven-distributions" as="xs:boolean?"
         select="$min-div-ref-group lt $max-div-ref-group"/>
      <xsl:choose>
         <xsl:when test="$source-count = 1 and $is-realign = true() and $anchor-div-ref-counts lt 1">
            <!-- This is an unanchored one-source realignment -->
            <xsl:for-each select="tan:div-ref/tan:div">
               <xsl:variable name="pos" select="position()"/>
               <realign>
                  <xsl:copy-of select="$this-align-or-realign/(@* except @id)"/>
                  <xsl:attribute name="id"
                     select="concat($this-align-or-realign/@id, '-', string($pos))"/>
                  <xsl:if test="$pos = 1">
                     <!-- transmit inherited errors in the first re/align only -->
                     <xsl:copy-of select="$this-align-or-realign/*[not(tan:div)]"/>
                  </xsl:if>
                  <div-ref>
                     <xsl:copy-of select="../@*"/>
                     <xsl:copy-of select="../*[not(self::tan:div)]"/>
                     <xsl:copy-of select="."/>
                  </div-ref>
               </realign>
            </xsl:for-each>
         </xsl:when>
         <xsl:when
            test="
               ($max-div-ref-group gt 1) and
               (@distribute = true() or
               ($is-realign = true() and $anchor-div-ref-counts ne 1))">
            <!-- If there's more than one div-ref, then redistribute if it's an align with @distribute as true or if it's a realign that doesn't have merely one anchor -->
            <xsl:for-each select="1 to $max-div-ref-group">
               <xsl:variable name="pos" select="."/>
               <xsl:element name="{name($this-align-or-realign)}">
                  <xsl:copy-of select="$this-align-or-realign/(@* except @id)"/>
                  <xsl:attribute name="id"
                     select="concat($this-align-or-realign/@id, '-', string($pos))"/>
                  <xsl:if test="$pos = 1">
                     <!-- transmit inherited errors in the first re/align only -->
                     <xsl:copy-of select="$this-align-or-realign/*[not(tan:div)]"/>
                  </xsl:if>
                  <xsl:if test="$uneven-distributions = true() and $pos gt $min-div-ref-group">
                     <xsl:copy-of
                        select="
                           tan:error('dst01', concat('attempt to correlate groups of size ', (if ($anchor-div-ref-counts gt 0) then
                              concat(tan:value-of($anchor-div-ref-counts), ' ')
                           else
                              ()), tan:value-of($div-ref-counts)))"
                     />
                  </xsl:if>
                  <xsl:for-each select="$this-align-or-realign/tan:anchor-div-ref">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:if test="$pos = 1">
                           <xsl:copy-of select="* except tan:div"/>
                        </xsl:if>
                        <xsl:copy-of select="tan:div[not(@complex)][$pos]"/>
                     </xsl:copy>
                  </xsl:for-each>
                  <xsl:for-each-group select="$this-align-or-realign/tan:div-ref" group-by="@group">
                     <xsl:variable name="this-div-or-seg" select="tan:div[not(@complex)][$pos]"/>
                     <div-ref>
                        <xsl:copy-of select="$this-div-or-seg/../@*"/>
                        <xsl:if test="$pos = 1">
                           <xsl:copy-of select="* except tan:div"/>
                        </xsl:if>
                        <xsl:if test="exists($this-div-or-seg/@see)">
                           <xsl:copy-of select="tan:div[@complex][@n = $this-div-or-seg/@see]"/>
                        </xsl:if>
                        <xsl:copy-of select="$this-div-or-seg"/>
                     </div-ref>
                  </xsl:for-each-group>
               </xsl:element>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <!-- If there are no divs or segs at all, then just copy the element since there's probably an error -->
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>



   <!-- Jan 2017: slated for deletion -->
   <!--<xsl:template match="tan:tok" mode="prep-tan-a-div-pass-3-prelim">
      <xsl:param name="sources-prepped-1" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="token-definitions"
         select="root()/tan:TAN-A-div/tan:head/tan:declarations/tan:token-definition"/>
      <xsl:variable name="this-tok" select="."/>
      <xsl:variable name="this-src" select="@src"/>
      <xsl:variable name="pass-1"
         select="tan:convert-ref-to-div-fragment($sources-prepped-1[*/@src = $this-src], ., true(), false())"
         as="element()*"/>
      <xsl:variable name="pass-2" as="element()*">
         <xsl:apply-templates select="$pass-1" mode="tokenize-prepped-class-1">
            <xsl:with-param name="token-definitions" select="$token-definitions[@src = $this-src]"
               tunnel="yes"/>
            <xsl:with-param name="add-n-attr" select="true()" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:for-each select="$pass-2">
         <!-\-<xsl:variable name="this-ref" select="@ref"/>-\->
         <xsl:variable name="these-toks" select="tan:get-toks(., $this-tok)" as="element()*"/>
         <xsl:for-each select="$these-toks">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$this-src"/>
               <xsl:copy-of select="@ref"/>
               <xsl:if test="@n = 1">
                  <xsl:copy-of select="tan:error('spl03')"/>
               </xsl:if>
               <xsl:copy-of select="node()"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:template>-->



   <!-- Nov 2016: to be deleted -->
   <!--<xsl:template match="tan:div-ref[not(@src)]" mode="prep-tan-a-div-pass-3-prelim">
      <!-\- This template distributes elements with @work across all the sources that are implied, using the resolved <equate-works> that has been placed in the body in the process of preparation pass 2 -\->
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="head-of-group" select="(preceding-sibling::*:div-ref[@work])[last()]"/>
      <xsl:variable name="is-continuation" select="not(exists(@work))"/>
      <xsl:variable name="this-work-attr" as="xs:string?"
         select="
            if ($is-continuation = true()) then
               $head-of-group/@work
            else
               @work"/>
      <xsl:variable name="these-sources"
         select="ancestor::tan:body/tan:equate-works[tan:work/@src = $this-work-attr]/tan:work/@src"/>
      <xsl:for-each select="$these-sources">
         <xsl:variable name="this-src" select="."/>
         <xsl:variable name="pos" select="position()"/>
         <div-ref>
            <xsl:copy-of select="$this-element/@*"/>
            <xsl:attribute name="src" select="$this-src"/>
            <xsl:attribute name="group"
               select="count($this-element/preceding-sibling::*[not(@cont)]) + 1"/>
            <xsl:if test="$is-continuation = true()">
               <xsl:copy-of select="$head-of-group/(@strength, @cert)"/>
            </xsl:if>
            <xsl:copy-of select="$this-element/node()"/>
         </div-ref>
      </xsl:for-each>
   </xsl:template>-->

   <xsl:template match="tan:div-ref | tan:anchor-div-ref"
      mode="insert-seg-into-leaf-divs-in-hierarchy-fragment">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists(tan:div[tan:div]) and exists(@seg)">
            <xsl:copy-of select="tan:error('seg01')"/>
         </xsl:if>
         <xsl:apply-templates mode="insert-seg-into-leaf-divs-in-hierarchy-fragment"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[not(tan:div)]"
      mode="insert-seg-into-leaf-divs-in-hierarchy-fragment">
      <xsl:param name="splits" as="element()*" tunnel="yes"/>
      <xsl:variable name="master-div-ref"
         select="(ancestor::tan:div-ref, ancestor::tan:anchor-div-ref)"/>
      <xsl:variable name="this-src" select="$master-div-ref/@src"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="relevant-splits"
         select="$splits/tan:tok[@src = $this-src and @ref = $this-ref]"/>
      <xsl:variable name="number-of-segments" select="count($relevant-splits) + 1"/>
      <xsl:variable name="segments-desired" select="($master-div-ref/@seg, '1 - last')[1]"/>
      <xsl:variable name="segment-numbers"
         select="tan:sequence-expand($segments-desired, $number-of-segments)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="node()"/>
         <xsl:for-each select="$segment-numbers">
            <xsl:if test=". = 0">
               <xsl:copy-of
                  select="tan:error('seq01', concat($this-ref, ' has ', $number-of-segments, ' max segments'))"
               />
            </xsl:if>
            <xsl:if test=". = -1">
               <xsl:copy-of
                  select="tan:error('seq02', concat($this-ref, ' has ', $number-of-segments, ' max segments'))"
               />
            </xsl:if>
            <xsl:if test=". = -2">
               <xsl:copy-of select="tan:error('seq03')"/>
            </xsl:if>
            <seg n="{.}"/>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>


   <!-- Nov 2016: delendum -->
   <!--<xsl:template match="tan:realign/tan:div-ref" mode="prep-class-2-doc-pass-4">
      <xsl:param name="duplicate-refs" as="xs:string*" tunnel="yes"/>
      <xsl:variable name="this-ref"
         select="
            for $i in tan:div
            return
               concat(@src, '#', $i/@ref)"
         as="xs:string*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$this-ref = $duplicate-refs">
            <xsl:variable name="this-message"
               select="concat(@src, ' ', @ref, ' realigned multiple times')"/>
            <xsl:copy-of select="tan:error('rea01', $this-message)"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>-->


   <!-- Processing self after common class 2 functions are finished. -->

   <xsl:function name="tan:prep-verbosely" as="document-node()*">
      <!-- Input: a TAN-A-div file prepped and its sources, also prepped
         Output: the same files, with information marked of relevance to the validation process.
      -->
      <xsl:param name="TAN-A-div-prepped" as="document-node()?"/>
      <xsl:param name="TAN-A-div-sources-prepped" as="document-node()*"/>
      <xsl:variable name="this-skeleton" select="tan:get-src-skeleton($TAN-A-div-sources-prepped)"/>
      <xsl:document>
         <xsl:apply-templates select="$TAN-A-div-prepped" mode="prep-verbosely">
            <xsl:with-param name="source-skeleton" select="$this-skeleton" tunnel="yes"/>
            <xsl:with-param name="sources-prepped" select="$TAN-A-div-sources-prepped" tunnel="yes"
            />
         </xsl:apply-templates>
      </xsl:document>
      <!-- Nov 2016: validation rules so far do not require changes to the sources -->
      <xsl:sequence select="$TAN-A-div-sources-prepped"/>
   </xsl:function>

   <xsl:template match="node()" mode="prep-verbosely prep-srcs-verbosely">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="prep-verbosely"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="/*" mode="prep-verbosely">
      <xsl:param name="source-skeleton" tunnel="yes" as="document-node()?"/>
      <xsl:variable name="these-realigns" select="tan:body/tan:realign"/>
      <xsl:variable name="defective-divs"
         select="
            $source-skeleton//tan:div[@src][not(
            some $i in $these-realigns/*
               satisfies
               ($i/@src = tokenize(@src, '\s+') and $i//@ref = @ref))]"/>
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
                     ' [', $i/@src, ']')"/>
            <xsl:text>)</xsl:text>
         </xsl:if>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="tan:info(string-join($defective-divs-message, ''), ())"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:source" mode="prep-verbosely">
      <xsl:param name="sources-prepped" tunnel="yes" as="document-node()*"/>
      <xsl:variable name="this-src-id" select="@xml:id"/>
      <xsl:variable name="this-src-doc" select="($sources-prepped[*/@src = $this-src-id])[1]"/>
      <xsl:variable name="leaf-div-refs" select="$this-src-doc//tan:div[not(tan:div)]"/>
      <xsl:variable name="duplicate-leaf-div-refs"
         select="tan:duplicate-values($leaf-div-refs/@ref)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($duplicate-leaf-div-refs)">
            <xsl:copy-of
               select="tan:error('cl109', concat('src ', $this-src-id, ' has duplicate leaf divs: ', string-join($duplicate-leaf-div-refs, ', ')))"
            />
         </xsl:if>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:info" mode="prep-verbosely">
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
      <!-- Input: Any sources for a TAN-A-div, preliminarily prepped (via class 2 operation) -->
      <!-- Output: the same sources, selectively segmented -->
      <!-- Segmentation here means inserting into only those leaf <div>s that have been split a new <div type="#seg" ref="[ANCESTRAL @REF + ' #' + SEGMENT NUMBER]"> -->
      <xsl:param name="self-expanded-3" as="document-node()?"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:variable name="all-leaf-div-splits"
         select="$self-expanded-3/tan:TAN-A-div/tan:body/tan:split-leaf-div-at/tan:tok"/>
      <xsl:for-each select="$src-1st-da-tokenized">
         <xsl:variable name="this-src" select="/*/@src"/>
         <xsl:document>
            <!--<test><xsl:copy-of select="$all-leaf-div-splits[@src = $this-src]"/></test>-->
            <!--<test><xsl:value-of select="$this-src"/></test>-->
            <xsl:apply-templates mode="segment-tokd-prepped-class-1">
               <xsl:with-param name="all-leaf-div-splits" tunnel="yes"
                  select="$all-leaf-div-splits[@src = $this-src]"/>
            </xsl:apply-templates>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:template match="tan:div[tan:tok]" mode="segment-tokd-prepped-class-1">
      <xsl:param name="all-leaf-div-splits" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-div" select="."/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="splits-at" select="$all-leaf-div-splits[@ref = $this-ref]"/>
      <xsl:variable name="this-div-seg-starts"
         select="
            (1,
            for $i in $splits-at/@n
            return
               xs:integer($i))"
         as="xs:integer+"/>
      <xsl:variable name="duplicate-splits" select="tan:duplicate-values($this-div-seg-starts)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="splits-at" select="$splits-at/@n"/>
         <xsl:for-each-group select="*"
            group-by="max($this-div-seg-starts[. lt (count(current()/(self::tan:tok, preceding-sibling::tan:tok)) + 1)])">
            <xsl:variable name="pos" select="position()"/>
            <div type="#seg" n="{$pos}" ref="{concat($this-ref, ' #',string($pos))}">
               <xsl:if test="$splits-at/@n = '1' and $pos = 1">
                  <xsl:copy-of select="tan:error('spl03')"/>
               </xsl:if>
               <xsl:if test="current-grouping-key() = $duplicate-splits">
                  <xsl:copy-of
                     select="tan:error('spl02', concat('duplicate splits at token ', current-grouping-key()))"
                  />
               </xsl:if>
               <xsl:copy-of select="current-group()"/>
            </div>
         </xsl:for-each-group>
         <xsl:sequence select="tei:*"/>
      </xsl:copy>
   </xsl:template>
   

   <!-- STEP SRC-1ST-DA-REALIGNED: realign segmented source documents -->

   <xsl:function name="tan:merge-tan-a-div-prepped" as="document-node()*">
      <!-- shortened version of the fuller function, below -->
      <xsl:param name="tan-a-div-prepped" as="document-node()?"/>
      <xsl:param name="tan-a-div-sources-prepped" as="document-node()*"/>
      <xsl:param name="prioritize-source-order-over-conciseness" as="xs:boolean?"/>
      <!--<xsl:param name="proportionally-allocate-complex-realigns" as="xs:boolean?"/>-->
      <!--<xsl:param name="allocate-deeply" as="xs:boolean?"/>-->
      <!--<xsl:copy-of
         select="tan:merge-tan-a-div-prepped($tan-a-div-prepped, $tan-a-div-sources-prepped, $prioritize-source-order-over-conciseness, $proportionally-allocate-complex-realigns, $allocate-deeply, ())"
      />-->
      <xsl:copy-of
         select="tan:merge-tan-a-div-prepped($tan-a-div-prepped, $tan-a-div-sources-prepped, $prioritize-source-order-over-conciseness, ())"
      />
   </xsl:function>
   <xsl:function name="tan:merge-tan-a-div-prepped" as="document-node()*">
      <!-- Input: TAN-A-div prepped; its sources, prepped; a boolean indicating whether source order should be prioritized; an optional filter to pick only certain works -->
      <!-- Output: the TAN-A-div file, with the following changes: (a) one <work> per work chosen is placed after <body>; (b) each <work> contains a merger of the <div>s of all sources that contain that work; (c) @ref in <div>s in unanchored realignments are moved to @pre-realign-ref and @ref takes the @id value of the realignment; (d) @ref in <div>s in anchored realignments are moved to @pre-realign-ref and @ref takes the @ref of the anchor -->
      <!-- See tan:merge-source-loop() for more documentation -->
      <xsl:param name="tan-a-div-prepped" as="document-node()?"/>
      <xsl:param name="tan-a-div-sources-prepped" as="document-node()*"/>
      <xsl:param name="prioritize-source-order-over-conciseness" as="xs:boolean?"/>
      <!--<xsl:param name="proportionally-allocate-complex-realigns" as="xs:boolean?"/>-->
      <!--<xsl:param name="allocate-deeply" as="xs:boolean?"/>-->
      <xsl:param name="work-filter" as="xs:string?"/>
      <xsl:variable name="tan-a-div-sources-prepped-for-merge"
         select="tan:prep-tan-a-div-sources-for-merge($tan-a-div-prepped, $tan-a-div-sources-prepped)"
         as="document-node()*"/>
      <xsl:variable name="results-pass1" as="document-node()?">
         <!-- Goal: repopulate every <realign> and <align> with correctly realigned <div>s and <seg>s; add one or more <work>s after <body>, copying the topmost <div>s, except for realigned <div>s -->
         <xsl:document>
            <xsl:apply-templates select="$tan-a-div-prepped" mode="tan-a-div-merge-pass1">
               <xsl:with-param name="tan-a-div-sources-realigned"
                  select="$tan-a-div-sources-prepped-for-merge" tunnel="yes"/>
               <!--<xsl:with-param name="allocate-deeply"
                  select="
                     if ($proportionally-allocate-complex-realigns = true()) then
                        $allocate-deeply
                     else
                        ()"
                  tunnel="yes"/>-->
               <xsl:with-param name="work-filter" select="$work-filter" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:document>
      </xsl:variable>
      <!-- Jan 2017: pass 2 unnecessary now that realigns are all simple -->
      <!--<xsl:variable name="results-pass2" as="document-node()?">
         <!-\- Goal: integrate <realign>s into <work> structure: (1) unanchored realigns are copied as the last children of <work>; (2) anchored divs: find the anchors (i.e., <div>s under <work>) and copy, as next siblings, the realignments: if proportional distribution is false then in the appropriate place wholly copy simple realignments and leave merely a placeholder for complex ones; if it is true, then copy, as next siblings, the <realign> <div> with the corresponding @ref (accuracy was guaranteed in the previous step) -\->
         <xsl:document>
            <xsl:apply-templates select="$results-pass1" mode="tan-a-div-merge-pass2">
               <!-\-<xsl:with-param name="proportionally-allocate-complex-realigns"
                  select="$proportionally-allocate-complex-realigns" tunnel="yes"/>-\->
            </xsl:apply-templates>
         </xsl:document>
      </xsl:variable>-->
      <!-- Goal: complete the merge -->
      <xsl:variable name="results-pass3" as="document-node()?"
         select="
            tan:merge-source-loop($results-pass1, 1, false(), if ($prioritize-source-order-over-conciseness = true()) then
               $results-pass1/tan:TAN-A-div/tan:head/tan:source/@xml:id
            else
               ())"/>
      <xsl:variable name="results-cleaned-up">
         <xsl:document>
            <xsl:copy-of
               select="tan:copy-of-except($results-pass3, (), ('realign-head', 'string-pos', 'string-length'), ())"
            />
         </xsl:document>
      </xsl:variable>
      <!--<xsl:copy-of select="$tan-a-div-prepped"/>-->
      <!--<xsl:copy-of select="$tan-a-div-sources-prepped"/>-->
      <!--<xsl:copy-of select="$tan-a-div-sources-prepped-for-merge"/>-->
      <!--<xsl:copy-of select="$results-pass1"/>-->
      <!--<xsl:copy-of select="$results-pass2"/>-->
      <!--<xsl:copy-of select="$results-pass3"/>-->
      <xsl:copy-of select="$results-cleaned-up"/>
   </xsl:function>

   <xsl:function name="tan:prep-tan-a-div-sources-for-merge" as="document-node()*">
      <!-- Input: A TAN-A-div file that has reached at least level four of preparation (<realign> has @id); the sources of that TAN-A-div file, prepared -->
      <!-- Output: The sources, realigned. -->
      <!-- The function traverses each source, div by div via a template. If in a given source ($this-src) in a given div ($this-div) the ref ($this-ref) is found in the TAN-A-div's <realign> (in realign/div-ref/div/@ref), then if the realignment is anchored then the anchor's @ref is adopted. In an unanchored realignment, the id of the <realign>, e.g., #realign1-1, is adopted. Whether a simple or complex realignment, @pre-realign-ref is added with the old @ref, and @src is added (to anticipate merges between sources). Whether simple or complex, a realigned <div> passes on its new @ref value to its children, whose @ref values are revised accordingly. -->
      <xsl:param name="tan-a-div-prepped" as="document-node()?"/>
      <xsl:param name="src-1st-da-prepped-or-segmented" as="document-node()*"/>
      <xsl:for-each select="$src-1st-da-prepped-or-segmented">
         <xsl:document>
            <xsl:apply-templates mode="prepare-class-1-doc-for-merge">
               <xsl:with-param name="keep-text" select="true()" as="xs:boolean" tunnel="yes"/>
               <xsl:with-param name="tan-a-div-prepped" select="$tan-a-div-prepped" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>

   <xsl:template match="comment() | processing-instruction()"
      mode="tan-a-div-merge-pass1 process-splits drop-tokenization mark-splits-in-fragment">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="*"
      mode="tan-a-div-merge-pass1 process-splits drop-tokenization mark-splits-in-fragment">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:source" mode="tan-a-div-merge-pass1">
      <!-- We assume that the user of the resultant file wants little or no recourse to the original source files, so we add select metadata --> 
      <xsl:param name="tan-a-div-sources-realigned" tunnel="yes" as="document-node()*"/>
      <xsl:variable name="this-src" select="@xml:id"/>
      <xsl:variable name="this-src-doc" select="$tan-a-div-sources-realigned[*/@src = $this-src]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="node()"/>
         <!-- We add <body>, so as to be able to easily retrieve the language of the transcription of the source, important for reuse of a TAN-A-div file -->
         <body>
            <xsl:copy-of select="$this-src-doc/tan:TAN-T/tan:body/@*"/>
         </body>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:body" mode="tan-a-div-merge-pass1">
      <xsl:param name="tan-a-div-sources-realigned" tunnel="yes" as="document-node()*"/>
      <xsl:param name="work-filter" tunnel="yes" as="xs:string?"/>
      <xsl:variable name="this-work-filter"
         select="
            if (string-length($work-filter) lt 1) then
               '.+'
            else
               $work-filter"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
      <xsl:for-each
         select="
            tan:equate-works[(some $i in (tan:work/@src)
               satisfies matches($i, $this-work-filter))
            or string(count(preceding-sibling::tan:equate-works) + 1) = $this-work-filter]">
         <xsl:variable name="these-srcs" select="tan:work/@src"/>
         <work>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="$tan-a-div-sources-realigned/*[@src = $these-srcs]/tan:body/tan:div"/>
            <!--<xsl:for-each
               select="$tan-a-div-sources-realigned/*[@src = $these-srcs]/tan:body/tan:div">
               <!-\- Dec 2016: One of three sorts that need to be revisited -\->
               <!-\-<xsl:sort select="@r"/>-\->
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="tan:copy-of-except(node(), (), (), 'realign-head')"/>
               </xsl:copy>
            </xsl:for-each>-->
         </work>
      </xsl:for-each>
   </xsl:template>
   <!-- Jan 2016: slated for deletion; originally written with the concept of complex realigns in mind (many-to-many realignments that may not correspond one-to-one); those are reserved only for aligns; all realigns are simple -->
   <!--<xsl:template match="tan:realign" mode="tan-a-div-merge-pass1">
      <xsl:param name="allocate-deeply" tunnel="yes" as="xs:boolean?"/>
      <xsl:param name="tan-a-div-sources-realigned" tunnel="yes" as="document-node()*"/>
      <!-\- in an unanchored realignment, we treat the first <div-ref> as a proxy anchor -\->
      <xsl:variable name="this-anchor" select="(tan:anchor-div-ref, tan:div-ref)[1]" as="element()?"/>
      <xsl:variable name="new-anchor-divs"
         select="
            $tan-a-div-sources-realigned/tan:TAN-T[@src = $this-anchor/@src]/tan:body//tan:div[(@ref, @pre-realign-ref) = $this-anchor/tan:div/@ref]"/>
      <xsl:variable name="new-anchor-div-ref" as="element()">
         <xsl:element name="{name($this-anchor)}">
            <xsl:copy-of select="$this-anchor/@*"/>
            <xsl:for-each select="$new-anchor-divs">
               <xsl:copy-of select="$this-anchor/(* except tan:div)"/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="tan:copy-of-except(*, (), (), 'realign-head')"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:element>
      </xsl:variable>
      <xsl:variable name="new-div-refs" as="element()*">
         <xsl:for-each
            select="
               if (exists(tan:anchor-div-ref)) then
                  tan:div-ref
               else
                  tan:div-ref[position() gt 1]">
            <xsl:variable name="this-div-ref" select="."/>
            <xsl:variable name="these-new-divs-to-be-realigned"
               select="
                  $tan-a-div-sources-realigned/tan:TAN-T[@src = $this-div-ref/@src]/tan:body//tan:div[@pre-realign-ref = $this-div-ref/tan:div/@ref]"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="* except tan:div"/>
               <xsl:for-each select="$these-new-divs-to-be-realigned">
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:copy-of select="tan:copy-of-except(*, (), 'r', 'realign-head')"/>
                  </xsl:copy>
               </xsl:for-each>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="* except (tan:div-ref, tan:anchor-div-ref)"/>
         <xsl:if test="exists($this-anchor)">
            <xsl:copy-of select="$new-anchor-div-ref"/>
         </xsl:if>
         <xsl:for-each select="$new-div-refs">
            <xsl:variable name="is-complex"
               select="count($new-anchor-div-ref/*) gt 1 or count(*) gt 1"/>
            <xsl:choose>
               <xsl:when test="$is-complex = true()">
                  <xsl:copy-of
                     select="tan:reanchor-div-ref(., $new-anchor-div-ref, $allocate-deeply)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>

      </xsl:copy>
   </xsl:template>-->
   
   <!-- Jan 2016: slated for deletion or massive reduction, since alignments have no (?) effect on merges -->
   <!--<xsl:template match="tan:align" mode="tan-a-div-merge-pass1">
      <!-\- We repeat the align for as many groups of <div-ref>s, treating each one in turn as an <anchor-div>, then applying the same approach to <realign> -\->
      <!-\-<xsl:param name="allocate-deeply" tunnel="yes" as="xs:boolean?"/>-\->
      <xsl:param name="tan-a-div-sources-realigned" tunnel="yes" as="document-node()*"/>
      <xsl:variable name="this-align" select="."/>
      <xsl:variable name="div-refs-repopulated" as="element()*">
         <xsl:for-each select="tan:div-ref">
            <xsl:variable name="this-div-ref" select="."/>
            <xsl:variable name="new-divs"
               select="
                  $tan-a-div-sources-realigned/tan:TAN-T[@src = $this-div-ref/@src]/tan:body//tan:div[(@ref, @pre-realign-ref) = $this-div-ref/tan:div/@ref]"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <!-\-<xsl:copy-of select="* except tan:div"/>-\->
               <xsl:copy-of
                  select="tan:copy-of-except($new-divs, ('error', 'warning', 'info', 'fatal'), (), 'realign-head')"
               />
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="exists(@topic)">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$div-refs-repopulated"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:for-each-group select="$div-refs-repopulated" group-by="@group">
               <xsl:variable name="this-group" select="current-grouping-key()"/>
               <xsl:variable name="pos" select="position()"/>
               <xsl:variable name="this-div-ref" as="element()*"
                  select="
                     current-group()[if (exists(@work)) then
                        (@work = @src)
                     else
                        true()]"/>
               <align>
                  <xsl:copy-of select="$this-align/@*"/>
                  <xsl:if test="$pos = 1">
                     <xsl:copy-of select="$this-align/(* except tan:div-ref)"/>
                  </xsl:if>
                  <xsl:variable name="this-anchor" as="element()">
                     <anchor-div-ref>
                        <xsl:copy-of select="$this-div-ref/@*"/>
                        <xsl:copy-of select="$this-div-ref/node()"/>
                     </anchor-div-ref>
                  </xsl:variable>
                  <xsl:copy-of select="$this-anchor"/>
                  <xsl:for-each select="$div-refs-repopulated[not(@group = $this-group)]">
                     <xsl:copy-of select="tan:remodel-div-ref(., $this-anchor, $allocate-deeply)"/>
                  </xsl:for-each>
               </align>
            </xsl:for-each-group>
         </xsl:otherwise></xsl:choose>
   </xsl:template>-->

   <!-- Jan 2017: tan-a-div-merge-pass2 is not needed, now that realigns are all simple -->
   <!--<xsl:template match="tan:head | tan:body" mode="tan-a-div-merge-pass2">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tan:work" mode="tan-a-div-merge-pass2">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:copy-of select="/tan:TAN-A-div/tan:body/tan:realign[not(tan:anchor-div-ref)]"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div" mode="tan-a-div-merge-pass2">
      <!-\-<xsl:param name="complex-realignments" tunnel="yes"/>-\->
      <xsl:param name="proportionally-allocate-complex-realigns" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="this-src" select="@src"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="this-n" select="@n"/>
      <xsl:variable name="these-realign-head-anchors"
         select="/tan:TAN-A-div/tan:body/tan:realign/tan:anchor-div-ref/tan:div[@src = $this-src and @ref = $this-ref]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
      <xsl:for-each select="$these-realign-head-anchors">
         <xsl:variable name="this-realign" select="ancestor::tan:realign"/>
         <xsl:choose>
            <xsl:when test="$proportionally-allocate-complex-realigns = true()">
               <xsl:variable name="this-realign-head-pos"
                  select="count(preceding-sibling::tan:div) + 1"/>
               <xsl:for-each select="$this-realign/tan:div-ref">
                  <xsl:copy-of select="tan:div[$this-realign-head-pos]"/>
                  <!-\-<div ref="{$this-ref}" src="{@src}">
                     <xsl:copy-of select="*[$this-realign-head-pos]/*"/>
                  </div>-\->
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="anchor-count" select="count(../tan:div)"/>
               <xsl:for-each select="$this-realign/tan:div-ref">
                  <xsl:choose>
                     <xsl:when test="$anchor-count = 1 and count(tan:div) = 1">
                        <xsl:copy-of select="tan:div"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <div ref="{$this-ref}" src="{@src}">
                           <realignment which="{$this-realign/@id}"/></div>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>-->

   <!-- PROCESSING COMPLEX REALIGNMENTS -->
   <xsl:function name="tan:remodel-div-ref" as="element()?">
      <!-- Input: (1) a <div-ref> containing one or more <div>s of unknown complexity, to be fused into (2) another <div-ref> or <anchor-div-ref> containing a <div>structure to be treated as a structural model of the first; a boolean indicating whether allocation should be shallow (top-level <div> only) or deep -->
      <!-- Output: the deep or shallow element structure of (2), but with the text of each leaf div being replaced by the proportionally appropriate leaf divs (fragmentary or whole) of (1); in that structure, all copies of (2)'s attributes are retained, except for @src, which is replaced by the value of @src in (1) -->
      <!-- This function is written for proportional realignments -->
      <xsl:param name="div-ref-to-remodel" as="element(tan:div-ref)?"/>
      <xsl:param name="model-div-ref" as="element()?"/>
      <xsl:param name="allocate-deeply" as="xs:boolean?"/>
      <xsl:variable name="model-prepped"
         select="tan:analyze-string-length($model-div-ref, false())"/>
      <xsl:variable name="model-length" select="sum($model-prepped/*/@string-length)"/>
      <xsl:variable name="model-divs-to-be-used"
         select="
            if ($allocate-deeply = true()) then
               ($model-prepped//tan:div[not(tan:div)])[position() gt 1]
            else
               $model-prepped/tan:div[position() gt 1]"/>
      <xsl:variable name="model-splits-at"
         select="
            for $i in $model-divs-to-be-used
            return
               $i/@string-pos div $model-length"/>
      <xsl:variable name="clay-tokenized" as="element()*">
         <xsl:apply-templates select="$div-ref-to-remodel" mode="tokenize-prepped-class-1">
            <xsl:with-param name="token-definition" select="$tokenization-nonspace" tunnel="yes"/>
            <xsl:with-param name="keep-copy-of-tei-elements" select="false()" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:variable name="clay-analyzed" select="tan:analyze-string-length($clay-tokenized)"/>
      <xsl:variable name="clay-length" select="sum($clay-analyzed/*/@string-length)"/>
      <xsl:variable name="clay-splits-at"
         select="
            for $i in $model-splits-at
            return
               ceiling($i * $clay-length)"/>
      <xsl:variable name="clean-clay-splits"
         select="
            for $i in $clay-splits-at
            return
               ($clay-analyzed//*[number(@string-pos) ge $i])[1]/@string-pos"/>
      <xsl:variable name="clay-splits-marked" as="element()?">
         <xsl:apply-templates select="$clay-analyzed" mode="mark-splits-in-fragment">
            <xsl:with-param name="put-split-before-element-with-what-attr-string-pos"
               select="$clean-clay-splits" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:variable name="clay-splits-made" select="tan:process-splits($clay-splits-marked)"/>
      <xsl:variable name="div-ref-reanchored" as="element()*">
         <div-ref>
            <xsl:copy-of select="$div-ref-to-remodel/@*"/>
            <xsl:apply-templates select="$model-prepped/*" mode="infuse-tokenized-div">
               <xsl:with-param name="div-clay-tokenized" select="$clay-splits-made" tunnel="yes"/>
               <xsl:with-param name="infuse-deeply" select="$allocate-deeply" tunnel="yes"/>
            </xsl:apply-templates>
         </div-ref>
      </xsl:variable>
      <!-- diagnostics, results -->
      <!--<xsl:copy-of select="$div-ref-to-reanchor"/>-->
      <!--<xsl:copy-of select="$model-prepped"/>-->
      <!--<test><xsl:copy-of select="$model-divs-to-be-used"/></test>-->
      <!--<test><xsl:copy-of select="$model-length"/></test>-->
      <!--<test><xsl:copy-of select="$model-splits-at"/></test>-->
      <!--<xsl:copy-of select="tan:analyze-string-length($div-ref-to-reanchor, false())"/>-->
      <!--<xsl:copy-of select="$clay-tokenized"/>-->
      <!--<xsl:copy-of select="$clay-analyzed"/>-->
      <!--<test><xsl:copy-of select="$clay-length"/></test>-->
      <!--<test><xsl:copy-of select="$clay-splits-at"/></test>-->
      <!--<xsl:copy-of select="$clay-splits-marked"/>-->
      <!--<test><xsl:copy-of select="$clay-splits-made"/></test>-->
      <xsl:copy-of select="$div-ref-reanchored"/>
   </xsl:function>

   <xsl:function name="tan:process-splits" as="element()*">
      <!-- Input: any document fragment with <split/> inserted in leaf elements representing where there should be a deep, top-level split -->
      <!-- Output: A sequence of <fragment>s (the number of <split/>s plus one containing a deep copy of the fragment chosen -->
      <xsl:param name="elements-to-process"/>
      <xsl:choose>
         <xsl:when test="not(exists($elements-to-process//tan:split))">
            <!--<xsl:copy-of select="$elements-to-process"/>-->
            <xsl:for-each-group select="$elements-to-process" group-adjacent="name()">
               <xsl:if test="not(current-group()/self::tan:split)">
                  <fragment>
                     <xsl:copy-of select="current-group()"/>
                  </fragment>
               </xsl:if>
            </xsl:for-each-group>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="next-step" as="element()*">
               <xsl:apply-templates select="$elements-to-process" mode="process-splits"/>
            </xsl:variable>
            <xsl:copy-of select="tan:process-splits($next-step)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:template match="*[tan:split]" mode="process-splits">
      <xsl:variable name="this-element" select="."/>
      <xsl:for-each-group select="*" group-starting-with="tan:split">
         <xsl:copy-of select="current-group()/self::tan:split"/>
         <xsl:element name="{name($this-element)}">
            <xsl:copy-of select="$this-element/@*"/>
            <xsl:copy-of select="current-group()[not(self::tan:split)]"/>
         </xsl:element>
      </xsl:for-each-group>
   </xsl:template>

   <xsl:template match="*[@string-pos]" mode="mark-splits-in-fragment">
      <xsl:param name="put-split-before-element-with-what-attr-string-pos" tunnel="yes"/>
      <xsl:variable name="these-matches"
         select="index-of($put-split-before-element-with-what-attr-string-pos, @string-pos)"/>
      <xsl:if
         test="count($these-matches) gt 0 and not(ancestor::*/@string-pos = $put-split-before-element-with-what-attr-string-pos)">
         <split n="{$these-matches}"/>
      </xsl:if>
      <!--<test><xsl:copy-of select="$put-split-before-element-with-what-attr-string-pos"/></test>-->
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*" mode="split-marked-fragment">
      <xsl:param name="after-split-no" as="xs:integer?" tunnel="yes"/>
      <xsl:param name="before-split-no" as="xs:integer?" tunnel="yes"/>
      <xsl:variable name="child-left-marker" select="tan:split[@n = $after-split-no]"/>
      <xsl:variable name="child-right-marker" select="tan:split[@n = $after-split-no]"/>
      <xsl:variable name="descendant-left-marker"
         select="*/descendant::tan:split[@n = $after-split-no]"/>
      <xsl:variable name="descendant-right-marker"
         select="*/descendant::tan:split[@n = $after-split-no]"/>
      <xsl:choose>
         <xsl:when test="true()">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of
                  select="tan:split[@n = $before-split-no]/preceding-sibling::* except tan:split[@n = $after-split-no]/(self::*, preceding-sibling::*)"
               />
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise> </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="*[tan:tok or tan:non-tok]" mode="drop-tokenization">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="normalize-space(.)"/>
      </xsl:copy>
   </xsl:template>


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
         select="(self::*, root(current())/tan:TAN-T/tan:body//tan:div[matches(@ref, concat('^', $this-ref, ' '))])[tan:div[@type = '#seg'], tan:tok]"/>
      <xsl:variable name="tok-qty-per-leaf-div"
         select="
            if (exists($leaf-divs)) then
               for $i in descendant-or-self::*[tan:tok, tan:non-tok]
               return
                  count($i/tan:tok)
            else
               0"/>
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
