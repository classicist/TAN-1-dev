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
   <xsl:variable name="srcs-common-skeleton" as="document-node()*">
      <xsl:choose>
         <xsl:when test="$self2/tan:TAN-A-div">
            <xsl:for-each select="$self2/tan:TAN-A-div/tan:body/tan:group[tan:work]">
               <xsl:variable name="these-works" select="tan:work/@src"/>
               <xsl:copy-of select="tan:get-src-skeleton($srcs-prepped[*/@src = $these-works])"/>
            </xsl:for-each> 
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="tan:get-src-skeleton($srcs-prepped)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:variable name="self3" select="tan:get-self-expanded-3($self2, $srcs-prepped)"/>
   <xsl:param name="ref-filter" select="$self3//(tan:anchor-div-ref, tan:div-ref, tan:tok)" as="element()*"/>
   <xsl:variable name="srcs-prepped-and-filtered"
      select="tan:pick-prepped-class-1-data($ref-filter, $srcs-prepped, false())"/>
   <xsl:variable name="srcs-common-skeleton-filtered" select="tan:get-src-skeleton($srcs-prepped-and-filtered)"/>
   <xsl:variable name="srcs-tokenized" select="tan:get-src-1st-da-tokenized($self2, $srcs-prepped, true())"
      as="document-node()*"/>
   <xsl:variable name="srcs-tokenized-and-filtered"
      select="tan:get-src-1st-da-tokenized($self2, $srcs-prepped-and-filtered)"
      as="document-node()*"/>
   <xsl:variable name="srcs-with-lm-data" select="for $i in $srcs-tokenized return
      tan:get-src-1st-da-with-lms($i,$srcs-context-prepped[tan:TAN-LM/@src = $i/*/@src])"/>
   <xsl:variable name="self4"
      select="
         tan:get-self-expanded-4($self3, if ($self3/tan:TAN-A-div/tan:body/tan:split-leaf-div-at)
         then
            $srcs-tokenized-and-filtered
         else
            $srcs-prepped-and-filtered)"
   />

   <!-- CONTEXTUAL DATA -->
   <xsl:variable name="srcs-context-1st-da-locations" as="element()*">
      <xsl:for-each
         select="$srcs-resolved/*/tan:head/tan:see-also[tan:relationship/@which = 'context'][not(tan:IRI = $doc-id)]">
         <xsl:variable name="this-src" select="root()/*/@src"/>
         <xsl:variable name="this-base" select="root()/*/@base-uri"/>
         <context src="{$this-src}" href="{tan:first-loc-available(.,$this-base)}"/>
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
   <xsl:variable name="srcs-context-1" as="document-node()*"
      select="tan:get-self-expanded-1($srcs-context-resolved, false())"/>
   <xsl:variable name="srcs-context-2" as="document-node()*">
      <xsl:for-each select="$srcs-context-1">
         <xsl:variable name="this-src" select="*/@src"/>
         <xsl:copy-of select="tan:get-self-expanded-2(., $srcs-resolved[*/@src = $this-src])"/>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="srcs-context-prepped" select="tan:get-context-prepped($self3, $srcs-context-2, 
      $srcs-prepped, $srcs-resolved)" as="document-node()*"></xsl:variable>

</xsl:stylesheet>
