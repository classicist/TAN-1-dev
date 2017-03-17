<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
   <xsl:import href="../../functions/TAN-A-tok-functions.xsl"/>
   
   <xsl:output indent="yes"/>
   <!-- Stylesheet to transform a TAN-A-tok file. Offers the following features:
        1. Convert <tok> references to and from @pos and @val
        2. Recombine <align>s
        3. Re-sort
        4. Cleanup
    -->
   <xsl:param name="make-backup" as="xs:boolean" select="true()"/>
   <!-- If the value is 'pos' then all <tok> values will be converted to @pos; likewise for
    'val'; for any other value no such transformation occurs -->
   <xsl:param name="p2-convert-tok-refs-to-pos-or-val" as="xs:string?"/>
   <xsl:param name="p3-recombination" as="xs:boolean" select="true()"/>

   <!-- Sorting. Identify the element or attribute name upon which sorting should take place. 
        If the parameter does not exist, or value is a zero-length string, then no sorting
    happens. If a valid value is appended by \Wd(esc(ending)?)? then values will be sorted in 
    descending fashion; anything else results in ascending sorts. -->
   <xsl:param name="p5-primary-sort" as="xs:string?"/>
   <xsl:variable name="sort-options" as="element()*">
      <xsl:analyze-string select="$p5-primary-sort" regex="([123])\W?(d)?">
         <xsl:matching-substring>
            <sort n="{regex-group(1)}"
               order="{if (regex-group(2) = 'd') then 'descending' else 'ascending'}"/>
         </xsl:matching-substring>
      </xsl:analyze-string>
   </xsl:variable>
   <!-- Feedback and cleanup. -->
   <xsl:variable name="p7-include-feedback" as="xs:boolean" select="true()"/>

   <!-- ################################################################################# -->

   <!-- OUTPUT -->
   <xsl:template match="/">
      <!--<xsl:copy-of select="$revised-tok-doc"/>-->
      <!--<xsl:copy-of select="$consolidated-doc"/>-->
      <!--<xsl:copy-of select="$re-sorted-doc"/>-->
      <xsl:copy-of select="$final-results-with-feedback"/>
      <xsl:if test="$make-backup">
         <xsl:variable name="new-version-no" select="replace(string(current-dateTime()), '\D', '')"/>
         <xsl:variable name="new-uri"
            select="replace($doc-uri, '(.+)(\..+)$', concat('$1-', $new-version-no, '$2'))"/>
         <xsl:result-document href="{$new-uri}">
            <xsl:copy-of select="/"/>
         </xsl:result-document>
      </xsl:if>
   </xsl:template>

   <!-- Default template handling -->
   <xsl:template match="node()" mode="re-sort-p1 re-sort-p2 consolidate-aligns revise-tok">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <!-- STEP ONE: CONVERTING TO AND FROM @VAL AND @POS -->
   <xsl:variable name="revised-tok-doc" as="document-node()">
      <xsl:choose>
         <xsl:when test="$p2-convert-tok-refs-to-pos-or-val = ('pos', 'val')">
            <xsl:document>
               <xsl:apply-templates select="/" mode="revise-tok"/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="/"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:template match="tan:tok[not(matches(@pos, ',|-\s'))]" mode="revise-tok">
      <xsl:param name="pos-or-val-override" as="xs:string?"/>
      <xsl:variable name="pos-or-val"
         select="($pos-or-val-override, $p2-convert-tok-refs-to-pos-or-val)[1]"/>
      <xsl:variable name="this-tok" select="."/>
      <xsl:variable name="this-src" select="@src"/>
      <xsl:variable name="this-ref-norm" select="tan:normalize-refs(@ref)"/>
      <xsl:variable name="this-val-norm" select="(@val, '.+')[1]"/>
      <xsl:variable name="that-div"
         select="$srcs-tokenized-and-filtered/tan:TAN-T[@src = $this-src]/tan:body//tan:div[@ref = $this-ref-norm]"/>
      <xsl:variable name="tok-ceiling" select="count($that-div/tan:tok)"/>
      <xsl:variable name="this-pos-norm"
         select="
            if (@pos) then
               tan:sequence-expand(@pos, $tok-ceiling)
            else
               1"/>
      <xsl:for-each select="$this-pos-norm">
         <xsl:variable name="pos" select="."/>
         <xsl:variable name="that-tok"
            select="($that-div/tan:tok[tan:matches(., $this-val-norm)])[$pos]"/>
         <tok>
            <xsl:copy-of select="$this-tok/(@ref, @cert, @chars, @cont, @ed-when, @ed-who, @src)"/>
            <xsl:choose>
               <xsl:when test="$pos-or-val = 'pos'">
                  <xsl:attribute name="pos" select="$that-tok/@n"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="tok-val" select="$that-tok/text()"/>
                  <xsl:variable name="nth-tok-val"
                     select="count($that-tok/preceding-sibling::tan:tok[. = $tok-val]) + 1"/>
                  <xsl:attribute name="val" select="$tok-val"/>
                  <xsl:if test="$nth-tok-val gt 1">
                     <xsl:attribute name="pos" select="$nth-tok-val"/>
                  </xsl:if>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="$this-tok/comment()"/>
         </tok>
      </xsl:for-each>
   </xsl:template>

   <!-- STEP THREE: CONSOLIDATING <ALIGN>S -->
   <xsl:variable name="consolidated-doc" as="document-node()">
      <xsl:choose>
         <xsl:when test="$p3-recombination = true()">
            <xsl:document>
               <xsl:apply-templates select="$revised-tok-doc" mode="consolidate-aligns"/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$revised-tok-doc"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:template match="tan:body | tan:group" mode="consolidate-aligns">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:for-each-group select="tan:align" group-by="count(distinct-values(.//@src))">
            <xsl:choose>
               <xsl:when test="current-grouping-key() = 1">
                  <xsl:for-each-group select="current-group()"
                     group-by="
                        string-join(for $i in @*
                        return
                           concat(name($i), '#', $i), '##')">
                     <align>
                        <xsl:copy-of select="current-group()[1]/@*"/>
                        <xsl:copy-of select="current-group()/node()"/>
                     </align>
                  </xsl:for-each-group>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="current-group()"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:align" mode="consolidate-aligns"/>

   <!-- STEP FOUR: RE-SORT -->
   <xsl:variable name="re-sorted-doc" as="document-node()">
      <xsl:choose>
         <xsl:when test="exists($sort-options)">
            <xsl:variable name="pass-1" as="document-node()">
               <xsl:document>
                  <xsl:apply-templates select="$consolidated-doc" mode="re-sort-p1"/>
               </xsl:document>
            </xsl:variable>
            <xsl:document>
               <xsl:apply-templates select="$pass-1" mode="re-sort-p2"/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$consolidated-doc"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:variable name="srcs-ref-sequence-1"
      select="$srcs-tokenized-and-filtered/tan:TAN-T[@src = $head/tan:source[1]/@xml:id]/tan:body//@ref"
      as="xs:string*"/>
   <xsl:variable name="srcs-ref-sequence-2"
      select="$srcs-tokenized-and-filtered/tan:TAN-T[@src = $head/tan:source[2]/@xml:id]/tan:body//@ref"
      as="xs:string*"/>
   <xsl:template match="tan:align" mode="re-sort-p1">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="tan:tok"
            group-by="count(preceding-sibling::tan:tok[not(@cont)])">
            <xsl:sort select="current-group()[1]/@src"/>
            <xsl:sort
               select="
                  if (current-group()[1]/@src = $head/tan:source[1]/@xml:id) then
                     index-of($srcs-ref-sequence-1, current-group()[1]/@ref)
                  else
                     index-of($srcs-ref-sequence-2, current-group()[1]/@ref)"/>
            <xsl:copy-of select="current-group()"/>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:group | tan:body" mode="re-sort-p2">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:for-each select="tan:align">
            <xsl:sort order="{$sort-options[1]/@order}">
               <xsl:choose>
                  <xsl:when test="$sort-options[1]/@n = '1'">
                     <xsl:value-of
                        select="
                           if (tan:tok[@src = $head/tan:source[1]/@xml:id]) then
                              index-of($srcs-ref-sequence-1, (tan:tok[@src = $head/tan:source[1]/@xml:id])[1]/@ref)
                           else
                              count($srcs-ref-sequence-1)"
                     />
                  </xsl:when>
                  <xsl:when test="$sort-options[1]/@n = '2'">
                     <xsl:value-of
                        select="
                           if (tan:tok[@src = $head/tan:source[2]/@xml:id]) then
                              index-of($srcs-ref-sequence-2, (tan:tok[@src = $head/tan:source[2]/@xml:id])[1]/@ref)
                           else
                              count($srcs-ref-sequence-2)"
                     />
                  </xsl:when>
                  <xsl:when test="$sort-options[1]/@n = '3'">
                     <xsl:value-of select="(ancestor-or-self::*/@reuse-type)[last()]"/>
                  </xsl:when>
               </xsl:choose>
            </xsl:sort>
            <xsl:sort order="{$sort-options[2]/@order}">
               <xsl:choose>
                  <xsl:when test="$sort-options[2]/@n = '1'">
                     <xsl:value-of
                        select="
                           if (tan:tok[@src = $head/tan:source[1]/@xml:id]) then
                              index-of($srcs-ref-sequence-1, (tan:tok[@src = $head/tan:source[1]/@xml:id])[1]/@ref)
                           else
                              count($srcs-ref-sequence-1)"
                     />
                  </xsl:when>
                  <xsl:when test="$sort-options[2]/@n = '2'">
                     <xsl:value-of
                        select="
                           if (tan:tok[@src = $head/tan:source[2]/@xml:id]) then
                              index-of($srcs-ref-sequence-2, (tan:tok[@src = $head/tan:source[2]/@xml:id])[1]/@ref)
                           else
                              count($srcs-ref-sequence-2)"
                     />
                  </xsl:when>
                  <xsl:when test="$sort-options[2]/@n = '3'">
                     <xsl:value-of select="(ancestor-or-self::*/@reuse-type)[last()]"/>
                  </xsl:when>
               </xsl:choose>
            </xsl:sort>
            <xsl:copy-of select="."/>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:align" mode="re-sort-p2"/>

   <!-- STEP SIX: FEEDBACK, FINAL CLEAN-UP -->
   <xsl:variable name="final-results-with-feedback" as="document-node()">
      <xsl:choose>
         <xsl:when test="$p7-include-feedback = true()">
            <xsl:document>
               <xsl:apply-templates select="$re-sorted-doc" mode="cleanup"/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$re-sorted-doc"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:template match="node()[not(self::text())]" mode="cleanup">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="text()" mode="cleanup">
      <xsl:value-of select="replace(., '(\n)(\s*\n)+', '$1')"/>
   </xsl:template>
</xsl:stylesheet>
