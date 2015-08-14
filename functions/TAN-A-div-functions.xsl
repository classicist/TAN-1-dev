<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Revised</xd:b>July 28, 2015</xd:p>
         <xd:p>Core functions for TAN-A-div files. Used by Schematron validation, but suitable for
            general use in other contexts</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="TAN-class-2-functions.xsl"/>
   <xsl:variable name="equate-works" as="xs:integer+">
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xsl:value-of
            select="
               if ($this-src gt 1 and $src-ids[$this-src] = (for $i in $body/tan:equate-works/@src
               return
                  tokenize($i, '\s+'))) then
                  min(for $i in $body/tan:equate-works/@src,
                     $j in tokenize($i, '\s+')
                  return
                     index-of($src-ids, $j))
               else
                  min(for $i in (1 to $this-src)
                  return
                     if ($src-1st-da-heads[$i]//tan:work/tan:IRI/text() = $src-1st-da-heads[$this-src]//tan:work/tan:IRI) then
                        $i
                     else
                        ())"
         />
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="equate-div-types-sorted" as="element()*">
      <xsl:for-each select="$body/tan:equate-div-types">
         <xsl:variable name="this-edt" select="."/>
         <tan:equate-div-types>
            <xsl:for-each select="$src-count">
               <xsl:variable name="this-src" select="."/>
               <xsl:for-each
                  select="$this-edt/tan:div-type-ref[$src-ids[$this-src] = tokenize(@src, '\s+')]">
                  <tan:div-type-ref src="{$src-ids[$this-src]}" div-type-ref="{@div-type-ref}"/>
               </xsl:for-each>
            </xsl:for-each>
         </tan:equate-div-types>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="src-1st-da-div-types-equiv-replace" as="node()+">
      <!-- Creates one element per source, then one element per div-type, correlating @xml:id or its renamed 
         value with an integer for the position of the first div-type within all div-types that share 
         an IRI value -->
      <xsl:for-each select="$src-count">
         <xsl:variable name="this-src" select="."/>
         <xml:source>
            <xsl:for-each select="$src-1st-da-all-div-types/tan:source[$this-src]/tan:div-type">
               <xsl:variable name="this-div-type-orig" select="@xml:id"/>
               <xsl:variable name="this-div-type-alias"
                  select="$rename-div-types/tan:src[$this-src]/tan:rename[@old = $this-div-type-orig]/@new"/>
               <xsl:variable name="this-div-type"
                  select="
                     ($this-div-type-alias,
                     $this-div-type-orig)[1]"/>

               <xsl:variable name="this-div-type-equiv"
                  select="
                     if ($equate-div-types-sorted/tan:div-type-ref[@src = $src-ids[$this-src]][@div-type-ref = $this-div-type])
                     then
                        $equate-div-types-sorted[tan:div-type-ref[@src = $src-ids[$this-src]][@div-type-ref = $this-div-type]]/tan:div-type-ref[1]/@div-type-ref
                     else
                        $this-div-type"/>
               <xsl:variable name="this-src-equiv"
                  select="
                     if ($equate-div-types-sorted/tan:div-type-ref[@src = $src-ids[$this-src]][@div-type-ref = $this-div-type])
                     then
                        index-of($src-ids, $equate-div-types-sorted[tan:div-type-ref[@src = $src-ids[$this-src]][@div-type-ref = $this-div-type]]/tan:div-type-ref[1]/@src)
                     else
                        $this-src"/>
               <tan:replace>
                  <tan:pattern>
                     <xsl:value-of
                        select="concat('^', $this-div-type, '\.|:', $this-div-type, '\.')"/>
                  </tan:pattern>
                  <tan:replacement>
                     <xsl:choose>
                        <xsl:when test="$this-src-equiv = 1">
                           <xsl:value-of
                              select="concat(':', string(count($src-1st-da-all-div-types/tan:source[1]/tan:div-type[@xml:id = $this-div-type-equiv]/preceding-sibling::tan:div-type) + 1), '.')"
                           />
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:variable name="this-div-type-iris"
                              select="$src-1st-da-all-div-types/tan:source[$this-src-equiv]/tan:div-type[@xml:id = $this-div-type-equiv]/tan:IRI"/>
                           <xsl:variable name="this-div-type-iris-first-match"
                              select="$src-1st-da-all-div-types/tan:source[.//tan:IRI = $this-div-type-iris][1]"/>
                           <xsl:value-of
                              select="
                                 concat(':', string(count($this-div-type-iris-first-match/tan:div-type[tan:IRI = $this-div-type-iris]/(preceding-sibling::tan:div-type,
                                 ../preceding-sibling::tan:source/tan:div-type)) + 1), '.')"
                           />
                        </xsl:otherwise>
                     </xsl:choose>
                  </tan:replacement>
               </tan:replace>
            </xsl:for-each>
            <tan:replace>
               <!-- Used to strip out leading periods -->
               <tan:pattern>^:</tan:pattern>
               <tan:replacement/>
            </tan:replace>
         </xml:source>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="leaf-div-splits-raw" as="element()*">
      <xsl:for-each select="$body/tan:split-leaf-div-at/tan:tok">
         <xsl:copy>
            <xsl:copy-of select="tan:pick-tokenized-prepped-class-1-data(.)"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:variable>
   
   <!-- FUNCTIONS -->
   <xsl:function name="tan:convert-ns-to-numerals" as="xs:string">
      <!-- converts a flattened ref's @n values to numerals according to their use in a given source
            Input: single flatref as a string, source number as integer
            Output: revised flatref, substituting @n values for numerals where appropriate
            E.g., ('bk.xxiv:ch.2b', 1) - > 'bk.24:ch.2#2'
        -->
      <xsl:param name="norm-flatref" as="xs:string"/>
      <xsl:param name="src-no" as="xs:integer"/>
      <xsl:variable name="type-n-pairs" select="tokenize($norm-flatref, $separator-hierarchy-regex)"/>
      <xsl:variable name="type-n-pairs-converted"
         select="
            for $i in $type-n-pairs
            return
               concat(tokenize($i, $separator-type-and-n-regex)[1], $separator-type-and-n,
               tan:replace-ns(tokenize($i, $separator-type-and-n-regex)[1], tokenize($i, $separator-type-and-n-regex)[2], $src-no))"/>
      <xsl:value-of select="string-join($type-n-pairs-converted, $separator-hierarchy)"/>
   </xsl:function>
   <xsl:function name="tan:replace-ns" as="xs:string">
      <!-- Input: single value of @type and @n, source number
      Output: single string replacing (or not) the value of @n as appropriate and as a string.
      E.g., ('bk', 'xxiv', 1) - > '24' -->
      <xsl:param name="param-div-type" as="xs:string?"/>
      <xsl:param name="param-div-n" as="xs:string?"/>
      <xsl:param name="param-src-no" as="xs:integer"/>
      <xsl:variable name="this-n-type"
         select="$div-type-ord-check/tan:source[$param-src-no]/tan:div-type[@id = $param-div-type]/@type"/>
      <xsl:choose>
         <xsl:when test="$this-n-type = $n-type[1]">
            <xsl:value-of
               select="
                  if (matches($param-div-n, $n-type-pattern[1], 'i'))
                  then
                     tan:rom-to-int($param-div-n)
                  else
                     $param-div-n"
            />
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[2]">
            <!-- digits don't need conversion -->
            <xsl:value-of select="$param-div-n"/>
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[3]">
            <xsl:choose>
               <xsl:when test="matches($param-div-n, $n-type-pattern[3], 'i')">
                  <xsl:variable name="this-n-split"
                     select="tokenize(replace($param-div-n, $n-type-pattern[3], '$1 $2'), ' ')"/>
                  <xsl:value-of
                     select="concat($this-n-split[1], '#', tan:aaa-to-int($this-n-split[2]))"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$param-div-n"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[4]">
            <xsl:value-of
               select="
                  if (matches($param-div-n, $n-type-pattern[4], 'i'))
                  then
                     tan:aaa-to-int($param-div-n)
                  else
                     $param-div-n"
            />
         </xsl:when>
         <xsl:when test="$this-n-type = $n-type[5]">
            <xsl:choose>
               <xsl:when test="matches($param-div-n, $n-type-pattern[5], 'i')">
                  <xsl:variable name="this-n-split"
                     select="tokenize(replace($param-div-n, $n-type-pattern[5], '$1 $2'), ' ')"/>
                  <xsl:value-of
                     select="concat(tan:aaa-to-int($this-n-split[1]), '#', $this-n-split[2])"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$param-div-n"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <!-- strings don't need conversion -->
            <xsl:value-of select="$param-div-n"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

</xsl:stylesheet>
