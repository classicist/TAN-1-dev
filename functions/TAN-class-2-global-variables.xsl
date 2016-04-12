<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
   exclude-result-prefixes="xs math xd tan tei fn functx xi" version="2.0">

   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>March 18, 2016</xd:p>
         <xd:p>Intended to be included alongside TAN-class-2-functions.xsl, to facilitate access to
            the class-2 and class-1 documents.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:param name="src-filter" select="('1 - last')" as="xs:string*"/>
   <xsl:variable name="self1" select="tan:get-self-expanded-1(true())"/>
   <xsl:variable name="srcs-raw" select="tan:get-src-1st-da($src-filter)" as="document-node()*"/>
   <xsl:variable name="src-ids-picked"
      select="$src-ids[position() = tan:sequence-expand($src-filter, count($src-ids))]"/>
   <xsl:variable name="srcs-resolved"
      select="tan:get-src-1st-da-resolved($srcs-raw, $src-ids-picked)" as="document-node()*"/>
   <xsl:variable name="self2" select="tan:get-self-expanded-2($self1, $srcs-resolved)"/>
   <xsl:variable name="srcs-prepped" select="tan:get-src-1st-da-prepped($self2, $srcs-resolved)"
      as="document-node()*"/>
   <xsl:variable name="self3" select="tan:get-self-expanded-3($self2, $srcs-prepped)"/>
   <xsl:param name="ref-filter" select="$self3//(tan:anchor-div-ref, tan:div-ref)" as="element()*"/>
   <xsl:variable name="srcs-prepped-and-filtered"
      select="tan:pick-prepped-class-1-data($ref-filter, $srcs-prepped, false())"/>
   <xsl:variable name="srcs-tokenized" select="tan:get-src-1st-da-tokenized($self2, $srcs-prepped)"
      as="document-node()*"/>
   <xsl:variable name="srcs-tokenized-and-filtered"
      select="tan:get-src-1st-da-tokenized($self2, $srcs-prepped-and-filtered)"
      as="document-node()*"/>
   <xsl:variable name="self4" select="tan:get-self-expanded-4($self3, $srcs-tokenized)"/>

   <!-- CONTEXTUAL DATA -->
   <xsl:variable name="srcs-base-uris" as="element()*">
      <xsl:for-each select="$srcs-raw">
         <xsl:variable name="pos" select="position()"/>
         <base-uris src="{$src-ids[$pos]}" base="{base-uri()}"/>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="srcs-context-1st-da-locations" as="element()*">
      <xsl:for-each
         select="$srcs-resolved/*/tan:head/tan:see-also[tan:relationship/@which = 'context'][not(tan:IRI = $doc-id)]">
         <xsl:variable name="this-src" select="root()/*/@src"/>
         <xsl:variable name="this-base" select="$srcs-base-uris[@src = $this-src]/@base"/>
         <context src="{$this-src}" base="{$this-base}"
            href="{tan:first-loc-available(.,$this-base)}"/>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="srcs-context-resolved"
      select="
         for $i in $srcs-context-1st-da-locations
         return
            if ($i/@href = '') then
               $empty-doc
            else
               tan:resolve-doc(document($i/@href), $i/@src, false())"/>
   <xsl:variable name="srcs-context-self-1" as="document-node()*"
      select="tan:get-self-expanded-1($srcs-context-resolved, true())"/>
   <xsl:variable name="srcs-context-self-2" as="document-node()*">
      <xsl:for-each select="$srcs-context-self-1">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy-of select="tan:get-self-expanded-2(., $srcs-resolved[*/@src = $this-src])"/>
      </xsl:for-each>
   </xsl:variable>
   <!--<xsl:variable name="srcs-context-self-3" as="document-node()*">
      <xsl:for-each select="$srcs-context-self-2">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy-of select="tan:get-self-expanded-3(., $srcs-prepped[*/@src = $this-src])"/>
      </xsl:for-each>
   </xsl:variable>-->
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
                     <src-key old="1" new="{tan:TAN-LM/@src}"></src-key>
                  </xsl:when>
                  <xsl:otherwise><xsl:for-each select="$hub-srcs">
                  <xsl:variable name="this-hub-src" select="."/>
                  <src-key old="{$these-srcs[tan:IRI = $this-hub-src/tan:IRI]/@xml:id}"
                     new="{@xml:id}"/>
               </xsl:for-each></xsl:otherwise></xsl:choose>
            </xsl:variable>
            <xsl:document>
               <xsl:apply-templates mode="prep-rim-pass-1">
                  <xsl:with-param name="src-key" select="$src-key"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$rim">
         <xsl:variable name="these-spokes"
            select="
               for $i in */tan:head/tan:source
               return
                  $spokes[tan:TAN-T/@id = $i/tan:IRI]"/>
         <xsl:variable name="these-srcs" select="$these-spokes/tan:TAN-T/@src"/>
         <xsl:variable name="is-multi-src"
            select="
               if (tan:TAN-LM) then
                  false()
               else
                  true()"/>
         <xsl:variable name="these-sdts"
            select="
               */tan:head/tan:declarations/tan:suppress-div-types[if ($is-multi-src = true()) then
                  tokenize((@src, '1')[1], '\s+') = $these-srcs
               else
                  true()]"/>
         <xsl:variable name="these-tds"
            select="
               */tan:head/tan:declarations/tan:token-definition[if ($is-multi-src = true()) then
                  tokenize((@src, '1')[1], '\s+') = $these-srcs
               else
                  true()]"/>
         <xsl:variable name="these-rdns"
            select="
               */tan:head/tan:declarations/tan:rename-div-ns[if ($is-multi-src = true()) then
                  tokenize((@src, '1')[1], '\s+') = $these-srcs
               else
                  true()]"/>
         <xsl:document><xsl:choose>
            <xsl:when
               test="
                  not(every $i in $these-sdts
                     satisfies
                     some $j in $hub-sdts[tokenize((@src, '1')[1], '\s+') = $these-srcs]
                        satisfies deep-equal($i, $j)) or not(every $i in $hub-sdts[tokenize((@src, '1')[1], '\s+') = $these-srcs]
                     satisfies
                     some $j in $these-sdts
                        satisfies deep-equal($i, $j))">
               <xsl:document>
                  <error src="{$these-srcs}">Reconcile suppress-div-types before using this
                     function. <xsl:copy-of select="$these-sdts"/>
                     <xsl:copy-of select="$hub-sdts[tokenize((@src, '1')[1], '\s+') = $these-srcs]"
                     />
                  </error>
               </xsl:document>
            </xsl:when>
            <xsl:when
               test="not($these-tds/@regex = $hub-tds[tokenize((@src, '1')[1], '\s+')]/@regex)">
               <xsl:document>
                  <xsl:copy-of select="$rim"/>
                  <error src="{$these-srcs}">Reconcile token-definitions before using this function.
                           <these-srcs><xsl:value-of select="$these-srcs"/></these-srcs>
                     <xsl:copy-of select="*/tan:head/tan:declarations/tan:token-definition"/>
                  </error>
               </xsl:document>
            </xsl:when>
            <xsl:when
               test="not(exists($these-rdns) or exists($hub-rdns[tokenize((@src, '1')[1], '\s+') = $these-srcs]))">
               <xsl:sequence select="."/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="spokes-recalced">
                  <xsl:choose>
                     <xsl:when test="not(exists($these-rdns))">
                        <xsl:sequence select="$spokes[*/@src = $these-srcs]"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of select="tan:get-src-1st-da-prepped(., $srcs-resolved[*/@src = $these-srcs])"></xsl:copy-of>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               <xsl:variable name="conversions" as="element()*">
                  <xsl:for-each select="$these-srcs">
                     <xsl:variable name="this-src" select="."/>
                     <xsl:for-each select="$spokes-recalced/tan:TAN-T[@src = $this-src]/tan:body//tan:div">
                        <xsl:variable name="starting-ref" select="@ref"/>
                        <xsl:variable name="orig-ref" select="(@orig-ref, @ref)[1]"/>
                        <xsl:variable name="ending-ref" select="$srcs-prepped/*[@src = $this-src]/tan:body//tan:div[(@orig-ref, @ref)[1] = $orig-ref]/@ref"/>
                        <convert src="{$this-src}" old="{$starting-ref}" new="{$ending-ref}"/>
                     </xsl:for-each>
                  </xsl:for-each>
               </xsl:variable>
                  <xsl:variable name="rim-self-3" as="document-node()*"
                     select="tan:get-self-expanded-3(., $spokes-recalced)"/>
               <xsl:apply-templates select="$rim-self-3" mode="prep-rim-pass-2">
                  <xsl:with-param name="key" select="$conversions"/>
               </xsl:apply-templates>
            </xsl:otherwise>
         </xsl:choose></xsl:document>
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

</xsl:stylesheet>
