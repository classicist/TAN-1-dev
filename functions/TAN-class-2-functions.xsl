<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>April 14, 2016</xd:p>
         <xd:p>Core variables and functions for class 2 TAN files (i.e., applicable to multiple
            class 2 TAN file types). Written principally for Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="TAN-core-functions.xsl"/>

   <xsl:key name="div-via-ref" match="tan:div" use="@ref"/>

   <!-- PART I.
      GLOBAL VARIABLES AND PARAMETERS -->
   <!-- Source picking and identification -->
   <xsl:param name="sources-picked" select="$src-count" as="xs:integer*"/>
   <xsl:variable name="source-lacks-id"
      select="
         if ($head/tan:source/@xml:id) then
            false()
         else
            true()"/>
   <xsl:variable name="src-count" select="1 to count($head/tan:source)" as="xs:integer+"/>

   <!-- Searches -->
   <xsl:param name="searches-ignore-accents" select="true()" as="xs:boolean"/>
   <xsl:param name="searches-are-case-sensitive" select="false()" as="xs:boolean"/>
   <xsl:variable name="match-flags"
      select="
         if ($searches-are-case-sensitive = true()) then
            ()
         else
            'i'"
      as="xs:string?"/>
   <xsl:param name="searches-suppress-what-text" as="xs:string?" select="'[\p{M}]'"/>

   <!-- Source transformation -->
   <!-- When fetching src-1st-da-prepped, should each tan:div have included a @type-eq that converts the @type
      to its numerical equivalence, based on the TAN-A-div's //tan:group[tan:div-type]? Oftentimes this step is unnecessary.-->
   <xsl:param name="fetch-type-eq" as="xs:boolean" select="false()"/>


   <!-- PART II.
      PROCESSING SOURCE DOCUMENTS -->

   <!-- Class 2 files are expanded in tandem with their underlying source files.
      Each transformation results in a document node, conducted in a sequence of steps:
      TAN-class-2        TAN-class-1           Comments   
      ===========        ===========           ===============================
      self-expanded-1                          Expand @src (but not for <equate-works>), @div-type-ref; normalize @ref; add @xml:id to TAN-LM <source>; add @group to elements that take @cont
                         src-1st-da            Get first document available for each source chosen
                         src-1st-da-resolved   Resolve each source document: add @src to root element, get inclusions, keywords, strip duplicates
      self-expanded-2                          Expand <token-definition> and (TAN-A-div) <equate-works>, <equate-div-types>
                         src-1st-da-prepped    Add @work to each root element, rename @ns, suppress div types, replace div types with numerical equivalent
      self-expanded-3                          Expand @ref for <tok>, <div-ref>, <anchor-div-ref>
                         src-1st-da-tokenized  Tokenize using the default token definitions
      self-expanded-4                          Expand @val, @pos for <tok>
      
      Each specific class-2 file admits further transformations. See the appropriate function
      spreadsheet for more information.
   -->

   <!-- STEP SELF-EXPANDED-1: First expansion of class-2 file: expand @src, @div-type-ref; add @src to <source> in TAN-LM file; start <equate-work> expansion -->
   <xsl:function name="tan:get-self-expanded-1" as="document-node()?">
      <xsl:document>
         <xsl:apply-templates mode="self-expanded-1" select="$self-resolved"/>
      </xsl:document>
   </xsl:function>
   <xsl:function name="tan:get-self-expanded-1" as="document-node()?">
      <xsl:param name="leave-breadcrumbs" as="xs:boolean"/>
      <xsl:variable name="self-breadcrumbed" select="tan:resolve-doc($root, (), true())"/>
      <xsl:document>
         <xsl:apply-templates mode="self-expanded-1" select="$self-breadcrumbed"/>
      </xsl:document>
   </xsl:function>
   <xsl:function name="tan:get-self-expanded-1" as="document-node()*">
      <xsl:param name="tan-doc" as="document-node()*"/>
      <xsl:param name="leave-breadcrumbs" as="xs:boolean"/>
      <xsl:for-each select="$tan-doc">
         <xsl:variable name="self-breadcrumbed"
            select="
               if (/*/@base-uri) then
                  .
               else
                  tan:resolve-doc(., (), $leave-breadcrumbs)"
            as="document-node()"/>
         <xsl:document>
            <xsl:apply-templates mode="self-expanded-1" select="$self-breadcrumbed"/>
         </xsl:document>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="self-expanded-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:source[not(@xml:id)]" mode="self-expanded-1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="xml:id" select="count(preceding-sibling::tan:source) + 1"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:equate-works" mode="self-expanded-1">
      <!-- <equate-works> doesn't get expanded, since the grouped @src refs are already what's needed for later changes -->
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template
      match="tan:anchor-div-ref | tan:div-ref | tan:div-type-ref | tan:rename-div-ns | tan:suppress-div-types | tan:tok | tan:token-definition"
      mode="self-expanded-1">
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-element-name" select="name($this-element)"/>
      <xsl:variable name="srcs-pass-1" select="tokenize(tan:normalize-text(@src), '\s+')"/>
      <xsl:variable name="these-sources"
         select="
            if ($srcs-pass-1 = '*') then
               $src-ids
            else
               $srcs-pass-1"/>
      <xsl:variable name="these-div-types"
         select="tokenize(tan:normalize-text(@div-type-ref), '\W+')"/>
      <xsl:for-each
         select="
            if (exists($these-sources)) then
               $these-sources
            else
               (root()/*/@src, 1)[1]">
         <xsl:variable name="this-src" select="."/>
         <xsl:for-each
            select="
               if (exists($these-div-types)) then
                  $these-div-types
               else
                  1">
            <xsl:element name="{$this-element-name}">
               <xsl:copy-of select="$this-element/@*"/>
               <xsl:if test="exists($this-element/@ref)">
                  <xsl:attribute name="ref" select="tan:normalize-refs($this-element/@ref)"/>
               </xsl:if>
               <xsl:attribute name="src" select="$this-src"/>
               <xsl:if test="exists($these-div-types)">
                  <xsl:attribute name="div-type-ref" select="."/>
               </xsl:if>
               <xsl:if test="$this-element-name = ('anchor-div-ref', 'div-ref', 'tok')">
                  <xsl:attribute name="group"
                     select="count($this-element/preceding-sibling::*[not(@cont)]) + 1"/>
               </xsl:if>
               <xsl:copy-of select="$this-element/node()"/>
            </xsl:element>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:template>

   <!-- Results of step -->
   <xsl:variable name="src-elements" select="$head/tan:source"/>
   <xsl:variable name="src-ids"
      select="
         if ($src-elements/@xml:id) then
            $src-elements/@xml:id
         else
            '1'"
      as="xs:string+"/>

   <!-- Resultant functions -->
   <xsl:function name="tan:expand-src-and-div-type-ref" as="element()*">
      <xsl:param name="elements-with-src-and-div-type" as="element()*"/>
      <xsl:apply-templates mode="self-expanded-1" select="$elements-with-src-and-div-type"/>
   </xsl:function>
   <xsl:function name="tan:normalize-refs" as="xs:string?">
      <!-- Input: string value of @ref that explicitly uses div types
         Output: punctuation- and space-normalized reference string
         E.g., "Gen 1:epigraph   , Gen:4,5   - Gen 7" -> "Gen 1 epigraph , Gen 4 5 - Gen 7" 
      -->
      <xsl:param name="raw-ref" as="xs:string?"/>
      <xsl:variable name="norm-ref" select="tan:normalize-text($raw-ref)"/>
      <xsl:value-of
         select="
            string-join(for $i in tokenize($norm-ref, '\s*,\s+')
            return
               string-join(for $j in tokenize($i, '\s+-\s+')
               return
                  replace($j, '\W+', $separator-hierarchy), ' - '), ' , ')"
      />
   </xsl:function>

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

   <!-- STEP SRC-1ST-DA-RESOLVED: Resolve source documents -->
   <xsl:function name="tan:get-src-1st-da-resolved" xml:id="v-src-1st-da-resolved">
      <!-- zero-parameter version of the next function -->
      <xsl:copy-of select="tan:get-src-1st-da-resolved(tan:get-src-1st-da(), $src-ids)"/>
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-resolved">
      <xsl:param name="picked-class-1-docs" as="document-node()*"/>
      <xsl:param name="picked-src-ids" as="xs:string*"/>
      <xsl:copy-of select="tan:resolve-doc($picked-class-1-docs, $picked-src-ids, false())"/>
   </xsl:function>

   <!-- resultant functions -->
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

   <!-- STEP SELF-EXPANDED-2: expand class-2 file to fully expand <equate-works>, <equate-div-types>, <token-definition> -->

   <xsl:function name="tan:get-self-expanded-2">
      <!-- zero parameter function of the next -->
      <xsl:variable name="self-expanded-1" select="tan:get-self-expanded-1()"/>
      <xsl:copy-of select="tan:get-self-expanded-2($self-expanded-1, tan:get-src-1st-da-resolved())"
      />
   </xsl:function>
   <xsl:function name="tan:get-self-expanded-2" as="document-node()?">
      <xsl:param name="self-expanded-1" as="document-node()?"/>
      <xsl:param name="src-1st-da-resolved" as="document-node()*"/>
      <xsl:variable name="token-definitions"
         select="tan:get-token-definitions-per-source($self-expanded-1, $src-1st-da-resolved)"
         as="element()*"/>
      <xsl:variable name="TAN-LM-expansions"
         select="tan:get-div-type-equivalents($self-expanded-1, $src-1st-da-resolved)"/>
      <xsl:variable name="TAN-A-div-expansions"
         select="
            tan:get-work-equivalents($self-expanded-1, $src-1st-da-resolved),
            tan:get-div-type-equivalents($self-expanded-1, $src-1st-da-resolved)"/>
      <xsl:document>
         <xsl:apply-templates mode="self-expanded-2" select="$self-expanded-1">
            <xsl:with-param name="token-definitions" select="$token-definitions"/>
            <xsl:with-param name="body-expansions" select="$TAN-A-div-expansions"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="node()" mode="self-expanded-2">
      <xsl:param name="token-definitions" as="element()*"/>
      <xsl:param name="body-expansions" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="token-definitions" select="$token-definitions"/>
            <xsl:with-param name="body-expansions" select="$body-expansions"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:declarations" mode="self-expanded-2">
      <xsl:param name="token-definitions" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$token-definitions"/>
         <xsl:apply-templates mode="#current" select="*[not(self::tan:token-definition)]"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:TAN-A-div/tan:body" mode="self-expanded-2">
      <xsl:param name="body-expansions" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$body-expansions"/>
         <xsl:copy-of select="*[not(self::tan:equate-works | self::tan:equate-div-types)]"/>
      </xsl:copy>
   </xsl:template>

   <!-- Functions for step -->
   <xsl:function name="tan:group-by-IRIs" as="element()*">
      <xsl:param name="elements-with-IRI-children" as="element()*"/>
      <xsl:variable name="first-group" as="element()">
         <group n="1">
            <xsl:copy-of select="$elements-with-IRI-children[1]"/>
         </group>
      </xsl:variable>
      <xsl:copy-of
         select="tan:group-by-IRIs($first-group, $elements-with-IRI-children[position() gt 1])"/>
   </xsl:function>
   <xsl:function name="tan:group-by-IRIs" as="element()*">
      <xsl:param name="group-to-check" as="element()"/>
      <xsl:param name="items-to-group" as="element()*"/>
      <xsl:variable name="this-n" select="xs:integer($group-to-check/@n)" as="xs:integer"/>
      <xsl:variable name="these-IRIs" select="$group-to-check/*/tan:IRI"/>
      <xsl:variable name="matches" select="$items-to-group[tan:IRI = $these-IRIs]"/>
      <xsl:variable name="new-group" as="element()">
         <xsl:for-each select="$group-to-check">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="*"/>
               <xsl:copy-of select="$matches"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="new-items-to-group" select="$items-to-group except $matches"/>
      <xsl:choose>
         <xsl:when test="not(exists($new-items-to-group)) or count($items-to-group) lt 1">
            <xsl:copy-of select="$new-group"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:choose>
               <xsl:when test="exists($matches)">
                  <xsl:copy-of select="tan:group-by-IRIs($new-group, $new-items-to-group)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="$new-group"/>
                  <xsl:variable name="next-group" as="element()">
                     <group n="{$this-n + 1}">
                        <xsl:copy-of select="$new-items-to-group[1]"/>
                     </group>
                  </xsl:variable>
                  <xsl:variable name="next-items" select="$new-items-to-group[position() gt 1]"/>
                  <xsl:copy-of select="tan:group-by-IRIs($next-group, $next-items)"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:regroup-work-or-div-types-from-equate-elements" as="element()*">
      <!-- This function, for TAN-A-div files, takes the default grouping of works and
      div-types and regroups them according to the <equate...>s made in the TAN-A-div file.
      Input: (1) <div-type> or <work> elements pulled from the source files and grouped using tan:group-by-IRIs()
      (2) <equate-works> or <equate-div-types> from the host TAN-A-div file
      Output: Reconfiguration of (1), lumping together groups that are explicitly equated. If an
      item is equated more than once, or if items that are already equivalent are equated, the 
      appropriate error will be returned as @err-equ01 or @err-equ02
      -->
      <xsl:param name="work-or-div-type-groups" as="element()+"/>
      <xsl:param name="equate-elements" as="element()*"/>
      <xsl:variable name="pass-1" as="element()*">
         <xsl:for-each select="$equate-elements">
            <equate n="{position()}">
               <xsl:choose>
                  <xsl:when test="self::tan:equate-works">
                     <xsl:for-each select="tokenize(tan:normalize-text(@src), ' ')">
                        <xsl:variable name="this-src" select="."/>
                        <IRI group="">
                           <xsl:value-of
                              select="$work-or-div-type-groups[tan:work/@src = $this-src]/@n"/>
                        </IRI>
                     </xsl:for-each>
                  </xsl:when>
                  <xsl:when test="self::tan:equate-div-types">
                     <xsl:for-each select="tan:div-type-ref">
                        <xsl:variable name="this-src" select="@src"/>
                        <xsl:variable name="this-div-type" select="@div-type-ref"/>
                        <IRI group="">
                           <xsl:value-of
                              select="
                                 $work-or-div-type-groups[tan:div-type[@src = $this-src and
                                 @xml:id = $this-div-type]]/@n"
                           />
                        </IRI>
                     </xsl:for-each>
                  </xsl:when>
               </xsl:choose>
            </equate>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="pass-2" select="tan:group-by-IRIs($pass-1)"/>
      <xsl:for-each
         select="$work-or-div-type-groups[not(@n = $pass-2//tan:IRI) or @n = $pass-2/*[1]/tan:IRI[1]]">
         <xsl:variable name="this-work-group" select="."/>
         <xsl:variable name="pos" select="position()"/>
         <xsl:variable name="equate-group" select="$pass-2[*/tan:IRI = $this-work-group/@n]"/>
         <group n="{$pos}">
            <xsl:choose>
               <xsl:when test="exists($equate-group)">
                  <xsl:variable name="redundancies"
                     select="
                        for $i in $equate-group/*
                        return
                           tan:duplicate-values($i/tan:IRI)"/>
                  <xsl:variable name="multiply-regrouped"
                     select="$equate-group/*/tan:IRI[. = ../preceding-sibling::*/tan:IRI]"/>
                  <xsl:variable name="work-groups-picked" select="$equate-group//tan:IRI"/>
                  <xsl:if test="exists($redundancies)">
                     <xsl:attribute name="err-equ01" select="$redundancies"/>
                  </xsl:if>
                  <xsl:if test="exists($multiply-regrouped)">
                     <xsl:attribute name="err-equ02" select="$multiply-regrouped"/>
                  </xsl:if>
                  <xsl:for-each select="$work-or-div-type-groups[@n = $work-groups-picked]/*">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:for-each select="*">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:otherwise>
            </xsl:choose>
         </group>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:get-src-ids" as="xs:string*">
      <!-- Input: class 2 document and its putative class 1 sources as documents
      Output: src @xml:id values; if there is no @xml:id then '1' is returned (useful for
      TAN-LM files) -->
      <xsl:param name="class-2-doc" as="document-node()?"/>
      <xsl:param name="class-1-docs" as="document-node()*"/>
      <xsl:variable name="these-tan-ids" select="$class-1-docs/*/@id"/>
      <xsl:for-each select="$these-tan-ids">
         <xsl:copy-of
            select="($class-2-doc/*/tan:head/tan:source[tan:IRI = current()]/@xml:id, '1')[1]"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:get-token-definitions-per-source" as="element()*">
      <!-- Sequence of one <token-definition> per source, chosen by whichever comes first:
         1. <token-definition> in the originating class-2 file;
         2. <token-definition> in the source file;
         3. The pre-set general <token-definition> (letters only)
      -->
      <xsl:param name="self-expanded-1" as="document-node()?"/>
      <xsl:param name="src-1st-da-resolved" as="document-node()*"/>
      <xsl:variable name="these-src-ids"
         select="tan:get-src-ids($self-expanded-1, $src-1st-da-resolved)"/>
      <xsl:for-each select="$these-src-ids">
         <xsl:variable name="pos" select="position()"/>
         <xsl:variable name="this-src-id" select="."/>
         <xsl:variable name="selfs-first-token-definition"
            select="
               $self-expanded-1/*/tan:head/tan:declarations/tan:token-definition[if (@src) then
                  (tokenize(@src, '\s+') = $this-src-id)
               else
                  true()][1]"/>
         <xsl:variable name="sources-first-token-definition"
            select="$src-1st-da-resolved[$pos]/*/tan:head/tan:declarations/tan:token-definition[1]"/>
         <xsl:for-each
            select="($selfs-first-token-definition, $sources-first-token-definition, $token-definitions-reserved)[1]">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="src" select="$this-src-id"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:get-work-equivalents" as="element()+">
      <!-- returns a sequence of <group>s, one per work, containing one <work @src="[IDREF]"> per source
         that is calculated to be part of the group of works. Errors set as @err-eqw01 and @err-eqw02 in <group> -->
      <xsl:param name="self-expanded-1" as="document-node()?"/>
      <xsl:param name="src-1st-da-resolved" as="document-node()*"/>
      <xsl:variable name="these-works"
         select="tan:extract-src-elements($src-1st-da-resolved/*/tan:head/tan:declarations/tan:work)"/>
      <xsl:variable name="these-works-grouped" select="tan:group-by-IRIs($these-works)"/>
      <xsl:variable name="these-equate-works"
         select="$self-expanded-1/tan:TAN-A-div/tan:body/tan:equate-works"/>
      <xsl:copy-of
         select="tan:regroup-work-or-div-types-from-equate-elements($these-works-grouped, $these-equate-works)"
      />
   </xsl:function>

   <xsl:function name="tan:get-div-type-equivalents" as="element()*">
      <!-- returns a sequence of <group>s, one per div-type, containing one <div-type @xml:id="[IDREF]" @src="[IDREF]"> per div-type per source
         that is calculated to be part of the group of div types. Errors set as @err-eqw01 and @err-eqw02 in <group> -->
      <xsl:param name="self-expanded-1" as="document-node()?"/>
      <xsl:param name="src-1st-da-resolved" as="document-node()*"/>
      <xsl:variable name="all-div-types"
         select="tan:extract-src-elements($src-1st-da-resolved/*/tan:head/tan:declarations/tan:div-type)"/>
      <xsl:variable name="all-div-types-grouped" select="tan:group-by-IRIs($all-div-types)"/>
      <xsl:variable name="equate-div-types"
         select="$self-expanded-1/tan:TAN-A-div/tan:body/tan:equate-div-types"/>
      <xsl:copy-of
         select="tan:regroup-work-or-div-types-from-equate-elements($all-div-types-grouped, $equate-div-types)"
      />
   </xsl:function>

   <!-- STEP SRC-1ST-DA-PREPPED: add to source documents work id, renamed ns, suppressed div types -->
   <xsl:function name="tan:get-src-1st-da-prepped" as="document-node()*">
      <!-- zero-parameter version of the next function -->
      <xsl:copy-of
         select="tan:get-src-1st-da-prepped(tan:get-self-expanded-2(), tan:get-src-1st-da-resolved())"
      />
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-prepped" as="document-node()*">
      <!-- Input: sequence of flattened class 1 TAN documents 
         Output: sequence of documents with these changes:
         /*   - >   @work="[DIGIT DRAWN FROM TAN-A-div //tan:group[tan:work]/@id]"
         tei:TEI - > tan:TAN-T
         tei:text/tei:body   - >   tan:body
         tei:div  - >  tan:div
         <div [copy of @*] @ref="[NORMALIZED, FLATTENED REF WITH N 
         SUBSTITUTIONS AND SUPPRESSIONS]">[COPY OF CONTENT, INCLUDING TEI MARKUP, IF ANY]</div>
         Text remains untokenized.
      -->
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <xsl:param name="resolved-class-1-documents" as="document-node()*"/>
      <xsl:for-each select="$resolved-class-1-documents">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:variable name="pos" select="position()"/>
         <xsl:copy>
            <xsl:apply-templates mode="prep-class-1" select="node()">
               <xsl:with-param name="key-to-this-src"
                  select="
                     $self-expanded-2/*/(tan:head/tan:declarations/tan:*[@src = $this-src],
                     tan:body)"
               />
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="prep-class-1">
      <xsl:param name="key-to-this-src" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:TAN-T | tei:TEI" mode="prep-class-1">
      <!-- Homogenize tei:TEI to tan:TAN-T -->
      <xsl:param name="key-to-this-src" as="element()*"/>
      <xsl:variable name="src-id" select="@src"/>
      <TAN-T>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="work"
            select="($key-to-this-src/tan:group[tan:work/@src = $src-id]/@n, 1)[1]"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
         </xsl:apply-templates>
      </TAN-T>
   </xsl:template>
   <xsl:template match="tei:body" mode="prep-class-1">
      <xsl:param name="key-to-this-src" as="element()*"/>
      <body>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
         </xsl:apply-templates>
      </body>
   </xsl:template>
   <xsl:template match="tei:text" mode="prep-class-1">
      <!-- Makes sure the tei:body drops rootward one level, as is customary in TAN and HTML -->
      <xsl:param name="key-to-this-src" as="element()*"/>
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tan:div | tei:div" mode="prep-class-1" xml:id="t-prep-class-1-data">
      <xsl:param name="key-to-this-src" as="element()*"/>
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
            <!-- Homogenize tei:body element to tan:body -->
            <div>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="ref" select="$new-ref"/>
               <xsl:if test="not($orig-ref = $new-ref)">
                  <xsl:attribute name="orig-ref" select="$orig-ref"/>
               </xsl:if>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="key-to-this-src" select="$key-to-this-src"/>
               </xsl:apply-templates>
            </div>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- Interlude: chance to get a proper subset of the prepped files -->
   <!-- tan:pick-prepped-class-1-data() presumes that you want only some divs -->
   <xsl:function name="tan:pick-prepped-class-1-data" as="document-node()*">
      <!-- 1-param function of the 2-param version below -->
      <xsl:param name="elements-with-atomic-src-and-ref-attributes" as="element()*"/>
      <xsl:variable name="src-1st-da-prepped" select="tan:get-src-1st-da-prepped()"/>
      <xsl:copy-of
         select="tan:pick-prepped-class-1-data($elements-with-atomic-src-and-ref-attributes, $src-1st-da-prepped, false())"
      />
   </xsl:function>
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
                           <errors>
                              <xsl:copy-of select="$erroneous-refs"/>
                           </errors>
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
   <xsl:function name="tan:cull-prepped-class-1-data" as="document-node()*">
      <!-- 1-param function of the 2-param version below -->
      <xsl:param name="elements-with-atomic-src-and-ref-attributes" as="element()*"/>
      <xsl:variable name="src-1st-da-prepped" select="tan:get-src-1st-da-prepped()"/>
      <xsl:copy-of
         select="tan:cull-prepped-class-1-data($elements-with-atomic-src-and-ref-attributes, $src-1st-da-prepped, false())"
      />
   </xsl:function>
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
                           <errors>
                              <xsl:copy-of select="$erroneous-refs"/>
                           </errors>
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

   <!-- STEP SELF-EXPANDED-3: revise self-expanded-2 to fully expand @ref (<tok>, <realign>, <align>; @seg remains unexpanded) -->

   <xsl:function name="tan:get-self-expanded-3">
      <!-- zero parameter function of the next -->
      <xsl:copy-of
         select="tan:get-self-expanded-3(tan:get-self-expanded-2(), tan:get-src-1st-da-prepped())"/>
   </xsl:function>
   <xsl:function name="tan:get-self-expanded-3" as="document-node()?">
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:document>
         <xsl:apply-templates mode="self-expanded-3" select="$self-expanded-2">
            <xsl:with-param name="self-expanded-2" select="$self-expanded-2"/>
            <xsl:with-param name="src-1st-da-prepped" select="$src-1st-da-prepped"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="node()" mode="self-expanded-3">
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="self-expanded-2" select="$self-expanded-2"/>
            <xsl:with-param name="src-1st-da-prepped" select="$src-1st-da-prepped"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:realign | tan:align | tan:split-leaf-div-at" mode="self-expanded-3">
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:variable name="shallow-picks" select="true()"/>
      <xsl:variable name="distribute-for-works"
         select="self::tan:align and (not(@exclusive = true())) and root()/tan:TAN-A-div"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="tan:div-ref | tan:anchor-div-ref | tan:tok"
            group-by="count(preceding-sibling::*[not(@cont)])">
            <xsl:variable name="these-div-refs" select="current-group()"/>
            <xsl:variable name="div-ref-expanded-for-work" as="element()*">
               <xsl:choose>
                  <xsl:when test="$distribute-for-works = true()">
                     <!-- If there is no @exclusive, then the <div-refs> need to be iterated for every source for that work -->
                     <xsl:variable name="srcs-for-this-work"
                        select="$self-expanded-2/tan:TAN-A-div/tan:body/tan:group[tan:work/@src = $these-div-refs/@src]/tan:work/@src"/>
                     <xsl:for-each select="$srcs-for-this-work">
                        <xsl:variable name="this-src" select="."/>
                        <xsl:variable name="src-pos" select="position()"/>
                        <xsl:for-each select="current-group()">
                           <xsl:copy>
                              <xsl:copy-of select="@*"/>
                              <xsl:attribute name="src" select="$this-src"/>
                              <!-- This ensures that sources in a single work are treated as a single group -->
                              <xsl:if test="$src-pos lt count($srcs-for-this-work)">
                                 <xsl:attribute name="cont" select="true()"/>
                              </xsl:if>
                           </xsl:copy>
                        </xsl:for-each>
                     </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="$these-div-refs"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:copy-of
               select="tan:expand-ref($div-ref-expanded-for-work, $shallow-picks, $src-1st-da-prepped)"
            />
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:ana" mode="self-expanded-3">
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:variable name="shallow-picks" select="true()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="tan:tok" group-by="count(preceding-sibling::*[not(@cont)])">
            <xsl:copy-of
               select="tan:expand-ref(current-group(), $shallow-picks, $src-1st-da-prepped)"/>
         </xsl:for-each-group>
         <xsl:copy-of select="node()[not(self::tan:tok)]"/>
      </xsl:copy>
   </xsl:template>

   <!-- functions for step -->
   <xsl:function name="tan:expand-ref" as="element()*">
      <!-- takes any elements that have compound values for @ref. Returns one copy per element
         per ref, replacing @ref with normalized single reference, putting the original value
         of @ref into @orig-ref, adding @cont
         for all but the last element for a group of elements that correspond to a single element, and
         copies of all other attributes. Applicable to <div-ref>, <anchor-div-ref>, and <tok>.
      E.g., (<div-ref src="A" ref="1 - 2" seg="1, last"/>, true()) - > 
      (<div-ref src="A" orig-ref="1 - 2" ref="1" seg="1, last"/>, <div-ref src="A" orig-ref="1 - 2" ref="2" seg="1, last"/>) 
      The parameter $shallow-picks indicates whether a range of references should return every possible 
      ref including all descendents, or stay on the hierarchy of each atomic reference. See tan:itemize-refs() 
      for details. 
      -->
      <xsl:param name="elements-with-ref" as="element()*"/>
      <xsl:param name="shallow-picks" as="xs:boolean"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:for-each select="$elements-with-ref">
         <xsl:variable name="this-element" select="."/>
         <xsl:variable name="these-divs-picked"
            select="tan:select-divs($this-element, $shallow-picks, $src-1st-da-prepped)"/>
         <xsl:choose>
            <xsl:when test="exists($these-divs-picked)">
               <xsl:for-each select="$these-divs-picked/*">
                  <xsl:element name="{name($this-element)}">
                     <xsl:copy-of select="$this-element/@*"/>
                     <xsl:attribute name="orig-ref" select="$this-element/@ref"/>
                     <xsl:copy-of select="@ref"/>
                     <xsl:if test="position() lt count($these-divs-picked/*)">
                        <!-- This ensures that groups are retained -->
                        <xsl:attribute name="cont" select="true()"/>
                     </xsl:if>
                  </xsl:element>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="error" select="'ref01'"/>
               </xsl:copy>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:select-divs" as="element()*">
      <!-- 2-parameter function of the complete, 3-parameter one, below. -->
      <xsl:param name="elements-with-ref-norm" as="element()*"/>
      <xsl:param name="shallow-picks" as="xs:boolean"/>
      <xsl:variable name="src-1st-da-prepped" select="tan:get-src-1st-da-prepped()"/>
      <xsl:copy-of
         select="tan:select-divs($elements-with-ref-norm, $shallow-picks, $src-1st-da-prepped)"/>
   </xsl:function>
   <xsl:function name="tan:select-divs" as="element()*">
      <!-- Turns an element with a single @src and a normalized but compound @ref string into a sequence of 
         <div>s chosen in the prepped documents supplied. 
         Input: (1) Element with a single value for @src and normalized value of @ref; (2) indication whether picks 
         should be shallow or deep; and (3) sources prepped
         Output: <div>s from the prepped sources
         Choosing shallowly returns no descendants of the chosen elements, and in ranges, all divs will be
         on the same hierarchical level as the starting point
      -->
      <xsl:param name="elements-with-ref-norm" as="element()*"/>
      <xsl:param name="shallow-picks" as="xs:boolean"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>

      <xsl:for-each select="$elements-with-ref-norm">
         <xsl:variable name="this-element" select="."/>
         <xsl:variable name="this-src" select="@src"/>
         <xsl:variable name="src-1st-da-data-prepped"
            select="$src-1st-da-prepped[*/@src = $this-src]/tan:TAN-T/tan:body"/>
         <xsl:variable name="ref-range-seq-1" select="tokenize(@ref, ' , ')"/>
         <result src="{$this-src}" ref="{$this-element/@ref}">
            <xsl:for-each select="$ref-range-seq-1">
               <xsl:variable name="start" select="tokenize(., ' - ')[1]"/>
               <xsl:variable name="end" select="tokenize(., ' - ')[2]"/>
               <xsl:variable name="start-div"
                  select="key('div-via-ref', $start, $src-1st-da-data-prepped)"/>
               <xsl:variable name="end-div"
                  select="key('div-via-ref', $end, $src-1st-da-data-prepped)"/>
               <xsl:choose>
                  <xsl:when test="exists($end)">
                     <xsl:variable name="start-hierarchy"
                        select="tokenize($start, $separator-hierarchy-regex)"/>
                     <xsl:variable name="start-hierarchy-depth" select="count($start-hierarchy)"/>
                     <xsl:choose>
                        <xsl:when test="$shallow-picks = false()">
                           <!--<xsl:copy-of
                              select="
                              $start-div/(descendant-or-self::tan:div, following::tan:div) except
                              $end-div/(following::tan:div, ancestor::tan:div)"
                           />-->
                           <xsl:copy-of
                              select="
                                 $src-1st-da-data-prepped//tan:div[@ref = $start]/(descendant-or-self::tan:div, following::tan:div) except
                                 $src-1st-da-data-prepped//tan:div[@ref = $end]/(following::tan:div, ancestor::tan:div)"
                           />
                        </xsl:when>
                        <xsl:otherwise>
                           <!--<xsl:copy-of
                              select="
                              $start-div/(self::tan:div, following::tan:div)[count(ancestor-or-self::tan:div) = $start-hierarchy-depth] except
                              $end-div/(following::tan:div, ancestor::tan:div)"
                           />-->
                           <xsl:copy-of
                              select="
                                 $src-1st-da-data-prepped//tan:div[@ref = $start]/(self::tan:div, following::tan:div)[count(ancestor-or-self::tan:div) = $start-hierarchy-depth] except
                                 $src-1st-da-data-prepped//tan:div[@ref = $end]/(following::tan:div, ancestor::tan:div)"
                           />
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:choose>
                        <xsl:when test="$shallow-picks = true()">
                           <!--<xsl:copy-of
                              select="
                              $start-div except
                              $start-div/descendant::tan:div"
                           />-->
                           <xsl:copy-of
                              select="
                                 $src-1st-da-data-prepped//tan:div[@ref = $start] except
                                 $src-1st-da-data-prepped//tan:div[@ref = $start]/descendant::tan:div"
                           />
                        </xsl:when>
                        <xsl:otherwise>
                           <!--<xsl:copy-of select="$start-div"/>-->
                           <xsl:copy-of
                              select="$src-1st-da-data-prepped//tan:div[@ref = $start]/descendant-or-self::tan:div"
                           />
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </result>
      </xsl:for-each>
   </xsl:function>

   <!-- STEP SRC-1ST-DA-TOKENIZED: tokenize prepped source documents, using token definitions in self-expanded-2 -->
   <xsl:function name="tan:get-src-1st-da-tokenized" as="document-node()*">
      <!-- zero-parameter version of the next function -->
      <xsl:copy-of
         select="tan:get-src-1st-da-tokenized(tan:get-self-expanded-2(), tan:get-src-1st-da-prepped())"
      />
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-tokenized" as="document-node()*">
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="prepped-class-1-doc" as="document-node()*"/>
      <xsl:copy-of
         select="tan:get-src-1st-da-tokenized($self-expanded-2, $prepped-class-1-doc, true())"/>
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-tokenized" as="document-node()*">
      <!-- Input: self-expanded-2 and prepped class 1 document; output: same document tokenized -->
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="prepped-class-1-doc" as="document-node()*"/>
      <xsl:param name="add-n-attr" as="xs:boolean"/>
      <xsl:variable name="token-definitions"
         select="$self-expanded-2/*/tan:head/tan:declarations/tan:token-definition"/>
      <xsl:for-each select="$prepped-class-1-doc">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy>
            <xsl:apply-templates select="node()" mode="tokenize-prepped-class-1">
               <xsl:with-param name="token-definitions"
                  select="$token-definitions[@src = $this-src]"/>
               <xsl:with-param name="add-n-attr" select="$add-n-attr"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="tokenize-prepped-class-1">
      <xsl:param name="token-definitions" as="element()*"/>
      <xsl:param name="add-n-attr" as="xs:boolean"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="token-definitions" select="$token-definitions"/>
            <xsl:with-param name="add-n-attr" select="$add-n-attr"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[not(tan:div)]" mode="tokenize-prepped-class-1">
      <xsl:param name="token-definitions" as="element()*"/>
      <xsl:param name="add-n-attr" as="xs:boolean"/>
      <xsl:variable name="this-text" select="normalize-space(string-join(.//text(), ''))"/>
      <xsl:variable name="this-analyzed"
         select="tan:tokenize-leaf-div($this-text, $token-definitions, $add-n-attr)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$this-analyzed/@max-toks"/>
         <xsl:copy-of select="$this-analyzed/*"/>
         <xsl:copy-of select="tei:*"/>
      </xsl:copy>
   </xsl:template>

   <!-- Derivative functions -->
   <xsl:function name="tan:tokenize-div" as="element()*">
      <!-- This function allows one to quickly get select <divs> in tokenized form, but
      requires passing the <token-definition> on -->
      <xsl:param name="divs" as="element()*"/>
      <xsl:param name="token-definitions" as="element()"/>
      <xsl:apply-templates select="$divs" mode="tokenize-prepped-class-1">
         <xsl:with-param name="token-definitions" select="$token-definitions"/>
         <xsl:with-param name="add-n-attr" select="false()"/>
      </xsl:apply-templates>
   </xsl:function>

   <!-- STEP SELF-EXPANDED-4: revise self-expanded-3 to fully expand @val and @pos in <tok> -->

   <xsl:function name="tan:get-self-expanded-4">
      <!-- zero parameter function of the next -->
      <xsl:copy-of
         select="tan:get-self-expanded-4(tan:get-self-expanded-3(), tan:get-src-1st-da-tokenized())"
      />
   </xsl:function>
   <xsl:function name="tan:get-self-expanded-4" as="document-node()?">
      <xsl:param name="self-expanded-3" as="document-node()?"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:document>
         <xsl:apply-templates mode="self-expanded-4" select="$self-expanded-3">
            <xsl:with-param name="self-expanded-3" select="$self-expanded-3"/>
            <xsl:with-param name="src-1st-da-tokenized" select="$src-1st-da-tokenized"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:function>
   <xsl:template match="node()" mode="self-expanded-4">
      <xsl:param name="self-expanded-3" as="document-node()?"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="self-expanded-2" select="$self-expanded-3"/>
            <xsl:with-param name="src-1st-da-tokenized" select="$src-1st-da-tokenized"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:tok" mode="self-expanded-4">
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:copy-of select="tan:expand-tok(., $src-1st-da-tokenized)"/>
   </xsl:template>

   <!-- functions for step -->
   <xsl:function name="tan:expand-tok" as="element()*">
      <!-- Input: any <tok> with atomic @src and @ref values; any number of tokenized source documents
         Output: one <tok> per token invoked, adding @n to specify where in the <div> the token is to be found;
         if @chars is present it is replaced with a space-delimited list of integers
      -->
      <xsl:param name="tok-elements" as="element()*"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <xsl:for-each select="$tok-elements">
         <xsl:variable name="this-tok" select="."/>
         <xsl:variable name="this-div"
            select="$src-1st-da-tokenized/tan:TAN-T[@src = $this-tok/@src]/tan:body//tan:div[@ref = $this-tok/@ref]"/>
         <xsl:variable name="those-toks" select="tan:get-toks($this-div, $this-tok)"/>
         <xsl:for-each select="$those-toks">
            <xsl:variable name="that-n" select="@n"/>
            <xsl:variable name="that-seq" select="position()"/>
            <xsl:variable name="that-val" select="text()"/>
            <xsl:for-each select="$this-tok">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="group" select="concat(@group, '-', $that-seq)"/>
                  <xsl:attribute name="n" select="$that-n"/>
                  <xsl:if test="exists($this-tok/@chars)">
                     <xsl:variable name="those-chars"
                        select="tan:get-chars($that-val, $this-tok/@chars)"/>
                     <xsl:attribute name="chars" select="$those-chars/tan:match/@n"/>
                  </xsl:if>
               </xsl:copy>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:get-toks" as="element()*">
      <!-- returns the <tok>s from a given <div>, including @n with integer position
         Input: (1) any <div> with <tok> and <non-tok> children (result of tan:tokenize-prepped-1st-da())
         (2) any number of <tok> that are deemed to relate to the <div> chosen (i.e., @src and @ref will 
         be ignored)
         Output: integers calculated by determining where each @val and @pos are found; when not found,
         -1 will be returned.
      -->
      <xsl:param name="tokenized-div" as="element()?"/>
      <xsl:param name="tok-elements" as="element()*"/>
      <xsl:for-each select="$tok-elements">
         <!-- if no @val then use the regex escape charactor for anything -->
         <xsl:variable name="this-val"
            select="concat('^', (tan:normalize-text(@val), '.+')[1], '$')"/>
         <xsl:variable name="these-matches"
            select="$tokenized-div/tan:tok[tan:matches(., $this-val)]"/>
         <xsl:variable name="max-toks" select="count($these-matches)"/>
         <xsl:variable name="these-pos-itemized"
            select="
               if (@pos) then
                  tan:sequence-expand(tan:normalize-text(@pos), $max-toks)
               else
                  1"/>
         <xsl:for-each select="$these-pos-itemized">
            <xsl:variable name="this-pos" select="."/>
            <xsl:choose>
               <xsl:when test="count($tok-elements) = 0">
                  <tok error="3" n="-3"/>
               </xsl:when>
               <xsl:when test="not($tokenized-div/tan:tok)">
                  <tok error="2" n="-2"/>
               </xsl:when>
               <xsl:when test="count($these-matches) lt $this-pos">
                  <tok error="1" n="-1"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:for-each select="$these-matches[$this-pos]">
                     <xsl:copy>
                        <xsl:attribute name="n"
                           select="count($these-matches[$this-pos]/preceding-sibling::tan:tok) + 1"/>
                        <xsl:copy-of select="text()"/>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:get-chars" as="element()?">
      <!-- Input: a string and the value of @chars
         Output: the string analyzed according to position
      -->
      <xsl:param name="string" as="xs:string"/>
      <xsl:param name="chars" as="xs:string"/>
      <xsl:variable name="regex" select="'\P{M}\p{M}*'"/>
      <xsl:variable name="string-analyzed" as="xs:string*">
         <xsl:analyze-string select="$string" regex="{$regex}">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="char-nos" select="tan:sequence-expand($chars, count($string-analyzed))"/>
      <tok>
         <xsl:for-each select="$string-analyzed">
            <xsl:variable name="pos" select="position()"/>
            <xsl:choose>
               <xsl:when test="$pos = $char-nos">
                  <match n="{$pos}">
                     <xsl:value-of select="."/>
                  </match>
               </xsl:when>
               <xsl:otherwise>
                  <non-match>
                     <xsl:value-of select="."/>
                  </non-match>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </tok>
   </xsl:function>
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
         <xsl:when test="some $i in $ref-tok-filter, $j in descendant-or-self::tan:div satisfies matches($j/@ref, $i/@ref)">
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
         <xsl:when test="(count(preceding-sibling::tan:tok) + 1) = $ref-tok-filter[@ref = $this-ref][@chars]/@n">
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
      transformation for other purposes. Also, below are some helpful, optional transformations
   -->

   <xsl:function name="tan:recombine-docs" as="document-node()*">
      <!-- Input: any number of documents
      Output: recombined documents
      This function is useful for cases where you have both picked and culled
      from a source, and you wish to combine the two documents into a single one
      that strips away duplicates. 
      NB, the results may not preserve the original document order of an original
      document. It also treats non-leaf white-space text nodes as dispensible.
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
                     <error src="{$this-rims-src}">Reconcile suppress-div-types before using this
                        function. <xsl:copy-of select="$this-rims-sdts"/>
                        <xsl:copy-of
                           select="$hub-sdts[tokenize((@src, '1')[1], '\s+') = $this-rims-src]"/>
                     </error>
                  </xsl:document>
               </xsl:when>
               <xsl:when
                  test="not($this-rims-tds/@regex = $hub-tds[tokenize((@src, '1')[1], '\s+')]/@regex)">
                  <xsl:document>
                     <xsl:copy-of select="$rim"/>
                     <error src="{$this-rims-src}">Reconcile token-definitions before using this
                        function. <these-srcs><xsl:value-of select="$this-rims-src"/></these-srcs>
                        <xsl:copy-of select="*/tan:head/tan:declarations/tan:token-definition"/>
                     </error>
                  </xsl:document>
               </xsl:when>
               <xsl:when
                  test="not(exists($this-rims-rdns) or exists($hub-rdns[tokenize((@src, '1')[1], '\s+') = $this-rims-src]))">
                  <!-- If neither rim nor hub rename any div types, then just proceed -->
                  <xsl:sequence select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <!-- If we've gotten here, then the rim or the hub rename div types, and they need to be reconciled. 
                  The strategy is to get two version of the spoke: one that reflects the naming covention of the hub, 
                  the other for the rim. One then traverses from the rim through the two spokes to the hub, or vice
                  versa: rim ⇄ spoke-prepped-for-rim ⇄ spoke-prepped-for-hub ⇄ hub
                  Of these four files, we are missing only the second.
                  -->
                  <xsl:variable name="spokes-prepped-for-rim"
                     select="tan:get-src-1st-da-prepped(., $srcs-resolved[*/@src = $this-rims-src])"/>
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
                     select="tan:get-self-expanded-3(., $spokes-prepped-for-rim)"/>
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
         <xsl:variable name="this-ref-norm" select="tan:normalize-refs(@ref)"/>
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
   <xsl:function name="tan:get-n-types" as="element()+">
      <!-- Calculates types of @n values per div type per source and div type -->
      <xsl:param name="src-1st-da-resolved" as="document-node()*"/>
      <xsl:for-each select="$src-1st-da-resolved">
         <!--<xsl:variable name="this-id" select="*/@id"/>-->
         <xsl:variable name="this-doc" select="."/>
         <xsl:variable name="this-src-id" select="*/@src"/>
         <n-types src="{$this-src-id}">
            <xsl:variable name="n-vals" as="element()*">
               <xsl:for-each select="*/tan:head/tan:declarations/tan:div-type">
                  <xsl:variable name="this-div-type-id" select="@xml:id"/>
                  <xsl:variable name="these-ns" as="xs:string*">
                     <xsl:copy-of
                        select="
                           $this-doc//(tan:div,
                           tei:div)[@type = $this-div-type-id]/@n"
                     />
                  </xsl:variable>
                  <xsl:variable name="this-ns-types"
                     select="
                        if (@ns-are-numerals = 'false') then
                           for $i in $these-ns
                           return
                              '$'
                        else
                           for $i in $these-ns
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
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:attribute name="n-type" select="$this-dominant-n-type"/>
                     <xsl:attribute name="ns-type-i" select="$this-n-types-count[1]"/>
                     <xsl:attribute name="ns-type-1" select="$this-n-types-count[2]"/>
                     <xsl:attribute name="ns-type-1a" select="$this-n-types-count[3]"/>
                     <xsl:attribute name="ns-type-a" select="$this-n-types-count[4]"/>
                     <xsl:attribute name="ns-type-a1" select="$this-n-types-count[5]"/>
                     <xsl:attribute name="ns-type-str" select="$this-n-types-count[6]"/>
                     <xsl:attribute name="unique-n-values" select="distinct-values($these-ns)"/>
                  </xsl:copy>
               </xsl:for-each>
            </xsl:variable>
            <xsl:copy-of select="$n-vals"/>
         </n-types>
      </xsl:for-each>
   </xsl:function>

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
