<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>March 4, 2016</xd:p>
         <xd:p>Core variables and functions for class 2 TAN files (i.e., applicable to multiple
            class 2 TAN file types). Written principally for Schematron validation, but suitable for
            general use in other contexts.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:include href="TAN-core-functions.xsl"/>

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
   <xsl:variable name="match-flags" xml:id="v-match-flags"
      select="
         if ($searches-are-case-sensitive = true()) then
            ()
         else
            'i'"
      as="xs:string?"/>
   <xsl:param name="searches-suppress-what-text" xml:id="p-searches-suppress-what-text"
      as="xs:string?" select="'[\p{M}]'"/>

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
      self-expanded-1                          Expand @src (but not for <equate-works>), @div-type-ref; add @xml:id to TAN-LM <source>
                         src-1st-da            Get first document available for each source chosen
                         src-1st-da-resolved   Resolve each source document: add @src to root element, get inclusions, keywords, strip duplicates
      self-expanded-2                          Expand <token-definition> and (TAN-A-div) <equate-works>, <equate-div-types>
                         src-1st-da-flattened  Flatten each source document
                         src-1st-da-prepped    Add @work to each root element, rename @ns, suppress div types, replace div types with numerical equivalent
      self-expanded-3                          Expand @ref for <tok>, <div-ref>, <anchor-div-ref>
                         src-1st-da-tokenized  Tokenize using the default token definitions
      self-expanded-4                          Expand @val, @pos for <tok>
      
      Each specific class-2 file admits further transformations. See the appropriate function
      spreadsheet for more information.
   -->

   <!-- STEP SELF-EXPANDED-1: First expansion of class-2 file: expand @src, @div-type-ref; add @src to <source> in TAN-LM file; start <equate-work> expansion -->
   <!-- commented this out March 2016; let's see if we can't get rid of it. -->
   <!--<xsl:variable name="self-expanded-1" select="tan:get-self-expanded-1()"/>-->
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
               $srcs-pass-1"
      />
      <xsl:variable name="these-div-types"
         select="tokenize(tan:normalize-text(@div-type-ref), '\W+')"/>
      <xsl:for-each
         select="
            if (exists($these-sources)) then
               $these-sources
            else
               1">
         <xsl:variable name="this-src" select="."/>
         <xsl:for-each
            select="
               if (exists($these-div-types)) then
                  $these-div-types
               else
                  1">
            <xsl:element name="{$this-element-name}">
               <xsl:copy-of select="$this-element/@*"/>
               <xsl:attribute name="src" select="$this-src"/>
               <xsl:if test="exists($these-div-types)">
                  <xsl:attribute name="div-type-ref" select="."/>
               </xsl:if>
               <xsl:copy-of select="$this-element/node()"/>
            </xsl:element>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:template>

   <!-- Results of step -->
   <xsl:variable name="src-elements" select="$head/tan:source"/>
   <xsl:variable name="src-ids" select="$src-elements/@xml:id" as="xs:string+"/>

   <!-- Resultant functions -->
   <xsl:function name="tan:expand-src-and-div-type-ref" as="element()*">
      <xsl:param name="elements-with-src-and-div-type" as="element()*"/>
      <xsl:apply-templates mode="self-expanded-1" select="$elements-with-src-and-div-type"/>
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
               $j in tan:first-loc-available($src-elements[@xml:id = $i])
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
               <xsl:copy-of select="$src-elements[position() = $seq-exp]/@xml:id"/>
            </xsl:when>
            <xsl:when test=". = $src-ids">
               <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test=". instance of xs:integer and . le count($src-elements)">
               <xsl:copy-of select="$src-elements[.]/@xml:id"/>
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
   <xsl:function name="tan:get-src-1st-da-resolved" xml:id="v-src-1st-da-resolved">
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

   <!-- STEP SRC-1ST-DA-FLATTENED: flatten source documents -->
   <xsl:function name="tan:get-src-1st-da-flattened" xml:id="v-src-1st-da-prepped"
      as="document-node()*">
      <!-- zero-parameter version of the next function -->
      <xsl:copy-of select="tan:get-src-1st-da-flattened(tan:resolve-doc(tan:get-src-1st-da()))"/>
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-flattened" as="document-node()*">
      <!-- Input: resolved class 1 document; output: same document flattened -->
      <xsl:param name="resolved-class-1-doc" as="document-node()*"/>
      <xsl:copy-of select="tan:flatten-class-1-doc($resolved-class-1-doc)"/>
   </xsl:function>

   <!-- STEP SRC-1ST-DA-PREPPED: add to source documents work id, renamed ns, suppressed div types -->
   <xsl:function name="tan:get-src-1st-da-prepped" as="document-node()*">
      <!-- zero-parameter version of the next function -->
      <xsl:copy-of
         select="tan:get-src-1st-da-prepped(tan:get-self-expanded-2(), tan:get-src-1st-da-flattened())"
      />
   </xsl:function>
   <xsl:function name="tan:get-src-1st-da-prepped" as="document-node()*">
      <!-- Input: sequence of flattened class 1 TAN documents 
         Output: sequence of documents with these changes:
         /*   - >   @work="[DIGIT DRAWN FROM TAN-A-div //tan:group[tan:work]/@id]"
         tei:TEI - > tan:TAN-T
         tei:text/tei:body   - >  tan:body
         tei:div  - >  tan:div
         <div [copy of @*] @pos="[POSITION, TO AVOID LENGTHY RECALCULATIONS DOWNSTREAM]" 
         @type-eq="[DIV-TYPE EQUIVALENCES]" @ref="[NORMALIZED, FLATTENED REF WITH N 
         SUBSTITUTIONS AND SUPPRESSIONS]">[COPY OF CONTENT, INCLUDING TEI MARKUP, IF ANY]</div>
         Text remains untokenized.
      -->
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <xsl:param name="flattened-class-1-documents" as="document-node()*"/>
      <!--<xsl:variable name="work-equivs" as="element()*"
         select="$self-expanded-2/*/tan:body/tan:group[tan:work]"/>
      <xsl:variable name="div-type-equivs" as="element()*"
         select="$self-expanded-2/*/tan:body/tan:group[tan:div-type]"/>-->
      <xsl:for-each select="$flattened-class-1-documents">
         <xsl:variable name="pos" select="position()"/>
         <xsl:copy>
            <xsl:apply-templates mode="prep-class-1" select="node()">
               <xsl:with-param name="self-expanded-2" select="$self-expanded-2"/>
               <!--<xsl:with-param name="work-equivs" select="$work-equivs"/>
               <xsl:with-param name="div-type-equivs" select="$div-type-equivs"/>-->
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="prep-class-1">
      <!--<xsl:param name="work-equivs" as="element()*"/>
      <xsl:param name="div-type-equivs" as="element()*"/>-->
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="self-expanded-2" select="$self-expanded-2"/>
            <!--<xsl:with-param name="work-equivs" select="$work-equivs"/>
            <xsl:with-param name="div-type-equivs" select="$div-type-equivs"/>-->
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:TAN-T | tei:TEI" mode="prep-class-1">
      <!-- Homogenize tei:TEI to tan:TAN-T -->
      <!--<xsl:param name="work-equivs" as="element()*"/>
      <xsl:param name="div-type-equivs" as="element()*"/>-->
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <xsl:variable name="this-root-id" select="@id"/>
      <xsl:variable name="src-id" select="$head/tan:source[tan:IRI = $this-root-id]/@xml:id"/>
      <TAN-T>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="src" select="$src-id"/>
         <xsl:attribute name="work" select="($self-expanded-2/tan:TAN-A-div/tan:body/tan:group[tan:work/@src = $src-id]/@n, 1)[1]"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="self-expanded-2" select="$self-expanded-2"/>
            <!--<xsl:with-param name="div-type-equivs" select="$div-type-equivs"/>-->
         </xsl:apply-templates>
      </TAN-T>
   </xsl:template>
   <xsl:template match="tei:text" mode="prep-class-1">
      <!-- This template makes sure the tei:body drops rootward one level, as is customary in TAN and HTML -->
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <!--<xsl:param name="div-type-equivs" as="element()*"/>-->
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="self-expanded-2" select="$self-expanded-2"/>
         <!--<xsl:with-param name="div-type-equivs" select="$div-type-equivs"/>-->
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tan:body | tei:body" mode="prep-class-1" xml:id="t-prep-class-1-data">
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <!--<xsl:param name="div-type-equivs" as="element()*"/>-->
      <xsl:variable name="this-root-id" select="root(.)/*/@id"/>
      <xsl:variable name="this-src-id" select="$head/tan:source[tan:IRI = $this-root-id]/@xml:id"/>
      <!-- Homogenize tei:body element to tan:body -->
      <body>
         <xsl:copy-of select="@*"/>
         <xsl:for-each select="*">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="this-after-div-types-suppressed"
               select="tan:suppress-div-types(., $this-src-id,$self-expanded-2)"/>
            <xsl:variable name="this-after-ns-renamed"
               select="tan:add-ref-to-div($this-after-div-types-suppressed, $this-src-id,$self-expanded-2)"/>
            <xsl:variable name="this-after-types-equated"
               select="
                  if ($fetch-type-eq = true()) then
                     tan:add-type-eq-to-div($this-after-ns-renamed, $this-src-id, $self-expanded-2)
                  else
                     $this-after-ns-renamed"/>
            <xsl:copy-of select="$this-after-types-equated"/>
         </xsl:for-each>
      </body>
   </xsl:template>

   <!-- Functions for step -->
   <xsl:function name="tan:suppress-div-types" as="element()">
      <xsl:param name="flattened-div" as="element()"/>
      <xsl:param name="src-id" as="xs:string"/>
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <xsl:variable name="div-types-to-suppress"
         select="$self-expanded-2/*/tan:head/tan:declarations/tan:suppress-div-types[@src = $src-id]/@div-type-ref"/>
      <xsl:variable name="type-seq"
         select="tokenize($flattened-div/@type, $separator-hierarchy-regex)"/>
      <xsl:variable name="n-seq" select="tokenize($flattened-div/@n, $separator-hierarchy-regex)"/>
      <xsl:variable name="delete-which-items"
         select="
            for $i in $div-types-to-suppress
            return
               index-of($type-seq, $i)"/>
      <xsl:for-each select="$flattened-div">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="type"
               select="string-join($type-seq[not(position() = $delete-which-items)], $separator-hierarchy)"/>
            <xsl:attribute name="n"
               select="string-join($n-seq[not(position() = $delete-which-items)], $separator-hierarchy)"/>
            <xsl:copy-of select="node()"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:add-ref-to-div" xml:id="f-ref-rename" as="element()">
      <!-- Input: flattened <div>, source-id
         Output: that same element reference transformed, adding @ref that changes @n values 
         according to new ones declared in the class-2 <rename-ns>.
         E.g., (<div type="bk ch v" n="Gn V iv">, 'ot') - > <div type="bk ch v" n="Gn V iv" ref="gen 5 4"/>
      -->
      <xsl:param name="flattened-div" as="element()"/>
      <xsl:param name="src-id" as="xs:string"/>
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <xsl:variable name="rename-div-ns"
         select="$self-expanded-2/*/tan:head/tan:declarations/tan:rename-div-ns[@src = $src-id]"/>
      <xsl:variable name="type-seq"
         select="tokenize($flattened-div/@type, $separator-hierarchy-regex)"/>
      <xsl:variable name="ref-seq" select="tokenize($flattened-div/@n, $separator-hierarchy-regex)"/>
      <xsl:variable name="ref-seq-repl" as="xs:string*">
         <xsl:for-each select="$ref-seq">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="this-type" select="$type-seq[$pos]"/>
            <xsl:variable name="this-n" select="."/>
            <xsl:variable name="this-n-rename"
               select="
                  if ($rename-div-ns[@div-type-ref = $this-type]/tan:rename[@old = $this-n]) then
                     $rename-div-ns[@div-type-ref = $this-type]/tan:rename[@old = $this-n]/@new
                  else
                     if ($rename-div-ns[@div-type-ref = $this-type]/tan:rename[@old = '#a'] and matches($this-n, $n-type-pattern[4])) then
                        (tan:aaa-to-int($this-n))
                     else
                        if ($rename-div-ns[@div-type-ref = $this-type]/tan:rename[@old = '#i'] and matches($this-n, $n-type-pattern[1])) then
                           (tan:rom-to-int($this-n))
                        else
                           ()"/>
            <xsl:value-of select="($this-n-rename, $this-n)[1]"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$flattened-div">
         <div>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="ref">
               <xsl:value-of select="string-join($ref-seq-repl, $separator-hierarchy)"/>
            </xsl:attribute>
            <xsl:copy-of select="node()"/>
         </div>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:add-type-eq-to-div" as="element()">
      <!-- Input: flattened <div>, source-id, copy of TAN-A-div's //tan:group[tan:div-type]
         Output: that same <div>, with added @type-eq that converts @type values 
         to the digits supplied in the calculated div-type equivalences.
         E.g., (<div type="bk ch v" n="Gn V iv" ref="gen 5 4"/>, 'ot', $div-type-equivs) - > <div type="bk ch v" n="Gn V iv" ref="gen 5 4" type-eq="1 4 3"/>
      -->
      <xsl:param name="flattened-div" as="element()"/>
      <xsl:param name="src-id" as="xs:string"/>
      <xsl:param name="self-expanded-2" as="document-node()"/>
      <xsl:variable name="type-seq"
         select="tokenize($flattened-div/@type, $separator-hierarchy-regex)"/>
      <xsl:variable name="div-type-equivs"
         select="$self-expanded-2/tan:TAN-A-div/tan:body/tan:group[tan:div-type]"/>
      <xsl:variable name="type-eq-seq"
         select="
            for $i in $type-seq
            return
               $div-type-equivs[tan:div-type[@src = $src-id and @xml:id = $i]]/@n"
      />
      <xsl:for-each select="$flattened-div">
         <div>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="type-eq">
               <xsl:value-of select="string-join($type-eq-seq, $separator-hierarchy)"/>
            </xsl:attribute>
            <xsl:copy-of select="node()"/>
         </div>
      </xsl:for-each>
   </xsl:function>

   <!-- Interlude: chance to reduce the size of the prepped files -->
   <xsl:function name="tan:pick-prepped-class-1-data" as="document-node()*">
      <!-- 1-param function of the 2-param version below -->
      <xsl:param name="elements-with-atomic-src-and-ref-attributes" as="element()*"/>
      <xsl:variable name="src-1st-da-prepped" select="tan:get-src-1st-da-prepped()"/>
      <xsl:copy-of
         select="tan:pick-prepped-class-1-data($elements-with-atomic-src-and-ref-attributes, $src-1st-da-prepped)"
      />
   </xsl:function>
   <xsl:function name="tan:pick-prepped-class-1-data" xml:id="f-pick-prepped-class-1-data"
      as="document-node()*">
      <!-- Used to create a subset of $src-1st-da-prepped 
         Input: any element with @src and @ref. It is assumed that both attributes have single, atomic values
         (i.e., no ranges in @ref)
         Output: src-1st-da-prepped, proper subset
         This is the earliest stage at which a picked source document can be reduced to a particular subset, 
         to make later transformations more efficient.
      -->
      <xsl:param name="elements-with-atomic-src-and-ref-attributes" as="element()*"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:variable name="sources-to-be-picked"
         select="distinct-values($elements-with-atomic-src-and-ref-attributes/@src)"/>
      <xsl:for-each select="$src-1st-da-prepped">
         <xsl:choose>
            <xsl:when test="*/@src = $sources-to-be-picked">
               <xsl:copy>
                  <xsl:apply-templates select="node()" mode="pick-prepped-class-1">
                     <xsl:with-param name="refs-norm"
                        select="$elements-with-atomic-src-and-ref-attributes[@src = current()/*/@src]"
                     />
                  </xsl:apply-templates>
               </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="pick-prepped-class-1">
      <xsl:param name="refs-norm" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="refs-norm" select="$refs-norm"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:body" mode="pick-prepped-class-1">
      <xsl:param name="refs-norm" as="element()*"/>
      <xsl:variable name="all-possible-refs" select="tan:div/@ref"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="tan:div[@ref = $refs-norm/@ref]"/>
         <xsl:for-each select="$refs-norm/@ref[not(. = $all-possible-refs)]">
            <xsl:variable name="error"
               select="
                  if (matches(., '[-,]\s+')) then
                     $errors//tan:error[@xml:id = 'ref02']
                  else
                     $errors//tan:error[@xml:id = 'ref01']"/>
            <div error="{$error/@xml:id}">
               <xsl:value-of select="$error"/></div>
         </xsl:for-each>
      </xsl:copy>
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
      <xsl:variable name="shallow-picks"
         select="
            if (@distribute = true()) then
               true()
            else
               false()"/>
      <xsl:variable name="distribute-for-works"
         select="self::tan:align and (not(@exclusive = true()))"/>
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

   <!-- functions for step -->
   <xsl:function name="tan:expand-ref" as="element()*">
      <!-- takes any elements that has compound values for @ref. Returns one copy per element
         per ref, replacing @ref with normalized single reference, @cont
         for all but the last element for a group of elements that correspond to a single element, and
         copies of all other attributes. Applicable to <div-ref>, <anchor-div-ref>, and <tok>.
      E.g., (<div-ref src="A" ref="1 - 2" seg="1, last"/>, true()) - > 
      (<div-ref src="A" ref="1" seg="1, last"/>, <div-ref src="A" ref="2" seg="1, last"/>) 
      The parameter $shallow-picks indicates whether a range of references should return every possible 
      ref including all descendents, or stay on the hierarchy of each atomic reference. See tan:itemize-refs() 
      for details. 
      -->
      <xsl:param name="elements-with-ref" as="element()*"/>
      <xsl:param name="shallow-picks" as="xs:boolean"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:for-each select="$elements-with-ref">
         <xsl:variable name="this-element" select="."/>
         <xsl:variable name="this-src" select="@src"/>
         <xsl:variable name="this-ref-norm" select="tan:normalize-refs($this-element/@ref)"/>
         <xsl:variable name="this-ref-expand"
            select="tan:itemize-refs($this-ref-norm, $this-src, $shallow-picks, $src-1st-da-prepped)"/>
         <xsl:for-each select="$this-ref-expand">
            <xsl:element name="{name($this-element)}">
               <xsl:copy-of select="$this-element/@*"/>
               <xsl:attribute name="src" select="$this-src"/>
               <xsl:attribute name="ref" select="."/>
               <xsl:if test="position() lt count($this-ref-expand)">
                  <!-- This ensures that groups are retained -->
                  <xsl:attribute name="cont" select="true()"/>
               </xsl:if>
            </xsl:element>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:normalize-refs" xml:id="f-normalize-refs" as="xs:string?">
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

   <xsl:function name="tan:itemize-refs" as="xs:string*">
      <!-- 3-parameter function of the complete, 4-parameter one, below. -->
      <xsl:param name="ref-range-norm" as="xs:string"/>
      <xsl:param name="src" as="xs:string"/>
      <xsl:param name="shallow-picks" as="xs:boolean"/>
      <xsl:variable name="src-1st-da-prepped" select="tan:get-src-1st-da-prepped()"/>
      <xsl:copy-of
         select="tan:itemize-refs($ref-range-norm, $src, $shallow-picks, $src-1st-da-prepped)"/>
   </xsl:function>
   <xsl:function name="tan:itemize-refs" xml:id="f-itemize-bare-refs" as="xs:string*">
      <!-- Turns a compound ref string into a sequence of atomized refs to divs in the source provided,
         calculated conservatively in the case of ranges. Only peers on the hierarchy will be returned. 
         Input: normalized ref sequence (value of @ref), source number, indication whether picks should be shallow or deep
         Output: sequence of values of @ref for leaf divs from $src-1st-da-data
         E.g., for a given source:   $shallow-picks = true():           $shallow-picks = false():
         '1 b , 2 - 4'         - >   ('1 b', '2', '3', '4')             ('1 b', '2', '2 a', '2 b', '2 c', '2 d', '3', '3 a', '3 b', '4', '4 a', '4 b')
         '1 b , 2 - 4 b'       - >   ('1 b', '2', '3', '4 a', '4 b')    ('1 b', '2', '2 a', '2 b', '2 c', '2 d', '3', '3 a', '3 b', '4 a', '4 b')
         '1 b , 2 c - 4'       - >   ('1 b', '2 c', '2 d', '3', '4')    ('1 b', '2 c', '2 d', '3', '3 a', '3 b', '4', '4 a', '4 b')
      -->
      <xsl:param name="ref-range-norm" as="xs:string"/>
      <xsl:param name="src" as="xs:string"/>
      <xsl:param name="shallow-picks" as="xs:boolean"/>
      <xsl:param name="src-1st-da-prepped" as="document-node()*"/>
      <xsl:variable name="src-1st-da-data-prepped"
         select="$src-1st-da-prepped[*/@src = $src]/*/tan:body"/>
      <xsl:variable name="ref-range-seq-1" select="tokenize($ref-range-norm, ' , ')"/>
      <xsl:for-each select="$ref-range-seq-1">
         <xsl:variable name="start" select="tokenize(., ' - ')[1]"/>
         <xsl:variable name="end" select="tokenize(., ' - ')[2]"/>
         <xsl:choose>
            <xsl:when test="exists($end)">
               <xsl:variable name="start-hierarchy"
                  select="tokenize($start, $separator-hierarchy-regex)"/>
               <xsl:variable name="start-hierarchy-depth" select="count($start-hierarchy)"/>
               <xsl:variable name="end-hierarchy"
                  select="tokenize($end, $separator-hierarchy-regex)"/>
               <xsl:variable name="end-hierarchy-depth" select="count($end-hierarchy)"/>
               <xsl:variable name="lowest-common-ancestor-hierarchy-depth"
                  select="
                     index-of(
                     (for $i in (1 to min(($start-hierarchy-depth, $end-hierarchy-depth)))
                     return
                        ($start-hierarchy[$i] = $end-hierarchy[$i])),
                     false())[1] - 1"/>
               <xsl:variable name="start-sibling-regex-match"
                  select="concat('^', replace($start, '\w+', '\\w+'), '$')"/>
               <xsl:variable name="end-sibling-regex-match"
                  select="concat('^', replace($end, '\w+', '\\w+'), '$')"/>
               <!-- This next variable is important, since a range should never include the ancestors of the terminal reference -->
               <xsl:variable name="end-ancestors-ref-vals"
                  select="
                     for $i in (1 to ($end-hierarchy-depth - 1))
                     return
                        string-join($end-hierarchy[position() = (1 to $i)], $separator-hierarchy)"/>
               <xsl:variable name="full-div-selection" as="element()*">
                  <xsl:choose>
                     <xsl:when test="$shallow-picks = false()">
                        <xsl:copy-of
                           select="
                              $src-1st-da-data-prepped/tan:div[@ref = $start]/(self::tan:div,
                              following-sibling::tan:div[not(@ref = $end-ancestors-ref-vals)]) except $src-1st-da-data-prepped[$src]/tan:div[(@ref = $end) or matches(@ref, concat('^', $end, $separator-hierarchy-regex))][last()]/following-sibling::tan:div"
                        />
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:choose>
                           <xsl:when test="$start-hierarchy-depth gt $end-hierarchy-depth">
                              <!-- e.g., '2c - 4' -->
                              <xsl:variable name="exceptions-starting-ref"
                                 select="string-join($start-hierarchy[position() le $end-hierarchy-depth], $separator-hierarchy)"/>
                              <test lca-depth="{$lowest-common-ancestor-hierarchy-depth}"/>
                              <xsl:copy-of
                                 select="
                                    $src-1st-da-data-prepped/tan:div[@ref = $start]/(self::tan:div,
                                    following-sibling::tan:div[matches(@ref, $start-sibling-regex-match)]),
                                    $src-1st-da-data-prepped/tan:div[@ref = $end]/(self::tan:div,
                                    preceding-sibling::tan:div[matches(@ref, $end-sibling-regex-match)]) except
                                    $src-1st-da-data-prepped/tan:div[@ref = $exceptions-starting-ref]/(self::tan:div,
                                    preceding-sibling::tan:div)"
                              />
                           </xsl:when>
                           <xsl:when test="$start-hierarchy-depth lt $end-hierarchy-depth">
                              <!-- e.g., '2 - 4 b' -->
                              <xsl:variable name="exceptions-starting-ref"
                                 select="string-join($end-hierarchy[position() le $start-hierarchy-depth], $separator-hierarchy)"/>
                              <xsl:copy-of
                                 select="
                                    $src-1st-da-data-prepped/tan:div[@ref = $end]/(self::tan:div,
                                    preceding-sibling::tan:div[matches(@ref, $end-sibling-regex-match)]),
                                    $src-1st-da-data-prepped/tan:div[@ref = $start]/(self::tan:div,
                                    following-sibling::tan:div[matches(@ref, $start-sibling-regex-match)]) except
                                    $src-1st-da-data-prepped/tan:div[@ref = $exceptions-starting-ref]/(self::tan:div,
                                    following-sibling::tan:div)"
                              />
                           </xsl:when>
                           <xsl:otherwise>
                              <!-- e.g., '2 - 4' -->
                              <xsl:copy-of
                                 select="
                                    $src-1st-da-data-prepped/tan:div[@ref = $start]/(self::tan:div,
                                    following-sibling::tan:div[matches(@ref, $start-sibling-regex-match)]) except
                                    $src-1st-da-data-prepped/tan:div[@ref = $end]/following-sibling::tan:div"
                              />
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               <xsl:copy-of select="$full-div-selection/@ref"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:choose>
                  <xsl:when test="$shallow-picks = true()">
                     <xsl:copy-of select="."/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of
                        select="$src-1st-da-data-prepped[$src]/tan:div[@ref = $start or matches(@ref, concat('^', $start, $separator-hierarchy-regex))]/@ref"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
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
      <!-- Input: self-expanded-2 and prepped class 1 document; output: same document tokenized -->
      <xsl:param name="self-expanded-2" as="document-node()?"/>
      <xsl:param name="prepped-class-1-doc" as="document-node()*"/>
      <xsl:variable name="token-definitions"
         select="$self-expanded-2/*/tan:head/tan:token-definition"/>
      <xsl:for-each select="$prepped-class-1-doc">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy>
            <xsl:apply-templates select="node()" mode="tokenize-prepped-class-1">
               <xsl:with-param name="token-definitions"
                  select="$token-definitions[@src = $this-src]"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="tokenize-prepped-class-1">
      <xsl:param name="token-definitions" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="token-definitions" select="$token-definitions"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div" mode="tokenize-prepped-class-1">
      <xsl:param name="token-definitions" as="element()*"/>
      <xsl:variable name="this-text" select="normalize-space(string-join(.//text(), ''))"/>
      <xsl:variable name="this-analyzed" select="tan:analyze-string($this-text, $token-definitions)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$this-analyzed/@max-toks"/>
         <xsl:copy-of select="$this-analyzed/*"/>
         <xsl:copy-of select="tei:*"/>
      </xsl:copy>
   </xsl:template>

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
         Output: one <tok> per token invoked, adding @n to specify where in the <div> the token is to be found 
      -->
      <xsl:param name="tok-elements" as="element()*"/>
      <xsl:param name="src-1st-da-tokenized" as="document-node()*"/>
      <!--<xsl:variable name="itemized-tok-elements"
         select="tan:expand-ref($tok-elements, true(), $src-1st-da-tokenized)"/>-->
      <xsl:for-each select="$tok-elements">
         <xsl:variable name="this-tok" select="."/>
         <xsl:variable name="this-div"
            select="$src-1st-da-tokenized/tan:TAN-T[@src = $this-tok/@src]/tan:body/tan:div[@ref = $this-tok/@ref]"/>
         <xsl:variable name="token-pos" select="tan:get-tok-nos($this-div, $this-tok)"/>
         <xsl:for-each select="$token-pos">
            <xsl:variable name="this-n" select="."/>
            <xsl:for-each select="$this-tok">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="n" select="$this-n"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:get-tok-nos" as="xs:integer*">
      <!-- returns the integer values of tokens in a given <div>
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
         <xsl:variable name="this-val" select="(tan:normalize-text(@val), '.')[1]"/>
         <xsl:variable name="these-matches" select="$tokenized-div/tan:tok[matches(., $this-val)]"/>
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
                  <xsl:copy-of select="-3"/>
               </xsl:when>
               <xsl:when test="not($tokenized-div/tan:tok)">
                  <xsl:copy-of select="-2"/>
               </xsl:when>
               <xsl:when test="count($these-matches) lt $this-pos">
                  <xsl:copy-of select="-1"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of
                     select="count($these-matches[$this-pos]/preceding-sibling::tan:tok) + 1"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:sequence-expand" xml:id="f-sequence-expand" as="xs:integer*">
      <!-- input: one string of concise TAN selectors (used by @poss, @chars, @segs), 
            and one integer defining the value of 'last'
            output: a sequence of numbers representing the positions selected, unsorted, and retaining
            duplicate values.
            E.g., ("2 - 4, last-5 - last, 36", 50) -> (2, 3, 4, 45, 46, 47, 48, 49, 50, 36)
            Errors will not be flagged; they must be processed by functions that invoke this one by
            checking for values less than zero or greater than the max. The one exception are ranges
            that ask for negative steps such as '4 - 2' or '1 - last-5' (where $max = 3), in which case 
            each item will be simply -1.
        -->
      <xsl:param name="selector" as="xs:string?"/>
      <xsl:param name="max" as="xs:integer?"/>
      <!-- first normalize syntax -->
      <xsl:variable name="pass-1" select="replace($selector, '(\d)\s*-\s*(last|\d)', '$1 - $2')"/>
      <xsl:variable name="pass-2" select="replace($pass-1, '(\d)\s+(\d)', '$1, $2')"/>
      <!-- replace 'last' with max value as string -->
      <xsl:variable name="selector-norm" select="replace($pass-2, 'last', string($max))"/>
      <xsl:variable name="seq-a" select="tokenize(normalize-space($selector-norm), '\s*,\s+')"/>
      <xsl:copy-of
         select="
            for $i in $seq-a
            return
               if (matches($i, ' - '))
               then
                  for $j in tan:string-subtract(tokenize($i, ' - ')[1]),
                     $k in tan:string-subtract(tokenize($i, ' - ')[2])
                  return
                     if ($j gt $k) then
                        for $l in ($k to $j)
                        return
                           -1
                     else
                        ($j to $k)
               else
                  tan:string-subtract($i)"
      />

   </xsl:function>
   <xsl:function name="tan:string-subtract" xml:id="f-string-subtract" as="xs:integer">
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

   <!-- This concludes functions and templates essential to transforming all class-2 files. 
      This is not the end of the story, however, since specific class-2 formats require further 
      transformation for other purposes.
   -->


   <!-- PART III.
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
         <xsl:variable name="is-flat" select="tan:is-flat-class-1(.)"/>
         <n-types src="{$this-src-id}">
            <xsl:variable name="n-vals" as="element()*">
               <xsl:for-each select="*/tan:head/tan:declarations/tan:div-type">
                  <xsl:variable name="this-div-type-id" select="@xml:id"/>
                  <xsl:variable name="these-ns" as="xs:string*">
                     <xsl:choose>
                        <xsl:when test="$is-flat = true()">
                           <xsl:for-each
                              select="$this-doc/tan:TAN-T/tan:body/tan:div, tei:TEI/tei:text/tei:body/tei:div">
                              <xsl:variable name="this-type" select="tokenize(@type, '\W+')"/>
                              <xsl:variable name="this-n" select="tokenize(@n, '\W+')"/>
                              <xsl:for-each select="$this-type">
                                 <xsl:variable name="pos" select="position()"/>
                                 <xsl:copy-of
                                    select="
                                       if (. = $this-div-type-id) then
                                          $this-n[$pos]
                                       else
                                          ()"
                                 />
                              </xsl:for-each>
                           </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:copy-of
                              select="
                                 $this-doc//(tan:div,
                                 tei:div)[@type = $this-div-type-id]/@n"
                           />
                        </xsl:otherwise>
                     </xsl:choose>
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

   <xsl:function name="tan:ordinal" xml:id="f-ordinal" as="xs:string+">
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

   <xsl:function name="tan:get-ucd-decomp" xml:id="v-ucd-decomp">
      <xsl:copy-of select="doc('string-base-translate.xml')"/>
   </xsl:function>
   <xsl:function name="tan:string-base" xml:id="f-string-base" as="xs:string?">
      <!-- This function takes any string and replaces every character with its base Unicode character.
      E.g., ἀνθρὠρους - > ανθρωρουσ
      This is useful for preparing text to be searched without respect to accents
      -->
      <xsl:param name="arg" as="xs:string?"/>
      <xsl:variable name="ucd-decomp" select="tan:get-ucd-decomp()"/>
      <xsl:value-of
         select="translate($arg, $ucd-decomp/tan:translate/tan:mapString, $ucd-decomp/tan:translate/tan:transString)"
      />
   </xsl:function>

   <xsl:function name="tan:expand-search" xml:id="f-expand-search" as="xs:string?">
      <!-- This function takes a string representation of a regular expression pattern and replaces every unescaped
      character with a character class that lists all Unicode characters that would recursively decompose to that base
      character.
      E.g., 'word' - > '[wŵʷẁẃẅẇẉẘⓦｗ𝐰𝑤𝒘𝓌𝔀𝔴𝕨𝖜𝗐𝘄𝘸𝙬𝚠][oºòóôõöōŏőơǒǫǭȍȏȫȭȯȱᵒṍṏṑṓọỏốồổỗộớờởỡợₒℴⓞ㍵ｏ𝐨𝑜𝒐𝓸𝔬𝕠𝖔𝗈𝗼𝘰𝙤𝚘][rŕŗřȑȓʳᵣṙṛṝṟⓡ㎭㎮㎯ｒ𝐫𝑟𝒓𝓇𝓻𝔯𝕣𝖗𝗋𝗿𝘳𝙧𝚛][dďǆǳᵈḋḍḏḑḓⅆⅾⓓ㍲㍷㍸㍹㎗㏈ｄ𝐝𝑑𝒅𝒹𝓭𝔡𝕕𝖉𝖽𝗱𝘥𝙙𝚍]' 
      This function is useful for cases where it is more efficient to change the search term rather than to transform
      the text to be searched into base characters.
      -->
      <xsl:param name="regex" as="xs:string?"/>
      <xsl:variable name="ucd-decomp" select="tan:get-ucd-decomp()"/>
      <xsl:variable name="output" as="xs:string*">
         <xsl:for-each select="1 to string-length($regex)">
            <xsl:variable name="pos" select="."/>
            <xsl:variable name="char" select="substring($regex, $pos, 1)"/>
            <xsl:variable name="prev-char" select="substring($regex, $pos - 1, 1)"/>
            <xsl:variable name="reverse-translate-match"
               select="$ucd-decomp/tan:translate/tan:reverse/tan:transString[text() = $char]"/>
            <xsl:choose>
               <xsl:when
                  test="$prev-char = '\' or ($prev-char != '\' and matches($char, $regex-escaping-characters))">
                  <xsl:value-of select="$char"/>
               </xsl:when>
               <xsl:when test="$reverse-translate-match">
                  <xsl:value-of
                     select="concat('[', $char, string-join($reverse-translate-match/tan:mapString, ''), ']')"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$char"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($output, '')"/>
   </xsl:function>

   <!-- everything below was thought in March 2016 to be deletable, but commented out, just in case I was wrong -->
   <!--<xsl:function name="tan:src-ids-to-nos" xml:id="f-src-ids-to-nos" as="xs:integer*">
      <!-\- Input: values of any number of @src (@xml:id values of sources)
      Output: sequence of integers for all sources 
      If input is an empty string, or the format lacks ids for sources, output = 1
      E.g., ('src-a src-d', 'src-b src-d') - > (1, 4, 2, 4)
      () - > 1
      -\->
      <xsl:param name="src-id-refs" as="xs:string*"/>
      <xsl:variable name="src-id-refs-norm" select="tan:normalize-text($src-id-refs)"/>
      <xsl:choose>
         <xsl:when test="exists($src-id-refs-norm) and not($source-lacks-id)">
            <xsl:for-each select="$src-id-refs-norm">
               <xsl:variable name="this-src-string" select="."/>
               <xsl:choose>
                  <xsl:when test="$this-src-string = '*'">
                     <xsl:copy-of select="$src-count"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of
                        select="
                           for $i in tokenize($this-src-string, '\s+')
                           return
                              index-of($src-ids-all, $i)"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="1"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>-->
   <!--<xsl:function name="tan:div-type-eq" xml:id="f-div-type-eq" as="xs:integer*">
      <!-\- Input: digit representing the position of the div-type to be checked within the sequence of all div-types of all sources
      Output: digit representing the smallest position of the div-type that is equivalent, within the same sequence
      E.g., 22 - > 3 -\->
      <xsl:param name="div-type-nos" as="xs:integer*"/>
      <xsl:variable name="all" select="tan:get-src-1st-da-heads()/tan:declarations/tan:div-type"/>
      <xsl:variable name="these-div-type-iris"
         select="
            for $i in $div-type-nos
            return
               $all[$i]/tan:IRI"/>
      <xsl:variable name="matches" as="xs:integer*">
         <xsl:for-each select="$all">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="this-div-type" select="."/>
            <xsl:if test="$this-div-type[tan:IRI = $these-div-type-iris]">
               <xsl:copy-of select="$pos"/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy-of
         select="
            if (count($matches) gt count($div-type-nos)) then
               tan:div-type-eq($matches)
            else
               min($div-type-nos)"
      />
   </xsl:function>-->

   <!--<xsl:function name="tan:pick-tokenized-prepped-class-1-data"
      xml:id="f-pick-tokenized-prepped-class-1-data" as="element()*">
      <!-\- Input: tan:tok, complete with @src, @ref, @pos|@val 
         Output: elements, 1 per source, deep copy of appropriate tree generated 
         by tan:tokenize-prepped-class-1-data() -\->
      <xsl:param name="tok-element" as="element()"/>
      <xsl:variable name="this-src-list" select="tan:src-ids-to-nos($tok-element/@src)"/>
      <xsl:variable name="help-requested" select="tan:help-requested($tok-element)"/>
      <xsl:variable name="this-refs-norm" select="tan:normalize-refs($tok-element/@ref)"/>
      <xsl:variable name="this-ord"
         select="
            if ($help-requested) then
               '1 - last'
            else
               if ($tok-element/@pos) then
                  normalize-space(replace($tok-element/@pos, '\?', ''))
               else
                  ()"/>
      <xsl:variable name="this-val"
         select="
            if ($help-requested) then
               if (matches($tok-element/@val, '^\s+\?$|^\?\s+$')) then
                  ()
               else
                  normalize-space(replace($tok-element/@val, '\s+\?|\?\s+', ''))
            else
               if (exists($tok-element/@val)) then
                  normalize-space($tok-element/@val)
               else
                  ()"/>
      <xsl:variable name="src-ref-subset"
         select="tan:pick-prepped-class-1-data($this-src-list, $this-refs-norm)"/>
      <xsl:variable name="src-ref-subset-tokenized"
         select="tan:tokenize-prepped-class-1-doc($src-ref-subset)"/>
      <xsl:for-each select="$src-ref-subset-tokenized">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="tan:div">
               <xsl:variable name="this-div" select="."/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:variable name="this-last"
                     select="
                        if (exists($this-val))
                        then
                           count(tan:tok[matches(., $this-val)])
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
                     <xsl:variable name="this-tok"
                        select="
                           if (exists($this-val)) then
                              $this-div/tan:tok[matches(., $this-val)][$this-ord-item]
                           else
                              $this-div/tan:tok[$this-ord-item]"/>
                     <xsl:choose>
                        <xsl:when test="exists($this-tok)">
                           <xsl:copy-of select="$this-tok"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <tok error="{string-join(($this-val, string($this-ord-item)),' ')}"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each>
               </xsl:copy>
            </xsl:for-each>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>-->
   <!--<xsl:function name="tan:pick-tokenized-prepped-class-1-data"
      xml:id="f-pick-tokenized-prepped-class-1-data" as="document-node()*">
      <!-\- Input: tan:tok, complete with @src, @ref, @pos|@val 
         Output: elements, 1 per source, deep copy of appropriate tree generated 
         by tan:tokenize-prepped-class-1-data() -\->
      <xsl:param name="tok-element" as="element()*"/>
      <xsl:variable name="all-tok-elements"
         select="tan:distribute-src-and-ref($tok-element, false())"/>
      <xsl:variable name="all-tok-elements-sorted" as="element()*">
         <xsl:for-each-group select="$all-tok-elements" group-by="@src">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:for-each-group select="current-group()" group-by="@ref">
               <xsl:copy-of select="functx:distinct-deep(current-group())"/>
            </xsl:for-each-group> 
         </xsl:for-each-group> 
      </xsl:variable>
      <xsl:variable name="this-src-list" select="distinct-values($all-tok-elements/@src)" as="xs:integer*"/>
      <xsl:variable name="this-refs-norm"
         select="
            for $i in $this-src-list
            return
               string-join($all-tok-elements-sorted[@src = $i]/@ref, ' , ')"
      />
      <xsl:variable name="src-ref-subset"
         select="tan:pick-prepped-class-1-data($this-src-list, $this-refs-norm)" as="document-node()*"/>
      <xsl:variable name="src-ref-subset-tokenized"
         select="tan:tokenize-prepped-class-1-doc($src-ref-subset)"/>
      <xsl:copy-of select="$src-ref-subset-tokenized"/>
   </xsl:function>-->


   <!--<xsl:function name="tan:ref-rename-reverse" xml:id="f-ref-rename-reverse" as="xs:string?">
      <!-\- The reverse of tan:ref-rename()
         E.g., "bk ch v", "Gen 5 4", 4 - > "Gn V iv" 
      -\->
      <xsl:param name="types" as="xs:string?"/>
      <xsl:param name="ns" as="xs:string?"/>
      <xsl:param name="src-no" as="xs:integer?"/>
      <xsl:variable name="rename-div-ns" select="tan:get-rename-div-ns()"/>
      <xsl:variable name="type-seq" select="tokenize($types, $separator-hierarchy-regex)"/>
      <xsl:variable name="ref-seq" select="tokenize($ns, $separator-hierarchy-regex)"/>
      <xsl:variable name="ref-seq-repl" as="xs:string*">
         <xsl:for-each select="$ref-seq">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="this-type" select="$type-seq[$pos]"/>
            <xsl:variable name="this-n" select="."/>
            <xsl:variable name="this-n-rename-prep"
               select="
                  $rename-div-ns/tan:source[$src-no]/tan:div-type[@div-type = $this-type]"
            />
            <xsl:variable name="this-n-rename"
               select="
                  if ($this-n-rename-prep/tan:rename[@new = $this-n]) then
                     $this-n-rename-prep/tan:rename[@new = $this-n]/@old
                  else
                     if ($this-n-rename-prep/tan:rename[@old = '#a'] and matches($this-n, $n-type-pattern[4])) then
                        (tan:aaa-to-int($this-n))
                     else
                        if ($this-n-rename-prep/tan:rename[@old = '#i'] and matches($this-n, $n-type-pattern[1])) then
                           (tan:rom-to-int($this-n))
                        else
                           ()"/>
            <xsl:value-of select="($this-n-rename, $this-n)[1]"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($ref-seq-repl, $separator-hierarchy)"/>
   </xsl:function>-->

   <!--<xsl:function name="tan:itemize-leaf-refs" xml:id="f-itemize-leaf-refs" as="xs:string*">
      <!-\- Turns a compound ref string into a sequence of atomized refs to leaf divs only in the source provided
         Input: normalized ref sequence (value of @ref), source number
         Output: sequence of values of @ref for leaf divs from $src-1st-da-data
      -\->
      <xsl:param name="ref-range-norm" as="xs:string"/>
      <xsl:param name="src" as="xs:integer"/>
      <xsl:param name="src-1st-da-data-prepped" as="document-node()*"/>
      <xsl:variable name="ref-range-seq-1" select="tokenize($ref-range-norm, ' , ')"/>
      <xsl:for-each select="$ref-range-seq-1">
         <xsl:variable name="start" select="tokenize(., ' - ')[1]"/>
         <xsl:variable name="end" select="tokenize(., ' - ')[2]"/>
         <xsl:choose>
            <xsl:when test="exists($end)">
               <xsl:variable name="nodes"
                  select="
                     $src-1st-da-data-prepped[$src]/tan:div[matches(@ref, concat('^', $end))][text()]/(self::tan:div,
                     preceding-sibling::tan:div[text()]) except $src-1st-da-data-prepped[$src]/tan:div[@ref = $start]/preceding-sibling::tan:div"/>
               <xsl:copy-of select="$nodes/@ref"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of
                  select="$src-1st-da-data-prepped[$src]/tan:div[matches(@ref, concat('^', $start))][text()]/@ref"
               />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>-->

</xsl:stylesheet>
