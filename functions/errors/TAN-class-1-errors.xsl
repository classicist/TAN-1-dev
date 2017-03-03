<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   exclude-result-prefixes="#all" version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>August 18, 2016</xd:p>
         <xd:p>Variables, functions, and templates for marking class-1 errors in TAN files. To be
            used in conjunction with TAN-core-functions.xsl. Includes items related to help
            requests.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:template match="tan:see-also" mode="class-1-errors">
      <xsl:variable name="pos" select="count(preceding-sibling::tan:see-also) + 1"/>
      <xsl:variable name="target-doc"
         select="
            if (exists($see-alsos-resolved)) then
               $see-alsos-resolved[$pos]
            else
               tan:resolve-doc(tan:get-1st-doc(.))"
      />
      <xsl:variable name="target-prepped" select="tan:prep-resolved-class-1-doc($target-doc)"/>
      <xsl:variable name="this-doc-text" select="tan:text-join(/tan:TAN-T/tan:body, true())"/>
      <xsl:variable name="target-doc-text"
         select="tan:text-join($target-doc/*/(tan:body, tei:text/tei:body))"/>
      <xsl:variable name="text-diff" select="tan:diff($this-doc-text, $target-doc-text)"/>
      <xsl:variable name="text-diff-analyzed">
         <xsl:variable name="pass1">
            <xsl:apply-templates select="$text-diff" mode="c1-stamp-string-length"/>
         </xsl:variable>
         <xsl:apply-templates select="$pass1" mode="c1-stamp-string-pos">
            <xsl:with-param name="parent-pos" select="0"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:variable name="other-models"
         select="(preceding-sibling::tan:see-also, following-sibling::tan:see-also)[tan:has-relationship(., 'model', ())]"/>
      <xsl:variable name="self-and-model-skeletons-merged"
         select="tan:merge-sources(($self-prepped, $target-prepped), false(), false(), ())"/>
      <xsl:variable name="skeleton-divs" select="$self-and-model-skeletons-merged//*:div"/>
      <xsl:variable name="model-divergence-threshold" select="0.1"/>
      <xsl:variable name="divs-used-there-but-not-here" select="$skeleton-divs[@src = '2']"/>
      <xsl:variable name="divs-used-here-but-not-there" select="$skeleton-divs[@src = '1']"/>
      <xsl:variable name="count-divs" select="count($skeleton-divs)"/>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="tan:has-relationship(., 'alternatively divided edition', ())">
            <xsl:if
               test="not(/*/tan:head/tan:source/tan:IRI = $target-doc/*/tan:head/tan:source/tan:IRI)">
               <xsl:copy-of select="tan:error('cl101')"/>
            </xsl:if>
            <xsl:if
               test="not(/*/tan:head/tan:declarations/tan:work/tan:IRI = $target-doc/*/tan:head/tan:declarations/tan:work/tan:IRI)">
               <xsl:copy-of select="tan:error('cl102')"/>
            </xsl:if>
            <xsl:if
               test="
                  exists(/tan:TAN-T/tan:head/tan:declarations/tan:version) and
                  exists($target-doc/*/tan:head/tan:declarations/tan:version) and
                  not(/*/tan:head/tan:declarations/tan:version/tan:IRI = $target-doc/*/tan:head/tan:declarations/tan:version/tan:IRI)">
               <xsl:copy-of select="tan:error('cl103')"/>
            </xsl:if>
            <xsl:if test="exists($text-diff/(tan:s1, tan:s2))">
               <xsl:copy-of select="tan:error('cl104', (), $text-diff-analyzed)"/>
            </xsl:if>
         </xsl:if>
         <xsl:if test="tan:has-relationship(., 'model', ())">
            <xsl:if
               test="not(/*/tan:head/tan:declarations/tan:work/tan:IRI = $target-doc/*/tan:head/tan:declarations/tan:work/tan:IRI)">
               <xsl:copy-of select="tan:error('cl105')"/>
            </xsl:if>
            <xsl:if test="exists($other-models)">
               <xsl:copy-of select="tan:error('cl106')"/>
            </xsl:if>
            <xsl:if
               test="exists($divs-used-there-but-not-here) or exists($divs-used-here-but-not-there)">
               <xsl:variable name="this-message">
                  <xsl:text>This file and its model diverge: </xsl:text>
                  <xsl:value-of
                     select="
                        if (exists($divs-used-here-but-not-there)) then
                           concat('uniquely here: ', string-join($divs-used-here-but-not-there/@ref, '; '), ' ')
                        else
                           ()"/>
                  <xsl:value-of
                     select="
                        if (exists($divs-used-there-but-not-here)) then
                           concat('unique to model: ', string-join($divs-used-there-but-not-here/@ref, '; '), ' ')
                        else
                           ()"
                  />
               </xsl:variable>
               <xsl:copy-of select="tan:error('cl107', $this-message)"/>
            </xsl:if>
         </xsl:if>
         <xsl:apply-templates mode="class-1-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:work" mode="class-1-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="count(tokenize(tan:normalize-text(@include), '\s')) gt 1">
            <xsl:copy-of select="tan:error('cl108')"/>
         </xsl:if>
         <xsl:apply-templates mode="class-1-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div" mode="class-1-errors">
      <xsl:variable name="text-with-bad-modifiers-1" select="text()[matches(., '^\p{M}')]"/>
      <xsl:variable name="text-with-bad-modifiers-2" select="text()[matches(., '\s\p{M}')]"/>
      <xsl:variable name="text-with-bad-characters"
         select="text()[matches(., $regex-characters-not-permitted)]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="@ref = $self-leaf-div-flatref-duplicates">
            <xsl:copy-of select="tan:error('cl109', @ref)"/>
         </xsl:if>
         <xsl:if test="not(matches(., '\S')) and not(exists(@see))">
            <xsl:copy-of select="tan:error('cl110')"/>
         </xsl:if>
         <xsl:if test="exists($text-with-bad-modifiers-1)">
            <xsl:copy-of
               select="tan:error('cl111', (), replace($text-with-bad-modifiers-1[1], '^\p{M}+', ''))"
            />
         </xsl:if>
         <xsl:if test="exists($text-with-bad-modifiers-2)">
            <xsl:copy-of
               select="tan:error('cl112', (), replace($text-with-bad-modifiers-2[1], '\s+(\p{M})', '$1'))"
            />
         </xsl:if>
         <xsl:if test="exists($text-with-bad-characters)">
            <xsl:copy-of
               select="tan:error('cl113', (), replace($text-with-bad-characters[1], $regex-characters-not-permitted, ''))"
            />
         </xsl:if>
         <xsl:apply-templates mode="class-1-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:diff" mode="class-1-copy-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="*" group-starting-with="tan:common">
            <xsl:variable name="this-common" select="current-group()/self::tan:common"/>
            <xsl:variable name="this-s1" select="current-group()/self::tan:s1"/>
            <xsl:variable name="this-s2" select="current-group()/self::tan:s2"/>
            <xsl:choose>
               <xsl:when test="exists($this-s1)">
                  <xsl:copy-of select="$this-common"/>
                  <s1>
                     <xsl:copy-of select="$this-s1/@*"/>
                     <xsl:for-each select="1 to $this-s1/@s1-length">
                        <xsl:variable name="s1-floor" select="(. - 1) div $this-s1/@s1-length"/>
                        <xsl:variable name="s1-ceiling" select=". div $this-s1/@s1-length"/>
                        <xsl:variable name="s2-start"
                           select="($this-s2/@s2-length * $s1-floor) + 1"/>
                        <xsl:variable name="s2-end"
                           select="($this-s2/@s2-length * $s1-ceiling)"/>
                        <xsl:variable name="replacement-text"
                           select="substring($this-s2, $s2-start, $s2-end - $s2-start + 1)"/>
                        <c s1-pos="{. + $this-s1/@s1-pos - 1}" start="{$s2-start}" end="{$s2-end}">
                           <xsl:value-of select="$replacement-text"/>
                        </c>
                     </xsl:for-each>
                     <xsl:copy-of select="$this-s1/text()"/>
                  </s1>
                  <xsl:copy-of select="$this-s2"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="$this-common"/>
                  <xsl:if test="exists($this-s2)">
                     <s2>
                        <xsl:copy-of select="$this-s2/@*"/>
                        <c s1-pos="{($this-common/@s1-pos, 1)[1] + $this-common/@s1-length}">
                           <xsl:value-of select="$this-s2/text()"/>
                        </c>
                     </s2>
                  </xsl:if>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[@string-length]" mode="class-1-copy-errors">
      <xsl:param name="copy-diff-prepped" as="element()?" tunnel="yes"/>
      <xsl:variable name="this-div" select="."/>
      <xsl:variable name="these-chars"
         select="
            for $i in (1 to @string-length)
            return
               $i + @string-pos - 1"/>
      <xsl:variable name="flags" select="$copy-diff-prepped/*[tan:c/@s1-pos = $these-chars]"/>
      <xsl:variable name="replacement" as="xs:string*">
         <xsl:for-each select="1 to @string-length">
            <xsl:variable name="this-pos" select=". + $this-div/@string-pos - 1"/>
            <xsl:variable name="this-flag" select="$copy-diff-prepped/*/tan:c[@s1-pos = $this-pos]"/>
            <xsl:variable name="this-char" select="substring($this-div/text(), ., 1)"/>
            <xsl:choose>
               <xsl:when test="$this-flag/parent::tan:s1">
                  <xsl:value-of select="$this-flag/text()"/>
               </xsl:when>
               <xsl:when test="$this-flag/parent::tan:s2">
                  <xsl:value-of select="concat($this-flag/text(),$this-char)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$this-char"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="this-message" select="concat('Text in copy: ', string-join($replacement,''))"
      />
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($flags)">
            <xsl:copy-of select="tan:error('cl104', $this-message, string-join($replacement, ''))"
            />
         </xsl:if>
         <xsl:apply-templates mode="class-1-copy-errors"/>
      </xsl:copy>
   </xsl:template>
</xsl:stylesheet>
